import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/chat/widget/attachment_sheet.dart';
import 'package:whatsapp_clone/screens/chat/widget/custom_emoji_picker.dart';

class BottomChatField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showEmoji;
  final VoidCallback onEmojiTap;
  final VoidCallback onSend;

  const BottomChatField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.showEmoji,
    required this.onEmojiTap,
    required this.onSend,
  });

  @override
  State<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends State<BottomChatField>
    with SingleTickerProviderStateMixin {
  final ScrollController _emojiScrollController = ScrollController();
  bool _showAttachment = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  void _toggleAttachment() {
    setState(() {
      _showAttachment = !_showAttachment;
      if (_showAttachment) {
        widget.focusNode.unfocus();
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  double _emojiHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    const appBarHeight = kToolbarHeight;
    const chatFieldHeight = 66.0;

    final available =
        screenHeight -
        padding.top -
        padding.bottom -
        appBarHeight -
        chatFieldHeight;

    return available.clamp(200.0, 450.0);
  }

  @override
  void dispose() {
    _emojiScrollController.dispose();
    super.dispose();
  }

  Widget _attachmentItem({
    required String svgPath,
    required String label,
    Color? svgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 64,
            decoration: BoxDecoration(
              color: attacment,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SvgPicture.asset(
              svgPath,
              width: 32,
              height: 32,
              colorFilter: svgColor != null
                  ? ColorFilter.mode(svgColor, BlendMode.srcIn)
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPanel() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SizeTransition(
        sizeFactor: _fadeAnim,
        axisAlignment: 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(color: backgroundColor),
          child: Wrap(
            spacing: 30,
            runSpacing: 20,
            alignment: WrapAlignment.start,
            children: [
              _attachmentItem(
                svgPath: 'assets/svg/photos.svg',
                label: 'Gallery',
                onTap: () => showAttachmentSheet(context),
              ),
              _attachmentItem(
                svgPath: 'assets/svg/file.svg',
                label: 'File',
                onTap: () {},
              ),
              _attachmentItem(
                svgPath: 'assets/svg/location.svg',
                label: 'Location',
                onTap: () {},
              ),
              _attachmentItem(
                svgPath: 'assets/svg/poll.svg',
                label: 'Poll',
                svgColor: Color(0xffFF8314),
                onTap: () {},
              ),
              _attachmentItem(
                svgPath: 'assets/svg/diary.svg',
                label: 'Diary',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: BorderSide(color: Colors.grey[900]!, width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: !widget.showEmoji && !_showAttachment,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleAttachment,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: CircleAvatar(
                      key: ValueKey(_showAttachment),
                      backgroundColor: _showAttachment
                          ? Colors.grey[900]
                          : Colors.grey[900],
                      radius: 24,
                      child: Icon(
                        _showAttachment ? Icons.close : Icons.add,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey[800]!, width: 1),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      readOnly: widget.showEmoji,
                      style: const TextStyle(color: Colors.white),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      onTap: () {
                        if (_showAttachment) {
                          setState(() {
                            _showAttachment = false;
                            _animController.reverse();
                          });
                        }
                      },
                      onSubmitted: (_) => widget.onSend(),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            widget.focusNode.unfocus();
                            widget.onEmojiTap();
                          },
                          child: Icon(
                            widget.showEmoji
                                ? Icons.keyboard_alt_outlined
                                : Icons.emoji_emotions_outlined,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        contentPadding: const EdgeInsets.only(
                          top: 10,
                          bottom: 10,
                          left: 16,
                          right: 8,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (context, value, child) {
                    final hasText = value.text.trim().isNotEmpty;
                    return GestureDetector(
                      onTap: hasText ? widget.onSend : null,
                      child: SvgPicture.asset(
                        hasText
                            ? "assets/svg/message.svg"
                            : "assets/svg/mic.svg",
                        width: 28,
                        height: 28,
                        colorFilter: const ColorFilter.mode(
                          whiteColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (_showAttachment) _buildAttachmentPanel(),
        if (widget.showEmoji)
          SizedBox(
            height: _emojiHeight(context),
            child: CustomEmojiPicker(
              controller: widget.controller,
              scrollController: _emojiScrollController,
            ),
          ),
      ],
    );
  }
}
