import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/screens/chat/group/repository/group_chat_repository.dart';

class GroupChatController {
  final GroupChatRepository _groupChatRepository;
  final ProviderRef ref;

  GroupChatController({
    required GroupChatRepository groupChatRepository,
    required this.ref,
  }) : _groupChatRepository = groupChatRepository;

  Stream<List<Map<String, dynamic>>> getMessages(String groupId) {
    return _groupChatRepository.getMessagesStream(groupId);
  }

  Stream<QuerySnapshot> getUserGroups(String uid) {
    return _groupChatRepository.getUserGroups(uid);
  }

  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required String text,
  }) async {
    try {
      await _groupChatRepository.sendMessage(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        text: text,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendImage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File imageFile,
  }) async {
    try {
      await _groupChatRepository.sendImage(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        imageFile: imageFile,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> sendImageAndGetId({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File imageFile,
  }) async {
    try {
      return await _groupChatRepository.sendImageAndGetId(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        imageFile: imageFile,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendVideo({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File videoFile,
    required int duration,
  }) async {
    try {
      await _groupChatRepository.sendVideo(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        videoFile: videoFile,
        duration: duration,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> sendVideoAndGetId({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File videoFile,
    required int duration,
  }) async {
    try {
      return await _groupChatRepository.sendVideoAndGetId(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        videoFile: videoFile,
        duration: duration,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendMultipleMedia({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required List<File> files,
    required List<String> mediaTypes,
  }) async {
    try {
      await _groupChatRepository.sendMultipleMedia(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        files: files,
        mediaTypes: mediaTypes,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendFile({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File file,
    required String fileType,
  }) async {
    try {
      await _groupChatRepository.sendFile(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        file: file,
        fileType: fileType,
      );
    } catch (e) {
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
      return await _groupChatRepository.sendFileAndGetId(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        file: file,
        fileType: fileType,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMediaMessage({
    required String groupId,
    required String messageId,
    required String mediaUrl,
  }) async {
    try {
      await _groupChatRepository.deleteMediaMessage(
        groupId: groupId,
        messageId: messageId,
        mediaUrl: mediaUrl,
      );
    } catch (e) {
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
      await _groupChatRepository.sendGif(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        gifUrl: gifUrl,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendAudio({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderProfilePic,
    required File audioFile,
    required int duration,
  }) async {
    try {
      await _groupChatRepository.sendAudio(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        audioFile: audioFile,
        duration: duration,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String groupId, String userId) async {
    try {
      await _groupChatRepository.markAsRead(groupId, userId);
    } catch (e) {
      rethrow;
    }
  }

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
      await _groupChatRepository.createGroupChat(
        groupId: groupId,
        groupName: groupName,
        members: members,
        groupProfilePic: groupProfilePic,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorProfilePic: creatorProfilePic,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addMember({
    required String groupId,
    required String memberId,
  }) async {
    try {
      await _groupChatRepository.addMember(
        groupId: groupId,
        memberId: memberId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    try {
      await _groupChatRepository.removeMember(
        groupId: groupId,
        memberId: memberId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getGroupInfo(String groupId) async {
    try {
      return await _groupChatRepository.getGroupInfo(groupId);
    } catch (e) {
      debugPrint('Error getting group info: $e');
      return null;
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
      await _groupChatRepository.forwardMedia(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        fileName: fileName,
        fileSize: fileSize,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
    String? mediaUrl,
  }) async {
    try {
      await _groupChatRepository.deleteMessage(
        groupId: groupId,
        messageId: messageId,
        mediaUrl: mediaUrl,
        isPermanent: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteMessage({
    required String groupId,
    required String messageId,
  }) async {
    try {
      await _groupChatRepository.softDeleteMessage(
        groupId: groupId,
        messageId: messageId,
      );
    } catch (e) {
      rethrow;
    }
  }
}
