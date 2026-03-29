import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/chat/widget/bubble_tail_painter.dart';

class ChatLoader extends StatefulWidget {
  const ChatLoader({super.key});

  @override
  State<ChatLoader> createState() => _ChatLoaderState();
}

class _ChatLoaderState extends State<ChatLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bubble({
    required bool isMe,
    required double width,
    double height = 26,
    bool showTail = false,
  }) {
    const Color bubbleColor = searchBarColor;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : (showTail ? 18 : 8)),
      bottomRight: Radius.circular(isMe ? (showTail ? 18 : 4) : 18),
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _) => Opacity(
        opacity: _animation.value,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
              right: isMe ? 8 : 0,
              left: isMe ? 0 : 8,
              top: 4,
              bottom: 4,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: borderRadius,
                  ),
                ),

                if (showTail)
                  Positioned(
                    bottom: 0,
                    right: isMe ? 1 : null,
                    left: isMe ? null : 1,
                    child: CustomPaint(
                      size: const Size(16, 34),
                      painter: BubbleTailPainter(
                        color: bubbleColor,
                        isMe: isMe,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _bubble(isMe: false, width: 160),
            _bubble(isMe: false, width: 220, showTail: true),
            const SizedBox(height: 6),

            _bubble(isMe: true, width: 180),
            _bubble(isMe: true, width: 130, showTail: true),
            const SizedBox(height: 6),

            _bubble(isMe: false, width: 200),
            _bubble(isMe: false, width: 100, showTail: true),
            const SizedBox(height: 6),

            _bubble(isMe: true, width: 150),
            _bubble(isMe: true, width: 240),
            _bubble(isMe: true, width: 110, showTail: true),
            const SizedBox(height: 6),

            _bubble(isMe: false, width: 190),
            _bubble(isMe: false, width: 140, showTail: true),
            const SizedBox(height: 6),

            _bubble(isMe: true, width: 170, showTail: true),
            SizedBox(height: 6),
            _bubble(isMe: false, width: 160),
            _bubble(isMe: false, width: 220, showTail: true),
            const SizedBox(height: 6),

            _bubble(isMe: true, width: 180),
            _bubble(isMe: true, width: 130, showTail: true),
            const SizedBox(height: 6),

            _bubble(isMe: false, width: 200),
            _bubble(isMe: false, width: 100, showTail: true),
            const SizedBox(height: 6),

            _bubble(isMe: true, width: 150),
            _bubble(isMe: true, width: 240),
            _bubble(isMe: true, width: 110, showTail: true),
            const SizedBox(height: 6),

            _bubble(isMe: false, width: 190),
            _bubble(isMe: false, width: 140, showTail: true),
            const SizedBox(height: 6),

            _bubble(isMe: true, width: 170, showTail: true),
          ],
        ),
      ),
    );
  }
}
