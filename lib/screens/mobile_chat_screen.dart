import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/chat/provider/chat_provider.dart';
import 'package:whatsapp_clone/screens/chat/widget/bottom_chat_field.dart';
import 'package:whatsapp_clone/screens/chat/widget/receiver_message.dart';
import 'package:whatsapp_clone/screens/chat/widget/sender_message.dart';

class MobileChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String receiverUid;
  final String receiverDisplayName;
  final String receiverProfilePic;

  const MobileChatScreen({
    super.key,
    required this.chatId,
    required this.receiverUid,
    required this.receiverDisplayName,
    required this.receiverProfilePic,
  });

  @override
  ConsumerState<MobileChatScreen> createState() => _MobileChatScreenState();
}

class _MobileChatScreenState extends ConsumerState<MobileChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool showEmoji = false;
  FocusNode focusNode = FocusNode();
  String receiverDisplayName = '';
  String receiverProfilePic = '';

  @override
  void initState() {
    super.initState();
    receiverDisplayName = widget.receiverDisplayName;
    receiverProfilePic = widget.receiverProfilePic;

    focusNode.addListener(() {
      if (focusNode.hasFocus && showEmoji) {
        setState(() => showEmoji = false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        ref
            .read(chatControllerProvider)
            .markAsRead(widget.chatId, currentUserId);
      }
    });
  }

  void onEmojiTap() {
    setState(() => showEmoji = !showEmoji);
    if (showEmoji) {
      focusNode.unfocus();
    } else {
      focusNode.requestFocus();
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) return;
    final messageText = _messageController.text.trim();
    _messageController.clear();
    try {
      await ref
          .read(chatControllerProvider)
          .sendMessage(
            chatId: widget.chatId,
            senderId: currentUserId,
            text: messageText,
            receiverId: widget.receiverUid,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: !showEmoji,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        backgroundColor: backgroundColor,
        elevation: 0,
        titleSpacing: 0,
        leadingWidth: 40,
        leading: IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: receiverProfilePic.isNotEmpty
                  ? NetworkImage(receiverProfilePic)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                receiverDisplayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: whiteColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: whiteColor),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call, color: whiteColor),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: whiteColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref
                  .read(chatControllerProvider)
                  .getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox();
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index];
                    final senderId = messageData['senderId'] ?? '';
                    final text = messageData['text'] ?? '';
                    final timeStr = messageData['time'];

                    final isMe = senderId == currentUserId;
                    String timeString = '';
                    try {
                      if (timeStr is String) {
                        timeString = DateFormat(
                          'h:mm a',
                        ).format(DateTime.parse(timeStr));
                      }
                    } catch (_) {}

                    bool showTail = true;
                    bool isGrouped = false;
                    if (index > 0) {
                      final prev = messages[index - 1];
                      if (prev['senderId'] == senderId) {
                        showTail = false;
                        isGrouped = true;
                      }
                    }

                    return isMe
                        ? SenderMessage(
                            text: text,
                            time: timeString,
                            showTail: showTail,
                            isGrouped: isGrouped,
                          )
                        : ReceiverMessage(
                            text: text,
                            time: timeString,
                            showTail: showTail,
                            isGrouped: isGrouped,
                          );
                  },
                );
              },
            ),
          ),
          BottomChatField(
            controller: _messageController,
            focusNode: focusNode,
            showEmoji: showEmoji,
            onEmojiTap: onEmojiTap,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
