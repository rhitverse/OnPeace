import 'package:cloud_firestore/cloud_firestore.dart';

class ChatContact {
  final String chatId;
  final String receiverUid;
  final String receiverDisplayName;
  final String receiverProfilePic;
  final DateTime lastMessageTime;
  final String lastMessage;
  final String lastMessageSenderId;
  final String? lastMessageMediaType;
  final int unreadCount;
  final bool isOnline;
  final DateTime? lastSeen;

  ChatContact({
    required this.chatId,
    required this.receiverUid,
    required this.receiverDisplayName,
    required this.receiverProfilePic,
    required this.lastMessageTime,
    required this.lastMessage,
    required this.lastMessageSenderId,
    this.lastMessageMediaType,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeen,
  });

  bool isLastMessageMine(String currentUid) {
    return lastMessageSenderId == currentUid;
  }

  String getDisplayMessage(String currentUid) {
    if (lastMessage.isEmpty || lastMessage == '🔒 Message') return '';

    if (isLastMessageMine(currentUid)) {
      return 'You: $lastMessage';
    }
    return lastMessage;
  }

  factory ChatContact.fromMap(
    Map<String, dynamic> map,
    String chatId,
    String currentUid,
    Map<String, dynamic> receiverUserData,
  ) {
    final participants = List<String>.from(map['participants'] ?? []);

    final receiverUid = participants.firstWhere(
      (uid) => uid != currentUid,
      orElse: () => '',
    );

    DateTime messageTime;
    try {
      if (map['lastMessageTime'] != null) {
        messageTime = (map['lastMessageTime'] as Timestamp).toDate();
      } else {
        messageTime = DateTime.now();
      }
    } catch (e) {
      messageTime = DateTime.now();
    }

    DateTime? lastSeenTime;
    try {
      if (receiverUserData['lastSeen'] != null) {
        lastSeenTime = (receiverUserData['lastSeen'] as Timestamp).toDate();
      }
    } catch (e) {
      lastSeenTime = null;
    }

    return ChatContact(
      chatId: chatId,
      receiverUid: receiverUid,
      receiverDisplayName:
          receiverUserData['displayname'] ??
          receiverUserData['username'] ??
          'Unknown User',
      receiverProfilePic: receiverUserData['profilePic'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: messageTime,
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageMediaType: map['lastMessageMediaType'],
      unreadCount: map['unreadCount_$currentUid'] ?? 0,
      isOnline: receiverUserData['isOnline'] ?? false,
      lastSeen: lastSeenTime,
    );
  }
}
