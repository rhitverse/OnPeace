import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/chat/forward/forward_messages_screen.dart';

class MessageActionMenu {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> messageData,
    VoidCallback? onReply,
    Future<void> Function()? onDelete,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    bool isRemoved = false;

    // Get current user ID to check if this is sender's own message
    final currentUserId = messageData['currentUserId'] as String? ?? '';
    final senderId = messageData['senderId'] as String? ?? '';
    final isOwnMessage = senderId == currentUserId;

    void removeOverlay() {
      if (!isRemoved) {
        isRemoved = true;
        try {
          overlayEntry.remove();
        } catch (_) {}
      }
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        right: 16,
        bottom: 100,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: searchBarColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: whiteColor.withOpacity(0.08),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              width: 180,
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _formatMessageTime(messageData['time']),
                      style: TextStyle(
                        color: whiteColor.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ),

                  Divider(color: whiteColor.withOpacity(0.07), height: 1),

                  // Reply
                  if (onReply != null)
                    GestureDetector(
                      onTap: () {
                        removeOverlay();
                        onReply();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.reply,
                              color: whiteColor,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Reply',
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Copy
                  if ((messageData['text'] as String?)?.isNotEmpty ?? false)
                    GestureDetector(
                      onTap: () {
                        removeOverlay();
                        _copyToClipboard(
                          context,
                          messageData['text'] as String,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.copy, color: whiteColor, size: 18),
                            const SizedBox(width: 10),
                            const Text(
                              'Copy',
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Forward
                  GestureDetector(
                    onTap: () {
                      removeOverlay();
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
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.share_outlined,
                            color: whiteColor,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Forward',
                            style: TextStyle(
                              color: whiteColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // React
                  GestureDetector(
                    onTap: () {
                      removeOverlay();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_emotions_outlined,
                            color: whiteColor,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'React',
                            style: TextStyle(
                              color: whiteColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Download
                  if (messageData['mediaUrl'] != null &&
                      (messageData['mediaUrl'] as String).isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        removeOverlay();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.download,
                              color: whiteColor,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Download',
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Delete
                  GestureDetector(
                    onTap: () {
                      removeOverlay();
                      if (onDelete != null) {
                        _showDeleteConfirmation(
                          context,
                          onDelete,
                          isOwnMessage,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            isOwnMessage ? 'Delete' : 'Delete for you',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
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
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Dismiss on tap outside
    Future.delayed(Duration.zero, () {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => GestureDetector(
            onTap: () {
              removeOverlay();
              Navigator.pop(context);
            },
            child: Container(color: Colors.transparent),
          ),
        ),
      );
    });
  }

  static String _formatMessageTime(dynamic timeValue) {
    try {
      if (timeValue == null) return 'Just now';

      DateTime messageTime;
      if (timeValue is DateTime) {
        messageTime = timeValue;
      } else if (timeValue is int) {
        messageTime = DateTime.fromMillisecondsSinceEpoch(timeValue);
      } else if (timeValue is String) {
        messageTime = DateTime.parse(timeValue);
      } else {
        return 'Just now';
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(
        messageTime.year,
        messageTime.month,
        messageTime.day,
      );
      final difference = today.difference(messageDate).inDays;

      // Format time in 12-hour format with AM/PM
      final hour = messageTime.hour;
      final minute = messageTime.minute.toString().padLeft(2, '0');
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final amPm = hour >= 12 ? 'PM' : 'AM';
      final timeStr = '$hour12:$minute $amPm';

      if (difference == 0) {
        // Today
        return timeStr;
      } else if (difference == 1) {
        // Yesterday
        return 'Yesterday $timeStr';
      } else if (difference < 7) {
        // Within the week
        final dayName = [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ][messageTime.weekday - 1];
        return '$dayName $timeStr';
      } else {
        // Older than a week
        return '${messageTime.day}/${messageTime.month} $timeStr';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  static void _copyToClipboard(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  static void _showDeleteConfirmation(
    BuildContext context,
    Future<void> Function() onDelete,
    bool isOwnMessage,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isOwnMessage ? 'Delete message?' : 'Delete for you?',
          style: const TextStyle(color: whiteColor, fontSize: 14),
        ),
        backgroundColor: fileContentDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),

        content: Text(
          isOwnMessage
              ? 'This message will be permanently deleted for everyone.'
              : 'This message will only be deleted for you. Others will still be able to see it.',
          style: const TextStyle(color: whiteColor, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: whiteColor, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await onDelete();
              } catch (e) {
                print('failed in error $e');
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
