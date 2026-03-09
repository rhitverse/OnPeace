import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/chat/provider/chat_provider.dart';
import 'package:whatsapp_clone/screens/chat/widget/attachment_send_screen.dart';
import 'package:whatsapp_clone/screens/chat/widget/attachment_sheet.dart';
import 'package:whatsapp_clone/screens/chat/widget/custom_emoji_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomChatField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showEmoji;
  final VoidCallback onEmojiTap;
  final VoidCallback onSend;
  final String chatId;
  final String receiverUid;

  const BottomChatField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.showEmoji,
    required this.onEmojiTap,
    required this.onSend,
    required this.chatId,
    required this.receiverUid,
  });

  @override
  ConsumerState<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends ConsumerState<BottomChatField>
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
      if (widget.showEmoji) {
        widget.onEmojiTap();
      }
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

  Future<void> _openGoogleMaps() async {
    final Uri googleMapUrl = Uri.parse("geo:0,0?q=my+location");

    if (await canLaunchUrl(googleMapUrl)) {
      await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not Open Google Maps");
    }
  }

  Future<void> _openAttachmentScreen() async {
    setState(() {
      _showAttachment = false;
      _animController.reverse();
    });
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result == null) return;
    if (!mounted) return;

    List<FileAttachment> files = [];
    for (var file in result.files) {
      if (file.path != null) {
        files.add(
          FileAttachment(
            filePath: file.path!,
            fileName: file.name,
            fileSize: file.size,
            fileType: _getFileType(file.name),
          ),
        );
      }
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttachmentSendScreen(
            chatId: widget.chatId,
            receiverUid: widget.receiverUid,
            initialFiles: files,
          ),
        ),
      );
    }
  }

  FileType _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return FileType.image;
    } else if (['mp4', 'avi', 'mov', 'flv'].contains(ext)) {
      return FileType.video;
    } else if (['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'].contains(ext)) {
      return FileType.custom;
    }
    return FileType.custom;
  }

  void _openGalleryAttachment() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showAttachmentSheet(
      context,
      chatId: widget.chatId,
      receiverUid: widget.receiverUid,
      currentUid: currentUid,
    );
  }

  Future<void> _sendGif(String gifUrl) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    try {
      await ref
          .read(chatControllerProvider)
          .sendGif(
            chatId: widget.chatId,
            senderId: currentUid,
            gifUrl: gifUrl,
            receiverId: widget.receiverUid,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send GIF')));
      }
    }
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
    double iconWidth = 22,
    double iconHeight = 22,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 68,
            decoration: BoxDecoration(
              color: attacment,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xff2A2F33), width: 1.4),
            ),
            child: Center(
              child: SizedBox(
                width: iconWidth,
                height: iconHeight,
                child: SvgPicture.asset(
                  svgPath,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  colorFilter: svgColor != null
                      ? ColorFilter.mode(svgColor, BlendMode.srcIn)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
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
                iconWidth: 54,
                iconHeight: 54,
                onTap: () {
                  setState(() {
                    _showAttachment = false;
                    _animController.reverse();
                  });
                  _openGalleryAttachment();
                },
              ),
              _attachmentItem(
                svgPath: 'assets/svg/file.svg',
                label: 'File',
                iconHeight: 42,
                iconWidth: 42,
                onTap: _openAttachmentScreen,
              ),
              _attachmentItem(
                svgPath: 'assets/svg/location.svg',
                label: 'Location',
                iconHeight: 52,
                iconWidth: 52,
                onTap: () async {
                  setState(() {
                    _showAttachment = false;
                    _animController.reverse();
                  });
                  await _openGoogleMaps();
                },
              ),

              _attachmentItem(
                svgPath: 'assets/svg/poll.svg',
                label: 'Poll',
                svgColor: Color(0xffFF8314),
                iconHeight: 55,
                iconWidth: 55,
                onTap: () {},
              ),
              _attachmentItem(
                svgPath: 'assets/svg/diary.svg',
                label: 'Diary',
                iconHeight: 52,
                iconWidth: 52,
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
                            if (_showAttachment) {
                              setState(() {
                                _showAttachment = false;
                                _animController.reverse();
                              });
                            }
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
              onGiftSelected: _sendGif,
            ),
          ),
      ],
    );
  }
}
