import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:on_peace/common/encryption/encryption_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:on_peace/common/utils/common_cloudinary_repository.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final _encryption = EncryptionService();
  final _cloudinaryRepository = CommonCloudinaryRepository();

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

            // Skip if message is deleted for current user
            final deletedFor = data['deletedFor'] as List<dynamic>? ?? [];
            if (deletedFor.contains(currentUid)) {
              continue;
            }

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

            String? decryptedMediaUrl;
            if (data.containsKey('mediaUrl') && data['mediaUrl'] != null) {
              final mediaUrlStr = data['mediaUrl'] as String;
              // Check if it's already a Cloudinary URL (not encrypted)
              if (mediaUrlStr.contains('cloudinary') ||
                  mediaUrlStr.startsWith('http')) {
                decryptedMediaUrl = mediaUrlStr;
              } else {
                // Try to decrypt if not a public URL
                try {
                  decryptedMediaUrl = await _encryption.decryptMessage(
                    mediaUrlStr,
                    currentUid,
                  );
                } catch (e) {
                  debugPrint('Error decrypting mediaUrl: $e');
                  decryptedMediaUrl = mediaUrlStr;
                }
              }
            }

            messages.add({
              'id': doc.id,
              'text': text,
              'senderId': senderId,
              'receiverId': data['receiverId'] ?? '',
              'isRead': data['isRead'] ?? false,
              'time': time.toIso8601String(),
              'mediaUrl': decryptedMediaUrl,
              'mediaType': data['mediaType'],
              'fileName': data['fileName'],
              'fileSize': data['fileSize'],
              'duration': data['duration'],
              'replyToMessageId': data['replyToMessageId'],
              'replyToText': data['replyToText'],
              'replyToSenderName': data['replyToSenderName'],
              'replyToMediaUrl': data['replyToMediaUrl'],
              'replyToMediaType': data['replyToMediaType'],
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
    String? replyToMessageId,
    String? replyToText,
    String? replyToMediaUrl,
    String? replyToMediaType,
    String? replyToSenderName,
  }) async {
    try {
      await _createChatIfNotExists(chatId, senderId, receiverId);

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

      final messageData = {
        'senderId': senderId,
        'receiverId': receiverId,
        'encryptedText': encryptedForReceiver,
        'encryptedSenderCopy': encryptedForSender,
        'isRead': false,
        'time': FieldValue.serverTimestamp(),
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        if (replyToText != null) 'replyToText': replyToText,
        if (replyToMediaUrl != null) 'replyToMediaUrl': replyToMediaUrl,
        if (replyToMediaType != null) 'replyToMediaType': replyToMediaType,
        if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      };

      await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      await _updateLastMessage(chatId, senderId, receiverId, 'Message');
    } catch (e) {
      debugPrint('Send message error: $e');
      rethrow;
    }
  }

  Future<void> sendImage({
    required String chatId,
    required String senderId,
    required File imageFile,
    required String receiverId,
  }) async {
    try {
      debugPrint('Starting image upload...');

      await _createChatIfNotExists(chatId, senderId, receiverId);

      final mediaUrl = await _cloudinaryRepository.storeFileToCloudinary(
        imageFile,
      );

      if (mediaUrl == null) {
        throw Exception('Failed to upload image to Cloudinary');
      }

      debugPrint('Image uploaded: $mediaUrl');

      final fileSize = await imageFile.length();
      final fileName = imageFile.path.split('/').last;

      await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'mediaUrl': mediaUrl,
            'mediaType': 'image',
            'fileName': fileName,
            'fileSize': fileSize,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(chatId, senderId, receiverId, '🖼️ Photo');

      debugPrint('Image message sent successfully');
    } catch (e) {
      debugPrint('Send image error: $e');
      rethrow;
    }
  }

  Future<String?> sendImageAndGetId({
    required String chatId,
    required String senderId,
    required File imageFile,
    required String receiverId,
  }) async {
    try {
      debugPrint('Starting image upload...');

      await _createChatIfNotExists(chatId, senderId, receiverId);

      final mediaUrl = await _cloudinaryRepository.storeFileToCloudinary(
        imageFile,
      );

      if (mediaUrl == null) {
        throw Exception('Failed to upload image to Cloudinary');
      }

      debugPrint('Image uploaded: $mediaUrl');

      final fileSize = await imageFile.length();
      final fileName = imageFile.path.split('/').last;

      final docRef = await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'mediaUrl': mediaUrl,
            'mediaType': 'image',
            'fileName': fileName,
            'fileSize': fileSize,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(chatId, senderId, receiverId, '🖼️ Photo');

      debugPrint('Image message sent successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Send image error: $e');
      rethrow;
    }
  }

  Future<void> sendVideo({
    required String chatId,
    required String senderId,
    required File videoFile,
    required String receiverId,
    required int duration,
  }) async {
    try {
      debugPrint('Starting video upload...');

      await _createChatIfNotExists(chatId, senderId, receiverId);

      final mediaUrl = await _cloudinaryRepository.storeFileToCloudinary(
        videoFile,
      );

      if (mediaUrl == null) {
        throw Exception('Failed to upload video to Cloudinary');
      }

      debugPrint('Video uploaded: $mediaUrl');

      final fileSize = await videoFile.length();
      final fileName = videoFile.path.split('/').last;

      await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'mediaUrl': mediaUrl,
            'mediaType': 'video',
            'fileName': fileName,
            'fileSize': fileSize,
            'duration': duration,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(chatId, senderId, receiverId, '🎥 Video');

      debugPrint('Video message sent successfully');
    } catch (e) {
      debugPrint('Send video error: $e');
      rethrow;
    }
  }

  Future<String?> sendVideoAndGetId({
    required String chatId,
    required String senderId,
    required File videoFile,
    required String receiverId,
    required int duration,
  }) async {
    try {
      debugPrint('Starting video upload...');

      await _createChatIfNotExists(chatId, senderId, receiverId);

      final mediaUrl = await _cloudinaryRepository.storeFileToCloudinary(
        videoFile,
      );

      if (mediaUrl == null) {
        throw Exception('Failed to upload video to Cloudinary');
      }

      debugPrint('Video uploaded: $mediaUrl');

      final fileSize = await videoFile.length();
      final fileName = videoFile.path.split('/').last;

      final docRef = await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'mediaUrl': mediaUrl,
            'mediaType': 'video',
            'fileName': fileName,
            'fileSize': fileSize,
            'duration': duration,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(chatId, senderId, receiverId, '🎥 Video');

      debugPrint('Video message sent successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Send video error: $e');
      rethrow;
    }
  }

  Future<void> sendMultipleMedia({
    required String chatId,
    required String senderId,
    required List<File> files,
    required String receiverId,
    required List<String> mediaTypes,
  }) async {
    try {
      debugPrint('Starting batch media upload...');

      await _createChatIfNotExists(chatId, senderId, receiverId);

      final results = await Future.wait([
        _firestore.collection('users').doc(receiverId).get(),
        _firestore.collection('users').doc(senderId).get(),
      ]);

      final receiverPublicKey = results[0].data()?['publicKey'];
      final senderPublicKey = results[1].data()?['publicKey'];

      final uploadTasks = <Future<String?>>[];
      for (final file in files) {
        uploadTasks.add(_cloudinaryRepository.storeFileToCloudinary(file));
      }

      final mediaUrls = await Future.wait(uploadTasks);

      if (mediaUrls.any((url) => url == null)) {
        throw Exception('Failed to upload one or more files to Cloudinary');
      }

      debugPrint('All files uploaded successfully');

      final batch = _firestore.batch();
      final messagesRef = _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages');

      for (int i = 0; i < files.length; i++) {
        final mediaUrl = mediaUrls[i]!;
        final file = files[i];
        final mediaType = mediaTypes[i];

        String encryptedUrlForReceiver = mediaUrl;
        String encryptedUrlForSender = mediaUrl;

        if (receiverPublicKey != null) {
          encryptedUrlForReceiver = await _encryption.encryptMessage(
            mediaUrl,
            receiverPublicKey,
          );
        }

        if (senderPublicKey != null) {
          encryptedUrlForSender = await _encryption.encryptMessage(
            mediaUrl,
            senderPublicKey,
          );
        }

        final fileSize = await file.length();
        final fileName = file.path.split('/').last;

        final newDoc = messagesRef.doc();
        batch.set(newDoc, {
          'senderId': senderId,
          'receiverId': receiverId,
          'mediaUrl': encryptedUrlForReceiver,
          'mediaUrlSenderCopy': encryptedUrlForSender,
          'mediaType': mediaType,
          'fileName': fileName,
          'fileSize': fileSize,
          'isRead': false,
          'time': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      await _updateLastMessage(
        chatId,
        senderId,
        receiverId,
        '📦 ${files.length} file${files.length > 1 ? 's' : ''}',
      );

      debugPrint('Batch media sent successfully (${files.length} files)');
    } catch (e) {
      debugPrint('Send multiple media error: $e');
      rethrow;
    }
  }

  Future<void> sendFile({
    required String chatId,
    required String senderId,
    required File file,
    required String receiverId,
    required String fileType,
  }) async {
    try {
      debugPrint('📤 Starting file upload...');

      await _createChatIfNotExists(chatId, senderId, receiverId);

      final isDocument = [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
      ].contains(fileType.toLowerCase());

      final fileUrl = await _cloudinaryRepository.storeFileToCloudinary(
        file,
        isDocument: isDocument,
      );

      if (fileUrl == null) {
        throw Exception('Failed to upload file to Cloudinary');
      }

      debugPrint('File uploaded: $fileUrl');

      final fileSize = await file.length();
      final fileName = file.path.split('/').last;

      await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'mediaUrl': fileUrl,
            'mediaType': fileType,
            'fileName': fileName,
            'fileSize': fileSize,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(
        chatId,
        senderId,
        receiverId,
        '📄 ${fileType.toUpperCase()}',
      );

      debugPrint('File message sent successfully');
    } catch (e) {
      debugPrint('Send file error: $e');
      rethrow;
    }
  }

  Future<String?> sendFileAndGetId({
    required String chatId,
    required String senderId,
    required File file,
    required String receiverId,
    required String fileType,
  }) async {
    try {
      debugPrint('📤 Starting file upload...');

      await _createChatIfNotExists(chatId, senderId, receiverId);
      final isDocument = [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
      ].contains(fileType.toLowerCase());

      final fileUrl = await _cloudinaryRepository.storeFileToCloudinary(
        file,
        isDocument: isDocument,
      );

      if (fileUrl == null) {
        throw Exception('Failed to upload file to Cloudinary');
      }

      debugPrint('File uploaded: $fileUrl');

      final fileSize = await file.length();
      final fileName = file.path.split('/').last;

      final docRef = await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'mediaUrl': fileUrl,
            'mediaType': fileType,
            'fileName': fileName,
            'fileSize': fileSize,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(
        chatId,
        senderId,
        receiverId,
        '📄 ${fileType.toUpperCase()}',
      );

      debugPrint('File message sent successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Send file error: $e');
      rethrow;
    }
  }

  Future<void> deleteMediaMessage({
    required String chatId,
    required String messageId,
    required String mediaUrl,
  }) async {
    try {
      debugPrint('🗑️ Deleting media...');

      await _cloudinaryRepository.deleteFileFromCloudinary(mediaUrl);

      await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      debugPrint('Media deleted successfully');
    } catch (e) {
      debugPrint('Delete media error: $e');
      rethrow;
    }
  }

  Future<void> sendGif({
    required String chatId,
    required String senderId,
    required String gifUrl,
    required String receiverId,
  }) async {
    try {
      debugPrint('Sending GIF...');
      await _createChatIfNotExists(chatId, senderId, receiverId);

      await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'mediaUrl': gifUrl,
            'mediaType': 'gif',
            'fileName': 'GIF',
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(chatId, senderId, receiverId, 'GIF');
      debugPrint('GiF send succesfully');
    } catch (e) {
      debugPrint('Send GIF error: $e');
      rethrow;
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

  Future<void> _createChatIfNotExists(
    String chatId,
    String senderId,
    String receiverId,
  ) async {
    final chatDoc = await _firestore.collection('Chats').doc(chatId).get();
    if (!chatDoc.exists) {
      await createChat(chatId: chatId, participants: [senderId, receiverId]);
    }
  }

  Future<void> _updateLastMessage(
    String chatId,
    String senderId,
    String receiverId,
    String message,
  ) async {
    await _firestore.collection('Chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      'unreadCount_$receiverId': FieldValue.increment(1),
      'status': 'accepted',
    });
  }

  Future<void> forwardMedia({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String mediaUrl,
    required String mediaType,
    String? fileName,
    int? fileSize,
  }) async {
    try {
      await _createChatIfNotExists(chatId, senderId, receiverId);

      await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'mediaUrl': mediaUrl,
            'mediaType': mediaType,
            if (fileName != null) 'fileName': fileName,
            if (fileSize != null) 'fileSize': fileSize,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      final displayText = mediaType == 'image'
          ? '🖼️ Photo'
          : mediaType == 'gif'
          ? '🎬 GIF'
          : mediaType == 'video'
          ? '🎥 Video'
          : mediaType == 'audio'
          ? '🎵 Audio'
          : '📎 File';

      await _updateLastMessage(chatId, senderId, receiverId, displayText);
    } catch (e) {
      debugPrint('Error forwarding media: $e');
      rethrow;
    }
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    String? mediaUrl,
    bool isPermanent = true,
  }) async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      if (isPermanent) {
        // Permanent deletion for sender's own message
        // Delete media from Cloudinary if exists
        if (mediaUrl != null && mediaUrl.isNotEmpty) {
          try {
            await _cloudinaryRepository.deleteFileFromCloudinary(mediaUrl);
          } catch (e) {
            debugPrint('Error deleting media from Cloudinary: $e');
          }
        }

        // Delete message from Firestore
        await _firestore
            .collection('Chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .delete();

        debugPrint('Message permanently deleted: $messageId');
      } else {
        // Soft delete for receiver (mark as deleted for current user only)
        await _firestore
            .collection('Chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .update({
              'deletedFor': FieldValue.arrayUnion([currentUid]),
            });

        debugPrint('Message marked as deleted for user: $currentUid');
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  Future<void> softDeleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      // Soft delete only - add user to deletedFor array
      await _firestore
          .collection('Chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'deletedFor': FieldValue.arrayUnion([currentUid]),
          });

      debugPrint('Message marked as deleted for user: $currentUid');
    } catch (e) {
      debugPrint('Error soft deleting message: $e');
      rethrow;
    }
  }
}
