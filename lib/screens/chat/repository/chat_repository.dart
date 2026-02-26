import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whatsapp_clone/common/encryption/encryption_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final _encryption = EncryptionService();

  final Map<String, StreamController<List<Map<String, dynamic>>>> _controllers =
      {};
  ChatRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  StreamController<List<Map<String, dynamic>>> _getController(String chatId) {
    if (!_controllers.containsKey(chatId)) {
      _controllers[chatId] =
          StreamController<List<Map<String, dynamic>>>.broadcast();
    }
    return _controllers[chatId]!;
  }

  Future<void> _refreshStream(String chatId) async {
    final messages = await loadLocalMessages(chatId);
    if (_controllers.containsKey(chatId)) {
      _controllers[chatId]!.add(messages);
    }
  }

  Future<File> _getChatFile(String chatId) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/chats');
    if (!await folder.exists()) await folder.create(recursive: true);
    return File('${folder.path}/$chatId.json');
  }

  Future<List<Map<String, dynamic>>> loadLocalMessages(String chatId) async {
    try {
      final file = await _getChatFile(chatId);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      return List<Map<String, dynamic>>.from(jsonDecode(content));
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMessageLocally({
    required String chatId,
    required String id,
    required String text,
    required String senderId,
    required String receiverId,
    required bool isRead,
    required DateTime time,
  }) async {
    final messages = await loadLocalMessages(chatId);

    final exists = messages.any((m) => m['id'] == id);
    if (exists) return;

    messages.add({
      'id': id,
      'text': text,
      'senderId': senderId,
      'receiverId': receiverId,
      'isRead': isRead,
      'time': time.toIso8601String(),
    });
    messages.sort((a, b) => b['time'].compareTo(a['time']));

    final file = await _getChatFile(chatId);
    await file.writeAsString(jsonEncode(messages));
  }

  Future<void> _saveLastMessageLocally({
    required String chatId,
    required String text,
    required String senderId,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/chats');
    if (!await folder.exists()) await folder.create(recursive: true);
    final file = File('${dir.path}/chats/lastmsg_$chatId.json');
    await file.writeAsString(
      jsonEncode({
        'text': text,
        'senderId': senderId,
        'time': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<Map<String, dynamic>?> getLocalLastMessage(String chatId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/chats/lastmsg_$chatId.json');
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString());
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchAndStoreMessages(String chatId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await _firestore
        .collection('Chats')
        .doc(chatId)
        .collection('messages')
        .get();

    if (snapshot.docs.isEmpty) return;

    String lastText = '';
    String lastSenderId = '';

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (data['senderId'] == currentUserId) continue;
      String text = '';

      if (data.containsKey('encryptedText')) {
        try {
          text = await _encryption.decryptMessage(
            data['encryptedText'],
            currentUserId,
          );
        } catch (_) {
          text = '🔒 Message';
        }
      } else if (data.containsKey('text')) {
        text = data['text'] ?? '';
      }
      DateTime time;
      try {
        time = (data['time'] as Timestamp).toDate();
      } catch (_) {
        time = DateTime.now();
      }
      await _saveMessageLocally(
        chatId: chatId,
        id: doc.id,
        text: text,
        senderId: data['senderId'] ?? '',
        receiverId: data['receiverId'] ?? '',
        isRead: data['isRead'] ?? false,
        time: time,
      );

      lastText = text;
      lastSenderId = data['senderId'] ?? '';

      await doc.reference.delete();
    }
    if (lastText.isNotEmpty) {
      await _saveLastMessageLocally(
        chatId: chatId,
        text: lastText,
        senderId: lastSenderId,
      );
    }
    await _refreshStream(chatId);
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String receiverId,
  }) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    await _saveMessageLocally(
      chatId: chatId,
      id: tempId,
      text: text,
      senderId: senderId,
      receiverId: receiverId,
      isRead: true,
      time: DateTime.now(),
    );
    await _saveLastMessageLocally(
      chatId: chatId,
      text: text,
      senderId: senderId,
    );
    await _refreshStream(chatId);

    _sendToFirestore(
      chatId: chatId,
      senderId: senderId,
      text: text,
      receiverId: receiverId,
      tempId: tempId,
    );
  }

  Future<void> _sendToFirestore({
    required String chatId,
    required String senderId,
    required String text,
    required String receiverId,
    required String tempId,
  }) async {
    try {
      final receiverDoc = await _firestore
          .collection('users')
          .doc(receiverId)
          .get();
      final publicKey = receiverDoc.data()?['publicKey'];
      String encryptedText = text;
      if (publicKey != null) {
        encryptedText = await _encryption.encryptMessage(text, publicKey);
      }
      final docRef = await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'encryptedText': encryptedText,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });
      final messages = await loadLocalMessages(chatId);
      final idx = messages.indexWhere((m) => m['id'] == tempId);
      if (idx != -1) {
        messages[idx]['id'] = docRef.id;
        final file = await _getChatFile(chatId);
        await file.writeAsString(jsonEncode(messages));
      }

      _firestore.collection('Chats').doc(chatId).update({
        'lastMessage': '🔒 Message',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'unreadCount_$receiverId': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Firestore send error: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getLocalMessagesStream(String chatId) {
    final controller = _getController(chatId);

    Future.microtask(() async {
      await fetchAndStoreMessages(chatId);
      final messages = await loadLocalMessages(chatId);
      controller.add(messages);
    });
    _firestore
        .collection('Chats')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            await fetchAndStoreMessages(chatId);
          }
        });
    return controller.stream;
  }

  Stream<QuerySnapshot> getUserChats(String uid) {
    return _firestore
        .collection('Chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection('Chats').doc(chatId).update({
      'unreadCount_$userId': 0,
    });
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    await _firestore.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createChat({
    required String chatId,
    required List<String> participants,
  }) async {
    final doc = await _firestore.collection('Chats').doc(chatId).get();

    if (!doc.exists) {
      await _firestore.collection('Chats').doc(chatId).set({
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        for (var uid in participants) 'unreadCount_$uid': 0,
      });
    }
  }

  Future<void> deleteLocalChat(String chatId) async {
    final file = await _getChatFile(chatId);
    if (await file.exists()) await file.delete();

    final dir = await getApplicationDocumentsDirectory();
    final lastMsgFile = File('${dir.path}/chats/lastmsg_$chatId.json');
    if (await lastMsgFile.exists()) await lastMsgFile.delete();
    _controllers[chatId]?.close();
    _controllers.remove(chatId);
  }
}
