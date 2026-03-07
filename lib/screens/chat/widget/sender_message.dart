import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/chat/widget/bubble_tail_painter.dart';
import 'package:whatsapp_clone/screens/chat/widget/link_preview_card.dart';
import 'package:whatsapp_clone/screens/chat/widget/media_message_bubble.dart';
import 'package:whatsapp_clone/screens/chat/widget/message_helper.dart';

class SenderMessage extends StatelessWidget {
  final String text;
  final String time;
  final bool showTail;
  final bool isGrouped;
  final bool showTime;
  final String? mediaUrl;
  final String? mediaType;
  final String? fileName;
  final int? fileSize;
  final int? duration;

  const SenderMessage({
    super.key,
    required this.text,
    required this.time,
    this.showTail = true,
    this.isGrouped = false,
    this.showTime = true,
    this.mediaUrl,
    this.mediaType,
    this.fileName,
    this.fileSize,
    this.duration,
  });

  static const double _fontSize = 15.0;
  static const double _timeFontSize = 11.0;

  double _getTimeWidth(BuildContext context) {
    final tp = TextPainter(
      text: TextSpan(
        text: time,
        style: const TextStyle(fontSize: _timeFontSize),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width + 6;
  }

  @override
  Widget build(BuildContext context) {
    if (mediaUrl != null && mediaUrl!.isNotEmpty) {
      return MediaMessageBubble(
        mediaUrl: mediaUrl!,
        mediaType: mediaType ?? 'file',
        fileName: fileName,
        fileSize: fileSize,
        duration: duration,
        time: time,
        isMe: true,
        showTail: showTail,
        isGrouped: isGrouped,
        showTime: showTime,
      );
    }
    final timeWidth = showTime ? _getTimeWidth(context) : 0.0;
    final hasUrl = isUri(text);
    final url = hasUrl ? extractUrl(text) : null;

    if (hasUrl && url != null) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: isGrouped ? 1 : 5,
          horizontal: 1,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: LinkPreviewCard(url: url, isMe: true),
              ),
              if (showTime) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    time,
                    style: const TextStyle(
                      color: whiteColor,
                      fontSize: _timeFontSize,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isGrouped ? 1 : 5, horizontal: 1),
      child: Align(
        alignment: Alignment.centerRight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                margin: const EdgeInsets.only(left: 40, right: 8, bottom: 2),
                padding: const EdgeInsets.only(
                  left: 13,
                  right: 13,
                  top: 9,
                  bottom: 9,
                ),
                decoration: BoxDecoration(
                  color: senderMessageColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: const Radius.circular(20),
                    bottomRight: showTail
                        ? const Radius.circular(5)
                        : const Radius.circular(20),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: _fontSize,
                        ),
                        children: [
                          TextSpan(text: text),
                          if (showTime)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.bottom,
                              child: SizedBox(
                                width: timeWidth,
                                height: _timeFontSize,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showTime)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Text(
                          time,
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: _timeFontSize,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (showTail)
              Positioned(
                bottom: 0,
                right: -1,
                child: CustomPaint(
                  painter: BubbleTailPainter(
                    color: senderMessageColor,
                    isMe: true,
                  ),
                  size: const Size(13, 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
