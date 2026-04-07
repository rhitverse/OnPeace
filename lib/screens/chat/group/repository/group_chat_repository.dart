import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:on_peace/common/encryption/encryption_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:on_peace/common/utils/common_cloudinary_repository.dart';

class GroupChatRepository {
  final FirebaseFirestore _firestore;
  final _encryption = EncryptionService();
  final _cloudinaryRepository = CommonCloudinaryRepository();

  GroupChatRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Get Messages Stream
  Stream<List<Map<String, dynamic>>> getMessagesStream(String groupId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return _firestore
        .collection('GroupChats')
        .doc(groupId)
        .collection('messages')
        .orderBy('time', descending: true)
        .snapshots()
        .asyncMap((snap) async {
          final List<Map<String, dynamic>> messages = [];

          for (final doc in snap.docs) {
            final data = doc.data();
            final senderId = data['senderId'] ?? '';
            final senderName = data['senderName'] ?? '';
            final senderProfilePic = data['senderProfilePic'] ?? '';

            DateTime time;
            try {
              time = (data['time'] as Timestamp).toDate();
            } catch (_) {
              time = DateTime.now();
            }

            String text = '';
            if (data.containsKey('encryptedText')) {
              try {
                text = await _encryption.decryptMessage(
                  data['encryptedText'],
                  currentUid,
                );
              } catch (_) {
                text = data['plainText'] ?? 'Message';
              }
            } else {
              text = data['plainText'] ?? '';
            }

            String? decryptedMediaUrl;
            if (data.containsKey('mediaUrl') && data['mediaUrl'] != null) {
              try {
                decryptedMediaUrl = await _encryption.decryptMessage(
                  data['mediaUrl'],
                  currentUid,
                );
              } catch (e) {
                debugPrint('Error decrypting mediaUrl: $e');
                decryptedMediaUrl = data['mediaUrl'];
              }
            }

            messages.add({
              'id': doc.id,
              'text': text,
              'senderId': senderId,
              'senderName': senderName,
              'senderProfilePic': senderProfilePic,
              'isRead': data['isRead'] ?? false,
              'time': time.toIso8601String(),
              'mediaUrl': decryptedMediaUrl,
              'mediaType': data['mediaType'],
              'fileName': data['fileName'],
              'fileSize': data['fileSize'],
              'duration': data['duration'],
            });
          }

          return messages;
        });
  }

  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required String text,
  }) async {
    try {
      await _createGroupIfNotExists(groupId);

      String encryptedText = text;
      final senderPublicKey =
          (await _firestore.collection('users').doc(senderId).get())
              .data()?['publicKey'];

      if (senderPublicKey != null) {
        encryptedText = await _encryption.encryptMessage(text, senderPublicKey);
      }

      await _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'senderProfilePic': senderProfilePic,
            'encryptedText': encryptedText,
            'plainText': encryptedText,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(groupId, senderId, senderName, text);
    } catch (e) {
      debugPrint('Send group message error: $e');
      rethrow;
    }
  }

  /// Send Image
  Future<void> sendImage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File imageFile,
  }) async {
    try {
      debugPrint('Starting group image upload...');
      await _createGroupIfNotExists(groupId);

      final mediaUrl = await _cloudinaryRepository.storeFileToCloudinary(
        imageFile,
      );

      if (mediaUrl == null) {
        throw Exception('Failed to upload image to Cloudinary');
      }

      final fileSize = await imageFile.length();
      final fileName = imageFile.path.split('/').last;

      String encryptedUrl = mediaUrl;
      final senderPublicKey =
          (await _firestore.collection('users').doc(senderId).get())
              .data()?['publicKey'];

      if (senderPublicKey != null) {
        encryptedUrl = await _encryption.encryptMessage(
          mediaUrl,
          senderPublicKey,
        );
      }

      await _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'senderProfilePic': senderProfilePic,
            'mediaUrl': encryptedUrl,
            'mediaType': 'image',
            'fileName': fileName,
            'fileSize': fileSize,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(groupId, senderId, senderName, '🖼️ Photo');
      debugPrint('Image message sent successfully');
    } catch (e) {
      debugPrint('Send group image error: $e');
      rethrow;
    }
  }

  /// Send Image & Get ID
  Future<String?> sendImageAndGetId({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File imageFile,
  }) async {
    try {
      debugPrint('Starting group image upload...');
      await _createGroupIfNotExists(groupId);

      final mediaUrl = await _cloudinaryRepository.storeFileToCloudinary(
        imageFile,
      );

      if (mediaUrl == null) {
        throw Exception('Failed to upload image to Cloudinary');
      }

      final fileSize = await imageFile.length();
      final fileName = imageFile.path.split('/').last;

      String encryptedUrl = mediaUrl;
      final senderPublicKey =
          (await _firestore.collection('users').doc(senderId).get())
              .data()?['publicKey'];

      if (senderPublicKey != null) {
        encryptedUrl = await _encryption.encryptMessage(
          mediaUrl,
          senderPublicKey,
        );
      }

      final docRef = await _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'senderProfilePic': senderProfilePic,
            'mediaUrl': encryptedUrl,
            'mediaType': 'image',
            'fileName': fileName,
            'fileSize': fileSize,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(groupId, senderId, senderName, '🖼️ Photo');
      return docRef.id;
    } catch (e) {
      debugPrint('Send group image error: $e');
      rethrow;
    }
  }

  /// Send Video
  Future<void> sendVideo({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File videoFile,
    required int duration,
  }) async {
    try {
      debugPrint('Starting group video upload...');
      await _createGroupIfNotExists(groupId);

      final mediaUrl = await _cloudinaryRepository.storeFileToCloudinary(
        videoFile,
      );

      if (mediaUrl == null) {
        throw Exception('Failed to upload video to Cloudinary');
      }

      final fileSize = await videoFile.length();
      final fileName = videoFile.path.split('/').last;

      String encryptedUrl = mediaUrl;
      final senderPublicKey =
          (await _firestore.collection('users').doc(senderId).get())
              .data()?['publicKey'];

      if (senderPublicKey != null) {
        encryptedUrl = await _encryption.encryptMessage(
          mediaUrl,
          senderPublicKey,
        );
      }

      await _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'senderProfilePic': senderProfilePic,
            'mediaUrl': encryptedUrl,
            'mediaType': 'video',
            'fileName': fileName,
            'fileSize': fileSize,
            'duration': duration,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(groupId, senderId, senderName, '🎥 Video');
      debugPrint('Video message sent successfully');
    } catch (e) {
      debugPrint('Send group video error: $e');
      rethrow;
    }
  }

  /// Send Video & Get ID
  Future<String?> sendVideoAndGetId({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File videoFile,
    required int duration,
  }) async {
    try {
      debugPrint('Starting group video upload...');
      await _createGroupIfNotExists(groupId);

      final mediaUrl = await _cloudinaryRepository.storeFileToCloudinary(
        videoFile,
      );

      if (mediaUrl == null) {
        throw Exception('Failed to upload video to Cloudinary');
      }

      final fileSize = await videoFile.length();
      final fileName = videoFile.path.split('/').last;

      String encryptedUrl = mediaUrl;
      final senderPublicKey =
          (await _firestore.collection('users').doc(senderId).get())
              .data()?['publicKey'];

      if (senderPublicKey != null) {
        encryptedUrl = await _encryption.encryptMessage(
          mediaUrl,
          senderPublicKey,
        );
      }

      final docRef = await _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'senderProfilePic': senderProfilePic,
            'mediaUrl': encryptedUrl,
            'mediaType': 'video',
            'fileName': fileName,
            'fileSize': fileSize,
            'duration': duration,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(groupId, senderId, senderName, '🎥 Video');
      return docRef.id;
    } catch (e) {
      debugPrint('Send group video error: $e');
      rethrow;
    }
  }

  /// Send File
  Future<void> sendFile({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File file,
    required String fileType,
  }) async {
    try {
      debugPrint('📤 Starting group file upload...');
      await _createGroupIfNotExists(groupId);

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

      final fileSize = await file.length();
      final fileName = file.path.split('/').last;

      String encryptedUrl = fileUrl;
      final senderPublicKey =
          (await _firestore.collection('users').doc(senderId).get())
              .data()?['publicKey'];

      if (senderPublicKey != null) {
        encryptedUrl = await _encryption.encryptMessage(
          fileUrl,
          senderPublicKey,
        );
      }

      await _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'senderProfilePic': senderProfilePic,
            'mediaUrl': encryptedUrl,
            'mediaType': fileType,
            'fileName': fileName,
            'fileSize': fileSize,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(
        groupId,
        senderId,
        senderName,
        '📄 ${fileType.toUpperCase()}',
      );

      debugPrint('File message sent successfully');
    } catch (e) {
      debugPrint('Send group file error: $e');
      rethrow;
    }
  }

  Future<String?> sendFileAndGetId({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File file,
    required String fileType,
  }) async {
    try {
      debugPrint('📤 Starting group file upload...');
      await _createGroupIfNotExists(groupId);

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

      final fileSize = await file.length();
      final fileName = file.path.split('/').last;

      String encryptedUrl = fileUrl;
      final senderPublicKey =
          (await _firestore.collection('users').doc(senderId).get())
              .data()?['publicKey'];

      if (senderPublicKey != null) {
        encryptedUrl = await _encryption.encryptMessage(
          fileUrl,
          senderPublicKey,
        );
      }

      final docRef = await _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'senderProfilePic': senderProfilePic,
            'mediaUrl': encryptedUrl,
            'mediaType': fileType,
            'fileName': fileName,
            'fileSize': fileSize,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(
        groupId,
        senderId,
        senderName,
        '📄 ${fileType.toUpperCase()}',
      );

      return docRef.id;
    } catch (e) {
      debugPrint('Send group file error: $e');
      rethrow;
    }
  }

  Future<void> sendGif({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required String gifUrl,
  }) async {
    try {
      debugPrint('Sending group GIF...');
      await _createGroupIfNotExists(groupId);

      String encryptedUrl = gifUrl;
      final senderPublicKey =
          (await _firestore.collection('users').doc(senderId).get())
              .data()?['publicKey'];

      if (senderPublicKey != null) {
        encryptedUrl = await _encryption.encryptMessage(
          gifUrl,
          senderPublicKey,
        );
      }

      await _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'senderProfilePic': senderProfilePic,
            'mediaUrl': encryptedUrl,
            'mediaType': 'gif',
            'fileName': 'GIF',
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(groupId, senderId, senderName, 'GIF');
      debugPrint('GIF sent successfully');
    } catch (e) {
      debugPrint('Send group GIF error: $e');
      rethrow;
    }
  }

  /// Send Audio
  Future<void> sendAudio({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File audioFile,
    required int duration,
  }) async {
    try {
      debugPrint('Starting group audio upload...');
      await _createGroupIfNotExists(groupId);

      final mediaUrl = await _cloudinaryRepository.storeFileToCloudinary(
        audioFile,
      );

      if (mediaUrl == null) {
        throw Exception('Failed to upload audio to Cloudinary');
      }

      final fileSize = await audioFile.length();
      final fileName = audioFile.path.split('/').last;

      String encryptedUrl = mediaUrl;
      final senderPublicKey =
          (await _firestore.collection('users').doc(senderId).get())
              .data()?['publicKey'];

      if (senderPublicKey != null) {
        encryptedUrl = await _encryption.encryptMessage(
          mediaUrl,
          senderPublicKey,
        );
      }

      await _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'senderProfilePic': senderProfilePic,
            'mediaUrl': encryptedUrl,
            'mediaType': 'audio',
            'fileName': fileName,
            'fileSize': fileSize,
            'duration': duration,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      await _updateLastMessage(groupId, senderId, senderName, '🎵 Audio');
      debugPrint('Audio message sent successfully');
    } catch (e) {
      debugPrint('Send group audio error: $e');
      rethrow;
    }
  }

  /// Send Multiple Media
  Future<void> sendMultipleMedia({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required List<File> files,
    required List<String> mediaTypes,
  }) async {
    try {
      debugPrint('Starting batch group media upload...');
      await _createGroupIfNotExists(groupId);

      final senderPublicKey =
          (await _firestore.collection('users').doc(senderId).get())
              .data()?['publicKey'];

      final uploadTasks = <Future<String?>>[];
      for (final file in files) {
        uploadTasks.add(_cloudinaryRepository.storeFileToCloudinary(file));
      }

      final mediaUrls = await Future.wait(uploadTasks);

      if (mediaUrls.any((url) => url == null)) {
        throw Exception('Failed to upload one or more files to Cloudinary');
      }

      final batch = _firestore.batch();
      final messagesRef = _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages');

      for (int i = 0; i < files.length; i++) {
        final mediaUrl = mediaUrls[i]!;
        final file = files[i];
        final mediaType = mediaTypes[i];

        String encryptedUrl = mediaUrl;
        if (senderPublicKey != null) {
          encryptedUrl = await _encryption.encryptMessage(
            mediaUrl,
            senderPublicKey,
          );
        }

        final fileSize = await file.length();
        final fileName = file.path.split('/').last;

        final newDoc = messagesRef.doc();
        batch.set(newDoc, {
          'senderId': senderId,
          'senderName': senderName,
          'senderProfilePic': senderProfilePic,
          'mediaUrl': encryptedUrl,
          'mediaType': mediaType,
          'fileName': fileName,
          'fileSize': fileSize,
          'isRead': false,
          'time': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      await _updateLastMessage(
        groupId,
        senderId,
        senderName,
        '📦 ${files.length} file${files.length > 1 ? 's' : ''}',
      );

      debugPrint('Batch group media sent successfully (${files.length} files)');
    } catch (e) {
      debugPrint('Send multiple group media error: $e');
      rethrow;
    }
  }

  /// Delete Media Message
  Future<void> deleteMediaMessage({
    required String groupId,
    required String messageId,
    required String mediaUrl,
  }) async {
    try {
      debugPrint('🗑️ Deleting group media...');

      await _cloudinaryRepository.deleteFileFromCloudinary(mediaUrl);

      await _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();

      debugPrint('Media deleted successfully');
    } catch (e) {
      debugPrint('Delete group media error: $e');
      rethrow;
    }
  }

  /// Mark As Read
  Future<void> markAsRead(String groupId, String userId) async {
    try {
      await _firestore.collection('GroupChats').doc(groupId).update({
        'unreadCount_$userId': 0,
      });

      final snap = await _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages')
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

  /// Get User Groups
  Stream<QuerySnapshot> getUserGroups(String uid) {
    return _firestore
        .collection('GroupChats')
        .where('members', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Create Group Chat
  Future<void> createGroupChat({
    required String groupId,
    required String groupName,
    required List<String> members,
    String groupProfilePic = '',
    String? creatorId,
    String? creatorName,
    String creatorProfilePic = '',
  }) async {
    try {
      final doc = await _firestore.collection('GroupChats').doc(groupId).get();

      if (!doc.exists) {
        final finalCreatorId =
            creatorId ?? FirebaseAuth.instance.currentUser?.uid;
        final finalCreatorName = creatorName ?? 'Unknown';

        await _firestore.collection('GroupChats').doc(groupId).set({
          'groupName': groupName,
          'groupProfilePic': groupProfilePic,
          'members': members,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
          'lastMessageSenderName': '',
          'status': 'active',
          'creatorId': finalCreatorId,
          'creatorName': finalCreatorName,
          'creatorProfilePic': creatorProfilePic,
          'admins': finalCreatorId != null ? [finalCreatorId] : <String>[],
          'createdAt': FieldValue.serverTimestamp(),
          for (var uid in members) 'unreadCount_$uid': 0,
        });

        debugPrint('Group created successfully');
      }
    } catch (e) {
      debugPrint('Error creating group: $e');
      rethrow;
    }
  }

  /// Add Member
  Future<void> addMember({
    required String groupId,
    required String memberId,
  }) async {
    await _firestore.collection('GroupChats').doc(groupId).update({
      'members': FieldValue.arrayUnion([memberId]),
      'unreadCount_$memberId': 0,
    });
  }

  /// Remove Member
  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    await _firestore.collection('GroupChats').doc(groupId).update({
      'members': FieldValue.arrayRemove([memberId]),
    });
  }

  /// Get Group Info
  Future<Map<String, dynamic>?> getGroupInfo(String groupId) async {
    try {
      final doc = await _firestore.collection('GroupChats').doc(groupId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching group info: $e');
      return null;
    }
  }

  // Helper Methods

  Future<void> _createGroupIfNotExists(String groupId) async {
    final groupDoc = await _firestore
        .collection('GroupChats')
        .doc(groupId)
        .get();

    if (!groupDoc.exists) {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null) {
        await createGroupChat(
          groupId: groupId,
          groupName: 'Group Chat',
          members: [currentUid],
        );
      }
    }
  }

  Future<void> forwardMedia({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required String mediaUrl,
    required String mediaType,
    String? fileName,
    int? fileSize,
  }) async {
    try {
      await _createGroupIfNotExists(groupId);

      String encryptedUrl = mediaUrl;
      final senderPublicKey =
          (await _firestore.collection('users').doc(senderId).get())
              .data()?['publicKey'];

      if (senderPublicKey != null) {
        encryptedUrl = await _encryption.encryptMessage(
          mediaUrl,
          senderPublicKey,
        );
      }

      await _firestore
          .collection('GroupChats')
          .doc(groupId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'senderProfilePic': senderProfilePic,
            'text': '',
            'mediaUrl': encryptedUrl,
            'mediaType': mediaType,
            if (fileName != null) 'fileName': fileName,
            if (fileSize != null) 'fileSize': fileSize,
            'time': FieldValue.serverTimestamp(),
          });

      final displayText = mediaType == 'image'
          ? '🖼️ Photo'
          : mediaType == 'video'
          ? '🎥 Video'
          : mediaType == 'audio'
          ? '🎵 Audio'
          : '📎 File';

      await _updateLastMessage(groupId, senderId, senderName, displayText);
    } catch (e) {
      debugPrint('Error forwarding media to group: $e');
      rethrow;
    }
  }

  Future<void> _updateLastMessage(
    String groupId,
    String senderId,
    String senderName,
    String message,
  ) async {
    try {
      final senderPublicKey =
          (await _firestore.collection('users').doc(senderId).get())
              .data()?['publicKey'];

      String encryptedMessage = message;
      if (senderPublicKey != null) {
        encryptedMessage = await _encryption.encryptMessage(
          message,
          senderPublicKey,
        );
      }

      await _firestore.collection('GroupChats').doc(groupId).update({
        'lastMessage': encryptedMessage,
        'lastMessagePlain': encryptedMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'lastMessageSenderName': senderName,
        'status': 'active',
      });
    } catch (e) {
      debugPrint('Error updating last message: $e');
      rethrow;
    }
  }
}
