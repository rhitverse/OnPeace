import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp_clone/common/encryption/encryption_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:whatsapp_clone/models/message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final _encryption = EncryptionService();

  ChatRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return _firestore
        .collection('Chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('time', descending: true)
        .snapshots()
        .asyncMap((snap) async {
          final List<Map<String, dynamic>> messages = [];
          for (final doc in snap.docs) {
            final data = doc.data();
            final senderId = data['senderId'] ?? '';
            DateTime time;
            try {
              time = (data['time'] as Timestamp).toDate();
            } catch (_) {
              time = DateTime.now();
            }

            String text = '';
            if (senderId == currentUid) {
              if (data.containsKey('encryptedSenderCopy')) {
                try {
                  text = await _encryption.decryptMessage(
                    data['encryptedSenderCopy'],
                    currentUid,
                  );
                } catch (_) {
                  text = data['plainText'] ?? '';
                }
              } else {
                text = data['plainText'] ?? '';
              }
            } else {
              if (data.containsKey('encryptedText')) {
                try {
                  text = await _encryption.decryptMessage(
                    data['encryptedText'],
                    currentUid,
                  );
                } catch (_) {
                  text = 'Message';
                }
              } else {
                text = data['text'] ?? '';
              }
            }

            messages.add({
              'id': doc.id,
              'text': text,
              'senderId': senderId,
              'receiverId': data['receiverId'] ?? '',
              'isRead': data['isRead'] ?? false,
              'time': time.toIso8601String(),
            });
          }
          return messages;
        });
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String receiverId,
    String receiverDispalyName = '',
    String receiverProfilePic = '',
  }) async {
    try {
      final chatDoc = await _firestore.collection('Chats').doc(chatId).get();
      if (!chatDoc.exists) {
        await _firestore.collection('Chats').doc(chatId).set({
          'participants': [senderId, receiverId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
          'status': 'accepted',
          'unreadCount_$senderId': 0,
          'unreadCount_$receiverId': 0,
        });
      }

      final results = await Future.wait([
        _firestore.collection('users').doc(receiverId).get(),
        _firestore.collection('users').doc(senderId).get(),
      ]);

      final receiverPublicKey = results[0].data()?['publicKey'];
      final senderPublicKey = results[1].data()?['publicKey'];

      String encryptedForReceiver = text;
      if (receiverPublicKey != null) {
        encryptedForReceiver = await _encryption.encryptMessage(
          text,
          receiverPublicKey,
        );
      }

      String encryptedForSender = text;
      if (senderPublicKey != null) {
        encryptedForSender = await _encryption.encryptMessage(
          text,
          senderPublicKey,
        );
      }

      await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'encryptedText': encryptedForReceiver,
            'encryptedSenderCopy': encryptedForSender,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _firestore.collection('Chats').doc(chatId).update({
        'lastMessage': 'Message',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'unreadCount_$receiverId': FieldValue.increment(1),
        'status': 'accepted',
      });
    } catch (e) {
      debugPrint('Send message error: $e');
    }
  }

  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('Chats').doc(chatId).update({
        'unreadCount_$userId': 0,
      });
      final snap = await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('MarkAsRead error: $e');
    }
  }

  Stream<QuerySnapshot> getUserChats(String uid) {
    return _firestore
        .collection('Chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
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
        'status': 'accepted',
        for (var uid in participants) 'unreadCount_$uid': 0,
      });
    }
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    await _firestore.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
