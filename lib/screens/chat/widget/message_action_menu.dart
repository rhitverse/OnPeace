import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/chat/forward/forward_messages_screen.dart';

class MessageActionMenu {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> messageData,
    VoidCallback? onReply,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: searchBarColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: whiteColor.withOpacity(0.08), width: 0.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: whiteColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Reply Option
            if (onReply != null)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onReply();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.reply, color: whiteColor, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Reply',
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (onReply != null)
              Divider(color: whiteColor.withOpacity(0.07), height: 1),

            // Forward Option
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForwardMessagesScreen(
                      messageData: messageData,
                      isGroupMessage: false,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.share_outlined,
                      color: whiteColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Forward',
                      style: TextStyle(
                        color: whiteColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Divider(color: whiteColor.withOpacity(0.07), height: 1),

            // Copy Option (if text exists)
            if ((messageData['text'] as String?)?.isNotEmpty ?? false)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(context, messageData['text'] as String);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.copy, color: whiteColor, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Copy',
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if ((messageData['text'] as String?)?.isNotEmpty ?? false)
              Divider(color: whiteColor.withOpacity(0.07), height: 1),

            // Delete Option
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _copyToClipboard(BuildContext context, String text) {
    // Implementation will depend on your utils
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  static void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: searchBarColor,
        title: const Text(
          'Delete Message',
          style: TextStyle(color: whiteColor),
        ),
        content: const Text(
          'Are you sure you want to delete this message?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: whiteColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete functionality will be implemented
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
