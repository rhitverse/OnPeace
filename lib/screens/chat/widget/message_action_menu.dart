import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/chat/forward/forward_messages_screen.dart';
import 'package:on_peace/widgets/helpful_widgets/custom_messenger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vision_gallery_saver/vision_gallery_saver.dart';

class MessageActionMenu {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> messageData,
    VoidCallback? onReply,
    Future<void> Function()? onDelete,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    late OverlayEntry dismissEntry;
    bool isRemoved = false;

    final currentUserId = messageData['currentUserId'] as String? ?? '';
    final senderId = messageData['senderId'] as String? ?? '';
    final isOwnMessage = senderId == currentUserId;

    void removeOverlay() {
      if (!isRemoved) {
        isRemoved = true;
        try {
          overlayEntry.remove();
        } catch (_) {}
        try {
          dismissEntry.remove();
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

                  GestureDetector(
                    onTap: () {
                      removeOverlay();
                      if (onReply != null) {
                        onReply();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/svg/reply.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              whiteColor,
                              BlendMode.srcIn,
                            ),
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
                          SvgPicture.asset(
                            'assets/svg/message.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              whiteColor,
                              BlendMode.srcIn,
                            ),
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
                          SvgPicture.asset(
                            'assets/svg/reactEmoji.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              whiteColor,
                              BlendMode.srcIn,
                            ),
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

                  if (messageData['mediaUrl'] != null &&
                      (messageData['mediaUrl'] as String).isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        removeOverlay();

                        final mediaUrl = messageData['mediaUrl'] as String?;
                        final mediaType = messageData['mediaType'] as String?;

                        if (mediaUrl != null && mediaUrl.isNotEmpty) {
                          _downloadMedia(context, mediaUrl, mediaType);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/svg/download.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                whiteColor,
                                BlendMode.srcIn,
                              ),
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
                          SvgPicture.asset(
                            'assets/svg/delete.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Colors.red,
                              BlendMode.srcIn,
                            ),
                          ),
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

    dismissEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
        child: GestureDetector(
          onTap: () {
            removeOverlay();
          },
          child: Container(color: Colors.transparent),
        ),
      ),
    );

    overlay.insert(dismissEntry);
    overlay.insert(overlayEntry);
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

      final hour = messageTime.hour;
      final minute = messageTime.minute.toString().padLeft(2, '0');
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final amPm = hour >= 12 ? 'PM' : 'AM';
      final timeStr = '$hour12:$minute $amPm';

      if (difference == 0) {
        return timeStr;
      } else if (difference == 1) {
        return 'Yesterday $timeStr';
      } else if (difference < 7) {
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
        return '${messageTime.day}/${messageTime.month} $timeStr';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  static Future<void> _downloadMedia(
    BuildContext context,
    String url,
    String? mediaType,
  ) async {
    try {
      bool granted = false;

      if (mediaType == 'video') {
        final status = await Permission.videos.request();
        granted = status.isGranted;
      } else {
        final status = await Permission.photos.request();
        granted = status.isGranted;
      }

      if (!granted) {
        final status = await Permission.storage.request();
        granted = status.isGranted;
      }

      if (!granted) {
        if (context.mounted) {
          CustomMessenger.show(context, "Storage permission denied");
        }
        return;
      }

      if (context.mounted) {
        CustomMessenger.show(context, "Downloading...");
      }

      final dir = await getTemporaryDirectory();
      final ext = url.split('.').last.split('?').first;
      final filePath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext';

      final dio = Dio();
      await dio.download(url, filePath);

      if (mediaType == 'image' || mediaType == 'gif' || mediaType == 'video') {
        await VisionGallerySaver.saveFile(filePath);
        if (context.mounted) {
          CustomMessenger.show(context, "Saved to gallery");
        }
      } else {
        if (context.mounted) {
          CustomMessenger.show(context, "File downloaded");
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomMessenger.show(context, "Download failed");
      }
      debugPrint('Download error: $e');
    }
  }

  static void _copyToClipboard(BuildContext context, String text) {
    CustomMessenger.show(context, "Message copied");
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
