import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/common/utils/time_utils.dart';
import 'package:on_peace/models/chat_contact.dart';
import 'package:on_peace/screens/mobile_chat_screen.dart';

class ContactsListScreen extends StatelessWidget {
  final List<ChatContact> contacts;

  const ContactsListScreen({super.key, required this.contacts});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: contacts.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final chat = contacts[index];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MobileChatScreen(
                    chatId: chat.chatId,
                    receiverUid: chat.receiverUid,
                    receiverDisplayName: chat.receiverDisplayName,
                    receiverProfilePic: chat.receiverProfilePic,
                  ),
                ),
              );
            },
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: chat.receiverProfilePic.isNotEmpty
                        ? NetworkImage(chat.receiverProfilePic)
                        : null,
                    child: chat.receiverProfilePic.isEmpty
                        ? Icon(Icons.person, size: 28, color: Colors.grey[600])
                        : null,
                  ),

                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat.receiverDisplayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: whiteColor,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),

                            Text(
                              getRelativeTime(chat.lastMessageTime),
                              style: TextStyle(
                                fontSize: 13,
                                color: chat.unreadCount > 0
                                    ? whiteColor
                                    : Colors.grey[500],
                                fontWeight: chat.unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (chat.lastMessageMediaType != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _getMediaIcon(
                                  chat.lastMessageMediaType!,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                chat.lastMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: chat.unreadCount > 0
                                      ? whiteColor
                                      : Colors.grey[400],
                                  fontWeight: chat.unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (chat.unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: uiColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  chat.unreadCount.toString(),
                                  style: const TextStyle(
                                    color: whiteColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Icon _getMediaIcon(String mediaType) {
    switch (mediaType) {
      case 'image':
        return const Icon(Icons.image_outlined, size: 20, color: Colors.grey);
      case 'video':
        return const Icon(
          Icons.videocam_outlined,
          size: 20,
          color: Colors.grey,
        );
      case 'gif':
        return const Icon(Icons.gif_box_outlined, size: 20, color: Colors.grey);
      default:
        return const Icon(Icons.attachment, size: 20, color: Colors.grey);
    }
  }
}
