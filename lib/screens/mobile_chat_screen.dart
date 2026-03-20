import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/calls/controller/call_provider.dart';
import 'package:whatsapp_clone/screens/chat/provider/chat_provider.dart';
import 'package:whatsapp_clone/screens/chat/widget/bottom_chat_field.dart';
import 'package:whatsapp_clone/screens/chat/widget/chat_loader.dart';
import 'package:whatsapp_clone/screens/chat/widget/date_chip.dart';
import 'package:whatsapp_clone/screens/chat/widget/profile/view_profile_screen.dart';
import 'package:whatsapp_clone/screens/chat/widget/profile/view_profile_unknown.dart';
import 'package:whatsapp_clone/screens/chat/widget/receiver_message.dart';
import 'package:whatsapp_clone/screens/chat/widget/sender_message.dart';
import 'package:whatsapp_clone/screens/chat/provider/uploading_messages_provider.dart';

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

  bool _isDifferentDay(String? t1, String? t2) {
    if (t1 == null || t2 == null) return false;
    try {
      final d1 = DateTime.parse(t1);
      final d2 = DateTime.parse(t2);
      return d1.year != d2.year || d1.month != d2.month || d1.day != d2.day;
    } catch (_) {
      return false;
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewProfileUnknown(
          receiverUid: widget.receiverUid,
          receiverDisplayName: receiverDisplayName,
          receiverProfilePic: receiverProfilePic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final uploadingMessages = ref.watch(uploadingMessagesProvider);
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
        title: GestureDetector(
          onTap: _openProfile,
          child: Row(
            children: [
              GestureDetector(
                onTap: _openProfile,
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: receiverProfilePic.isNotEmpty
                      ? NetworkImage(receiverProfilePic)
                      : null,
                ),
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
        ),
        actions: [
          GestureDetector(
            onTap: () {
              ref
                  .read(callControllerProvider.notifier)
                  .startCall(
                    receiverId: widget.receiverUid,
                    isVideo: true,
                    context: context,
                  );
            },
            child: SvgPicture.asset(
              'assets/svg/videocall.svg',
              width: 27,
              height: 27,
              color: whiteColor,
            ),
          ),
          SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              ref
                  .read(callControllerProvider.notifier)
                  .startCall(
                    receiverId: widget.receiverUid,
                    isVideo: false,
                    context: context,
                  );
            },
            child: SvgPicture.asset(
              'assets/svg/call1.svg',
              width: 27,
              height: 27,
              color: whiteColor,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert_outlined, size: 26, color: whiteColor),
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
                if (!snapshot.hasData) {
                  return const ChatLoader();
                }
                if (snapshot.data!.isEmpty) {
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

                    final mediaUrl = messageData['mediaUrl'];
                    final mediaType = messageData['mediaType'];
                    final fileName = messageData['fileName'];
                    final fileSize = messageData['fileSize'];
                    final duration = messageData['duration'];

                    final messageId = messageData['id'] ?? '';
                    final isLoading = uploadingMessages.contains(messageId);

                    String timeString = '';
                    DateTime? msgDateTime;
                    try {
                      if (timeStr is String) {
                        msgDateTime = DateTime.parse(timeStr);
                        timeString = DateFormat('h:mm a').format(msgDateTime);
                      }
                    } catch (_) {}

                    bool showTail = true;
                    bool isGrouped = false;
                    bool showTime = true;

                    bool showDataChip = false;
                    if (index == messages.length - 1) {
                      showDataChip = true;
                    } else {
                      showDataChip = _isDifferentDay(
                        timeStr,
                        messages[index + 1]['time'],
                      );
                    }

                    if (index > 0) {
                      final prev = messages[index - 1];
                      if (prev['senderId'] == senderId) {
                        showTail = false;
                        isGrouped = true;
                      }

                      String prevTimeString = '';
                      try {
                        final prevTimeStr = prev['time'];
                        if (prevTimeStr is String) {
                          prevTimeString = DateFormat(
                            'h:mm a',
                          ).format(DateTime.parse(prevTimeStr));
                        }
                      } catch (_) {}

                      if (prev['senderId'] == senderId &&
                          prevTimeString == timeString) {
                        showTime = false;
                      }
                    }

                    return Column(
                      children: [
                        if (showDataChip && msgDateTime != null)
                          DateChip(dateTime: msgDateTime),
                        isMe
                            ? SenderMessage(
                                text: text,
                                time: timeString,
                                showTail: showTail,
                                isGrouped: isGrouped,
                                showTime: showTime,
                                mediaUrl: mediaUrl,
                                mediaType: mediaType,
                                fileName: fileName,
                                fileSize: fileSize,
                                duration: duration,
                                isLoading: isLoading,
                              )
                            : ReceiverMessage(
                                text: text,
                                time: timeString,
                                showTail: showTail,
                                isGrouped: isGrouped,
                                showTime: showTime,
                                mediaUrl: mediaUrl,
                                mediaType: mediaType,
                                fileName: fileName,
                                fileSize: fileSize,
                                duration: duration,
                                isLoading: isLoading,
                              ),
                      ],
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
            chatId: widget.chatId,
            receiverUid: widget.receiverUid,
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
