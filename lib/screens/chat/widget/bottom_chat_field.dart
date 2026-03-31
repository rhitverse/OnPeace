import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:on_peace/screens/chat/group/controller/group_chat_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/chat/provider/chat_provider.dart';
import 'package:on_peace/screens/chat/widget/attachment_send_screen.dart';
import 'package:on_peace/screens/chat/widget/attachment_sheet.dart';
import 'package:on_peace/screens/chat/widget/custom_emoji_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/screens/chat/widget/voice_recorder_field.dart';
import 'package:on_peace/screens/chat/widget/create_poll_screen.dart';

enum ChatInputMode { none, attachment, recording }

class BottomChatField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showEmoji;
  final VoidCallback onEmojiTap;
  final VoidCallback onSend;
  final String chatId;
  final String receiverUid;
  final bool isGroupChat;

  const BottomChatField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.showEmoji,
    required this.onEmojiTap,
    required this.onSend,
    required this.chatId,
    required this.receiverUid,
    this.isGroupChat = false,
  });

  @override
  ConsumerState<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends ConsumerState<BottomChatField>
    with SingleTickerProviderStateMixin {
  final ScrollController _emojiScrollController = ScrollController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  ChatInputMode _mode = ChatInputMode.none;

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

  void _setMode(ChatInputMode newMode) {
    if (widget.showEmoji) widget.onEmojiTap();

    widget.focusNode.unfocus();

    final resolvedMode = _mode == newMode ? ChatInputMode.none : newMode;

    setState(() => _mode = resolvedMode);

    if (resolvedMode == ChatInputMode.attachment) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
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
    }
  }

  Future<void> _openPollCreation() async {
    setState(() {
      _mode = ChatInputMode.none;
      _animController.reverse();
    });

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final pollData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePollScreen(
          chatId: widget.chatId,
          currentUserId: currentUserId,
        ),
      ),
    );

    if (pollData != null && mounted) {
      debugPrint('Poll created: ${pollData['question']}');
      debugPrint('Options: ${pollData['options']}');
    }
  }

  Future<void> _openAttachmentScreen() async {
    setState(() {
      _mode = ChatInputMode.none;
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
            isGroupChat: widget.isGroupChat,
          ),
        ),
      );
    }
  }

  FileType _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return FileType.image;
    }
    if (['mp4', 'avi', 'mov', 'flv'].contains(ext)) return FileType.video;
    return FileType.custom;
  }

  void _openGalleryAttachment() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    showAttachmentSheet(
      context,
      chatId: widget.chatId,
      receiverUid: widget.receiverUid,
      currentUid: currentUid,
      isGroupChat: widget.isGroupChat,
    );
  }

  Future<void> _sendGif(String gifUrl) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    try {
      if (widget.isGroupChat) {
        final currentUserData = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();

        final senderName = currentUserData.data()?['displayname'] ?? 'Unknown';
        final senderProfilePic = currentUserData.data()?['profilePic'] ?? '';

        await ref
            .read(groupChatControllerProvider)
            .sendGif(
              groupId: widget.chatId,
              senderId: currentUid,
              senderName: senderName,
              senderProfilePic: senderProfilePic,
              gifUrl: gifUrl,
            );
      } else {
        await ref
            .read(chatControllerProvider)
            .sendGif(
              chatId: widget.chatId,
              senderId: currentUid,
              gifUrl: gifUrl,
              receiverId: widget.receiverUid,
            );
      }
    } catch (e) {
      print('GIF send error: $e');
    }
  }

  @override
  void dispose() {
    _emojiScrollController.dispose();
    _animController.dispose();
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
              border: Border.all(color: const Color(0xff2A2F33), width: 1.4),
            ),
            child: Center(
              child: SizedBox(
                width: iconWidth,
                height: iconHeight,
                child: SvgPicture.asset(
                  svgPath,
                  fit: BoxFit.contain,
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
          color: backgroundColor,
          child: Wrap(
            spacing: 30,
            runSpacing: 20,
            children: [
              _attachmentItem(
                svgPath: 'assets/svg/photos.svg',
                label: 'Gallery',
                iconWidth: 54,
                iconHeight: 54,
                onTap: () {
                  setState(() {
                    _mode = ChatInputMode.none;
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
                    _mode = ChatInputMode.none;
                    _animController.reverse();
                  });
                  await _openGoogleMaps();
                },
              ),
              _attachmentItem(
                svgPath: 'assets/svg/poll.svg',
                label: 'Poll',
                svgColor: const Color(0xffFF8314),
                iconHeight: 55,
                iconWidth: 55,
                onTap: _openPollCreation,
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
    final isAttachment = _mode == ChatInputMode.attachment;
    final isRecording = _mode == ChatInputMode.recording;

    return Column(
      mainAxisSize: MainAxisSize.min,
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
            bottom: !widget.showEmoji && !isAttachment,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _setMode(ChatInputMode.attachment),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: CircleAvatar(
                      key: ValueKey(isAttachment),
                      backgroundColor: Colors.grey[900],
                      radius: 24,
                      child: Icon(
                        isAttachment ? Icons.close : Icons.add,
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
                        setState(() {
                          _mode = ChatInputMode.none;
                          _animController.reverse();
                        });
                        if (widget.showEmoji) widget.onEmojiTap();
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
                            setState(() {
                              _mode = ChatInputMode.none;
                              _animController.reverse();
                            });
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
                      onTap: hasText
                          ? widget.onSend
                          : () => _setMode(ChatInputMode.recording),
                      child: isRecording
                          ? const Icon(Icons.close, color: whiteColor, size: 28)
                          : SvgPicture.asset(
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
        if (isAttachment) _buildAttachmentPanel(),
        if (widget.showEmoji)
          SizedBox(
            height: _emojiHeight(context),
            child: CustomEmojiPicker(
              controller: widget.controller,
              scrollController: _emojiScrollController,
              onGiftSelected: _sendGif,
            ),
          ),
        if (isRecording)
          VoiceRecorderField(
            chatId: widget.chatId,
            receiverUid: widget.receiverUid,
            isGroupChat: widget.isGroupChat,
            onRecordingDone: () => setState(() => _mode = ChatInputMode.none),
          ),
      ],
    );
  }
}
