import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/common/encryption/encryption_service.dart';
import 'package:on_peace/screens/chat/Screens/contacts_list_screen.dart';
import 'package:on_peace/screens/chat/Screens/empty_contacts_screen.dart';
import 'package:on_peace/screens/chat/widget/chat_list_loader.dart';

class ChatControl extends ConsumerWidget {
  final String userId;
  const ChatControl({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Chats')
          .where('participants', arrayContains: userId)
          .where('status', isEqualTo: 'accepted')
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final oneOnOneChats = snapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('GroupChats')
              .where('members', arrayContains: userId)
              .orderBy('lastMessageTime', descending: true)
              .snapshots(),
          builder: (context, groupSnapshot) {
            if (groupSnapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${groupSnapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final groupChats = groupSnapshot.data?.docs ?? [];

            if (!snapshot.hasData && !groupSnapshot.hasData) {
              return const ChatListLoader();
            }

            if (oneOnOneChats.isEmpty && groupChats.isEmpty) {
              return const EmptyContactsScreen();
            }

            return FutureBuilder<List<ChatItem>>(
              future: _combineChatData(oneOnOneChats, groupChats, userId),
              builder: (context, combinedSnapshot) {
                if (combinedSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${combinedSnapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!combinedSnapshot.hasData) {
                  return const ChatListLoader();
                }

                final chats = combinedSnapshot.data!;

                if (chats.isEmpty) {
                  return const EmptyContactsScreen();
                }

                return ContactsListScreen(chats: chats);
              },
            );
          },
        );
      },
    );
  }

  Future<List<ChatItem>> _combineChatData(
    List<QueryDocumentSnapshot> oneOnOneChats,
    List<QueryDocumentSnapshot> groupChats,
    String userId,
  ) async {
    final List<ChatItem> allChats = [];
    final encryption = EncryptionService();

    for (final doc in oneOnOneChats) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = data['participants'] as List<dynamic>? ?? [];

      if (participants.isEmpty) continue;

      final otherUid = participants.firstWhere(
        (uid) => uid != userId,
        orElse: () => null,
      );

      if (otherUid == null) continue;

      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUid)
          .get();

      if (!otherUserDoc.exists) continue;

      final otherUserData = otherUserDoc.data() ?? {};

      String realLastMessage = 'Message';
      String? lastMessageMediaType;

      try {
        final lastMsgSnap = await FirebaseFirestore.instance
            .collection('Chats')
            .doc(doc.id)
            .collection('messages')
            .orderBy('time', descending: true)
            .limit(1)
            .get();

        if (lastMsgSnap.docs.isNotEmpty) {
          final lastMsgData = lastMsgSnap.docs.first.data();
          final senderId = lastMsgData['senderId'] ?? '';
          final mediaType = lastMsgData['mediaType'];

          if (mediaType != null) {
            lastMessageMediaType = mediaType;
            if (mediaType == 'image') {
              realLastMessage = 'Photo';
            } else if (mediaType == 'video') {
              realLastMessage = 'Video';
            } else if (mediaType == 'gif') {
              realLastMessage = 'GIF';
            } else {
              realLastMessage = 'File';
            }
          } else {
            final textField = senderId == userId
                ? lastMsgData['encryptedSenderCopy']
                : lastMsgData['encryptedText'];

            if (textField != null) {
              try {
                realLastMessage = await encryption.decryptMessage(
                  textField,
                  userId,
                );
              } catch (_) {
                realLastMessage = 'Message';
              }
            }
          }
        }
      } catch (e) {
        print('Error getting last message: $e');
      }

      allChats.add(
        ChatItem(
          chatId: doc.id,
          name: otherUserData['displayname'] ?? 'Unknown',
          profilePic: otherUserData['profilePic'] ?? '',
          lastMessage: realLastMessage,
          lastMessageMediaType: lastMessageMediaType,
          lastMessageTime:
              (data['lastMessageTime'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          unreadCount: data['unreadCount_$userId'] ?? 0,
          chatType: 'oneOnOne',
          receiverUid: otherUid,
          members: [],
        ),
      );
    }

    for (final doc in groupChats) {
      final data = doc.data() as Map<String, dynamic>;
      final groupName = data['groupName'] ?? 'Group';
      final groupProfilePic = data['groupProfilePic'] ?? '';
      final members = (data['members'] as List<dynamic>?) ?? [];
      String lastMessage = 'Message';
      String? lastMessageMediaType;

      try {
        final lastMsgSnap = await FirebaseFirestore.instance
            .collection('GroupChats')
            .doc(doc.id)
            .collection('messages')
            .orderBy('time', descending: true)
            .limit(1)
            .get();

        if (lastMsgSnap.docs.isNotEmpty) {
          final lastMsgData = lastMsgSnap.docs.first.data();
          final mediaType = lastMsgData['mediaType'];

          if (mediaType != null) {
            lastMessageMediaType = mediaType;
            if (mediaType == 'image') {
              lastMessage = 'Photo';
            } else if (mediaType == 'video') {
              lastMessage = 'Video';
            } else if (mediaType == 'gif') {
              lastMessage = 'GIF';
            } else {
              lastMessage = 'File';
            }
          } else {
            // Text message - decrypt plainText
            if (lastMsgData['plainText'] != null) {
              try {
                lastMessage = await encryption.decryptMessage(
                  lastMsgData['plainText'],
                  userId,
                );
              } catch (_) {
                lastMessage = 'Message';
              }
            }
          }
        } else {
          // Fallback
          if (data['lastMessagePlain'] != null) {
            try {
              lastMessage = await encryption.decryptMessage(
                data['lastMessagePlain'],
                userId,
              );
            } catch (_) {
              lastMessage = 'Message';
            }
          }
        }
      } catch (e) {
        print('Error getting last message: $e');
        lastMessage = 'Message';
      }

      allChats.add(
        ChatItem(
          chatId: doc.id,
          name: groupName,
          profilePic: groupProfilePic,
          lastMessage: lastMessage,
          lastMessageMediaType: lastMessageMediaType,
          lastMessageTime:
              (data['lastMessageTime'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          unreadCount: data['unreadCount_$userId'] ?? 0,
          chatType: 'group',
          receiverUid: doc.id,
          members: members.cast<String>(),
        ),
      );
    }

    allChats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    return allChats;
  }
}

class ChatItem {
  final String chatId;
  final String name;
  final String profilePic;
  final String lastMessage;
  final String? lastMessageMediaType;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String chatType;
  final String receiverUid;
  final List<String> members;

  ChatItem({
    required this.chatId,
    required this.name,
    required this.profilePic,
    required this.lastMessage,
    this.lastMessageMediaType,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.chatType,
    required this.receiverUid,
    required this.members,
  });
}
