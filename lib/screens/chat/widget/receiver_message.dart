import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/chat/widget/bubble_tail_painter.dart';
import 'package:on_peace/screens/chat/widget/link_preview_card.dart';
import 'package:on_peace/screens/chat/widget/media_message_bubble.dart';
import 'package:on_peace/screens/chat/widget/message_helper.dart';

class ReceiverMessage extends StatelessWidget {
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
  final bool isLoading;
  final String? replyToText;
  final String? replyToSenderName;
  final String? replyToMediaUrl;
  final String? replyToMediaType;
  final String senderName;
  final VoidCallback? onReplyTap;
  final bool isHighlighted;

  const ReceiverMessage({
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
    this.isLoading = false,
    this.replyToText,
    this.replyToSenderName,
    this.replyToMediaUrl,
    this.replyToMediaType,
    required this.senderName,
    this.onReplyTap,
    this.isHighlighted = false,
  });

  static const double _fontSize = 16.0;
  static const double _timeFontSize = 11.0;

  bool get _hasReply =>
      (replyToText != null && replyToText!.isNotEmpty) ||
      (replyToMediaType != null && replyToMediaType!.isNotEmpty);

  double _getTimeWidth(BuildContext context) {
    final tp = TextPainter(
      text: TextSpan(
        text: time,
        style: const TextStyle(fontSize: _timeFontSize),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return tp.width + 6;
  }

  Widget _buildReplyPreview(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final replierName = senderName;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 4),
            child: Text(
              replierName.isNotEmpty ? '$replierName replied' : 'Replied',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.72),
            child: Container(
              margin: const EdgeInsets.only(left: 10, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (replyToMediaType != null &&
                          replyToMediaType!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (replyToMediaType == 'image' &&
                                replyToMediaUrl != null &&
                                replyToMediaUrl != null &&
                                replyToMediaUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    replyToMediaUrl!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey[700],
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.white54,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Icon(
                              replyToMediaType == 'image'
                                  ? Icons.image_outlined
                                  : replyToMediaType == 'video'
                                  ? Icons.videocam_outlined
                                  : Icons.insert_drive_file_outlined,
                              size: 13,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              replyToMediaType == 'image'
                                  ? 'Photo'
                                  : replyToMediaType == 'video'
                                  ? 'Video'
                                  : 'File',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          replyToText ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12.5,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
        isMe: false,
        showTail: showTail,
        isGrouped: isGrouped,
        showTime: showTime,
        isLoading: isLoading,
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
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: LinkPreviewCard(url: url, isMe: false),
              ),
              if (showTime) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasReply)
            GestureDetector(
              onTap: onReplyTap,
              behavior: HitTestBehavior.opaque,
              child: _buildReplyPreview(context),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 8,
                      right: 40,
                      bottom: 2,
                    ),
                    padding: const EdgeInsets.only(
                      left: 13,
                      right: 13,
                      top: 8,
                      bottom: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? uiColor.withOpacity(0.3)
                          : const Color(0xFF262626),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: showTail
                            ? const Radius.circular(5)
                            : const Radius.circular(20),
                        bottomRight: const Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: whiteColor,
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
                    left: -1,
                    child: CustomPaint(
                      painter: BubbleTailPainter(
                        color: const Color(0xFF262626),
                        isMe: false,
                      ),
                      size: const Size(13, 20),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
