import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/screens/chat/repository/chat_repository.dart';

class ChatController {
  final ChatRepository _chatRepository;
  final ProviderRef ref;

  ChatController({required ChatRepository chatRepository, required this.ref})
    : _chatRepository = chatRepository;

  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _chatRepository.getMessagesStream(chatId);
  }

  Stream<QuerySnapshot> getUserChats(String uid) {
    return _chatRepository.getUserChats(uid);
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String receiverId,
    String receiverDisplayName = '',
    String receiverProfilePic = '',
  }) async {
    try {
      await _chatRepository.sendMessage(
        chatId: chatId,
        senderId: senderId,
        text: text,
        receiverId: receiverId,
        receiverDispalyName: receiverDisplayName,
        receiverProfilePic: receiverProfilePic,
      );
    } catch (e) {
      return;
    }
  }

  Future<void> sendImage({
    required String chatId,
    required String senderId,
    required File imageFile,
    required String receiverId,
  }) async {
    try {
      await _chatRepository.sendImage(
        chatId: chatId,
        senderId: senderId,
        imageFile: imageFile,
        receiverId: receiverId,
      );
    } catch (e) {
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
      return await _chatRepository.sendImageAndGetId(
        chatId: chatId,
        senderId: senderId,
        imageFile: imageFile,
        receiverId: receiverId,
      );
    } catch (e) {
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
      await _chatRepository.sendVideo(
        chatId: chatId,
        senderId: senderId,
        videoFile: videoFile,
        receiverId: receiverId,
        duration: duration,
      );
    } catch (e) {
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
      return await _chatRepository.sendVideoAndGetId(
        chatId: chatId,
        senderId: senderId,
        videoFile: videoFile,
        receiverId: receiverId,
        duration: duration,
      );
    } catch (e) {
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
      await _chatRepository.sendMultipleMedia(
        chatId: chatId,
        senderId: senderId,
        files: files,
        receiverId: receiverId,
        mediaTypes: mediaTypes,
      );
    } catch (e) {
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
      await _chatRepository.sendFile(
        chatId: chatId,
        senderId: senderId,
        file: file,
        receiverId: receiverId,
        fileType: fileType,
      );
    } catch (e) {
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
      return await _chatRepository.sendFileAndGetId(
        chatId: chatId,
        senderId: senderId,
        file: file,
        receiverId: receiverId,
        fileType: fileType,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMediaMessage({
    required String chatId,
    required String messageId,
    required String mediaUrl,
  }) async {
    try {
      await _chatRepository.deleteMediaMessage(
        chatId: chatId,
        messageId: messageId,
        mediaUrl: mediaUrl,
      );
    } catch (e) {
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
      await _chatRepository.sendGif(
        chatId: chatId,
        senderId: senderId,
        gifUrl: gifUrl,
        receiverId: receiverId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await _chatRepository.markAsRead(chatId, userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createChat({
    required String chatId,
    required List<String> participants,
  }) async {
    try {
      await _chatRepository.createChat(
        chatId: chatId,
        participants: participants,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    try {
      await _chatRepository.updateOnlineStatus(uid, isOnline);
    } catch (e) {
      rethrow;
    }
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
      await _chatRepository.forwardMedia(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        fileName: fileName,
        fileSize: fileSize,
      );
    } catch (e) {
      rethrow;
    }
  }
}
