import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/chat/widget/bubble_tail_painter.dart';
import 'package:whatsapp_clone/screens/chat/widget/link_preview_card.dart';
import 'package:whatsapp_clone/screens/chat/widget/message_helper.dart';

class ReceiverMessage extends StatelessWidget {
  final String text;
  final String time;
  final bool showTail;
  final bool isGrouped;
  const ReceiverMessage({
    super.key,
    required this.text,
    required this.time,
    this.showTail = true,
    this.isGrouped = false,
  });

  static const double _fontSize = 16.0;
  static const double _timeFontSize = 11.0;

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

  @override
  Widget build(BuildContext context) {
    final timeWidth = _getTimeWidth(context);
    const double spacerHeight = _timeFontSize;

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
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isGrouped ? 1 : 5, horizontal: 1),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                margin: const EdgeInsets.only(left: 8, right: 40, bottom: 2),
                padding: const EdgeInsets.only(
                  left: 13,
                  right: 13,
                  top: 8,
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
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
                          WidgetSpan(
                            alignment: PlaceholderAlignment.bottom,
                            child: SizedBox(
                              width: timeWidth,
                              height: spacerHeight,
                            ),
                          ),
                        ],
                      ),
                    ),
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
    );
  }
}
