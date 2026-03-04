import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/common/encryption/encryption_service.dart';
import 'package:whatsapp_clone/models/chat_contact.dart';
import 'package:whatsapp_clone/screens/chat/Screens/contacts_list_screen.dart';
import 'package:whatsapp_clone/screens/chat/Screens/empty_contacts_screen.dart';

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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const EmptyContactsScreen();
        }

        return FutureBuilder<List<ChatContact>>(
          future: Future.wait(
            docs.map((doc) async {
              final data = doc.data() as Map<String, dynamic>;
              final participants = data['participants'] as List<dynamic>? ?? [];
              if (participants.isEmpty) return null;

              final otherUid = participants.firstWhere(
                (uid) => uid != userId,
                orElse: () => null,
              );
              if (otherUid == null) return null;

              final otherUserDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUid)
                  .get();
              if (!otherUserDoc.exists) return null;

              final otherUserData = otherUserDoc.data() ?? {};
              final modifiedData = Map<String, dynamic>.from(data);

              final lastMsgSnap = await FirebaseFirestore.instance
                  .collection('Chats')
                  .doc(doc.id)
                  .collection('messages')
                  .orderBy('time', descending: true)
                  .limit(1)
                  .get();

              String realLastMessage = 'Message';
              if (lastMsgSnap.docs.isNotEmpty) {
                final lastMsgData = lastMsgSnap.docs.first.data();
                final senderId = lastMsgData['senderId'] ?? '';
                final textField = senderId == userId
                    ? lastMsgData['encryptedSenderCopy'] ??
                          lastMsgData['plainText'] ??
                          'Message'
                    : lastMsgData['encryptedText'] ??
                          lastMsgData['text'] ??
                          'Message';

                try {
                  realLastMessage = await EncryptionService().decryptMessage(
                    textField,
                    userId,
                  );
                } catch (_) {
                  realLastMessage = senderId == userId
                      ? lastMsgData['plainText'] ?? 'Message'
                      : 'Message';
                }
              }

              modifiedData['lastMessage'] = realLastMessage;

              return ChatContact.fromMap(
                modifiedData,
                doc.id,
                userId,
                otherUserData,
              );
            }),
          ).then((list) => list.whereType<ChatContact>().toList()),
          builder: (context, chatSnapshot) {
            if (chatSnapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${chatSnapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (!chatSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final chats = chatSnapshot.data!;

            if (chats.isEmpty) return const EmptyContactsScreen();

            return ContactsListScreen(contacts: chats);
          },
        );
      },
    );
  }
}
