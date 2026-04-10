import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/calls/controller/call_provider.dart';
import 'package:on_peace/screens/chat/provider/chat_provider.dart';
import 'package:on_peace/screens/chat/provider/pending_messages_provider.dart';
import 'package:on_peace/screens/chat/widget/bottom_chat_field.dart';
import 'package:on_peace/screens/chat/widget/chat_loader.dart';
import 'package:on_peace/screens/chat/widget/date_chip.dart';
import 'package:on_peace/screens/chat/widget/message_action_menu.dart';
import 'package:on_peace/screens/chat/widget/profile/view_profile_screen.dart';
import 'package:on_peace/screens/chat/widget/profile/view_profile_unknown.dart';
import 'package:on_peace/screens/chat/widget/receiver_message.dart';
import 'package:on_peace/screens/chat/widget/sender_message.dart';
import 'package:on_peace/screens/chat/provider/uploading_messages_provider.dart';

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
  
  // Reply management
  String? replyingToMessageId;
  String? replyingToText;
  String? replyingToMediaUrl;
  String? replyingToMediaType;
  String? replyingToSenderName = '';

  void _setReply({
    required String messageId,
    required String text,
    String? mediaUrl,
    String? mediaType,
    required String senderName,
  }) {
    setState(() {
      replyingToMessageId = messageId;
      replyingToText = text;
      replyingToMediaUrl = mediaUrl;
      replyingToMediaType = mediaType;
      replyingToSenderName = senderName;
    });
    focusNode.requestFocus();
  }

  void _clearReply() {
    setState(() {
      replyingToMessageId = null;
      replyingToText = null;
      replyingToMediaUrl = null;
      replyingToMediaType = null;
      replyingToSenderName = '';
    });
  }

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

  void _startVideoCall() {
    ref
        .read(callControllerProvider.notifier)
        .startCall(
          receiverId: widget.receiverUid,
          isVideo: true,
          context: context,
        );
  }

  void _startVoiceCall() {
    ref
        .read(callControllerProvider.notifier)
        .startCall(
          receiverId: widget.receiverUid,
          isVideo: false,
          context: context,
        );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) return;
    final messageText = _messageController.text.trim();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    ref
        .read(pendingMessagesProvider.notifier)
        .addPending(
          PendingMessage(
            tempId: tempId,
            text: messageText,
            senderId: currentUserId,
            sentTime: DateTime.now(),
            status: 'sending',
          ),
        );

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

      if (mounted) {
        ref.read(pendingMessagesProvider.notifier).removePending(tempId);
      }
    } catch (e) {
      if (mounted) {
        ref
            .read(pendingMessagesProvider.notifier)
            .updateStatus(tempId, 'failed');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send message'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                ref
                    .read(pendingMessagesProvider.notifier)
                    .removePending(tempId);
                _messageController.text = messageText;
              },
            ),
          ),
        );
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

  Future<void> _openProfile() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final friendQuery = await FirebaseFirestore.instance
        .collection('Friends')
        .where('uid', isEqualTo: currentUid)
        .where('friendUid', isEqualTo: widget.receiverUid)
        .limit(1)
        .get();

    final isFriend = friendQuery.docs.isNotEmpty;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isFriend
            ? ViewProfileScreen(
                receiverUid: widget.receiverUid,
                receiverDisplayName: receiverDisplayName,
                receiverProfilePic: receiverProfilePic,
              )
            : ViewProfileUnknown(
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
            onTap: _startVideoCall,
            child: SvgPicture.asset(
              'assets/svg/videocall.svg',
              width: 27,
              height: 27,
              color: whiteColor,
            ),
          ),
          SizedBox(width: 16),
          GestureDetector(
            onTap: _startVoiceCall,
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
                final firebaseMessages =
                    (snapshot.hasData ? snapshot.data! : [])
                        .cast<Map<String, dynamic>>();
                final pendingMessages = ref.watch(pendingMessagesProvider);

                final allMessages = <Map<String, dynamic>>[];

                allMessages.addAll(firebaseMessages);

                for (final pm in pendingMessages) {
                  bool isDuplicate = false;

                  try {
                    for (final fbMsg in firebaseMessages) {
                      final fbTime = DateTime.tryParse(
                        fbMsg['time'] as String? ?? '',
                      );

                      final senderMatch = fbMsg['senderId'] == pm.senderId;
                      final mediaTypeMatch = fbMsg['mediaType'] == pm.mediaType;

                      final fileNameMatch =
                          pm.fileName != null &&
                          fbMsg['fileName'] == pm.fileName;

                      final timeMatch =
                          fbTime != null &&
                          pm.sentTime.difference(fbTime).inSeconds.abs() < 10;

                      if (senderMatch &&
                          mediaTypeMatch &&
                          (fileNameMatch || timeMatch)) {
                        isDuplicate = true;
                        break;
                      }
                    }
                  } catch (_) {}

                  if (!isDuplicate && pm.localFilePath != null) {
                    for (final fbMsg in firebaseMessages) {
                      if (fbMsg['localFilePath'] == pm.localFilePath) {
                        isDuplicate = true;
                        break;
                      }
                    }
                  }

                  if (!isDuplicate) {
                    allMessages.add({
                      'id': pm.tempId,
                      'text': pm.text,
                      'senderId': pm.senderId,
                      'time': pm.sentTime.toIso8601String(),
                      'mediaUrl': pm.mediaUrl ?? pm.localFilePath,
                      'mediaType': pm.mediaType,
                      'fileName': pm.fileName,
                      'fileSize': pm.fileSize,
                      'duration': pm.duration,
                      'isPending': true,
                      'pendingStatus': pm.status,
                      'localFilePath': pm.localFilePath,
                    });
                  }
                }

                allMessages.sort((a, b) {
                  try {
                    final timeA = DateTime.parse(a['time'] ?? '');
                    final timeB = DateTime.parse(b['time'] ?? '');
                    return timeB.compareTo(timeA);
                  } catch (_) {
                    return 0;
                  }
                });

                if (!snapshot.hasData && pendingMessages.isEmpty) {
                  return const ChatLoader();
                }

                if (allMessages.isEmpty) {
                  return const ChatLoader();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final messageData = allMessages[index];
                    final senderId = messageData['senderId'] ?? '';
                    final text = messageData['text'] ?? '';
                    final timeStr = messageData['time'];
                    final isMe = senderId == currentUserId;
                    final isPending = messageData['isPending'] ?? false;
                    final pendingStatus =
                        messageData['pendingStatus'] ?? 'sending';

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
                    if (index == allMessages.length - 1) {
                      showDataChip = true;
                    } else {
                      showDataChip = _isDifferentDay(
                        timeStr,
                        allMessages[index + 1]['time'],
                      );
                    }

                    if (index > 0) {
                      final prev = allMessages[index - 1];
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
                            ? GestureDetector(
                                onLongPress: () {
                                  final chatController = ref.read(
                                    chatControllerProvider,
                                  );
                                  MessageActionMenu.show(
                                    context: context,
                                    messageData: {
                                      'text': text,
                                      'mediaUrl': mediaUrl,
                                      'mediaType': mediaType,
                                      'fileName': fileName,
                                      'fileSize': fileSize,
                                      'time': timeStr,
                                      'senderId': senderId,
                                      'currentUserId': currentUserId,
                                    },
                                    onReply: () => _setReply(
                                      messageId: messageId,
                                      text: text,
                                      mediaUrl: mediaUrl,
                                      mediaType: mediaType,
                                      senderName: 'You',
                                    ),
                                    onDelete: () =>
                                        chatController.deleteMessage(
                                          chatId: widget.chatId,
                                          messageId: messageId,
                                          mediaUrl: mediaUrl,
                                        ),
                                  );
                                },
                                child: SenderMessage(
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
                                  isLoading:
                                      isLoading ||
                                      (isPending && pendingStatus == 'sending'),
                                ),
                              )
                            : GestureDetector(
                                onLongPress: () {
                                  final chatController = ref.read(
                                    chatControllerProvider,
                                  );
                                  MessageActionMenu.show(
                                    context: context,
                                    messageData: {
                                      'text': text,
                                      'mediaUrl': mediaUrl,
                                      'mediaType': mediaType,
                                      'fileName': fileName,
                                      'fileSize': fileSize,
                                      'time': timeStr,
                                      'senderId': senderId,
                                      'currentUserId': currentUserId,
                                    },
                                    onReply: () => _setReply(
                                      messageId: messageId,
                                      text: text,
                                      mediaUrl: mediaUrl,
                                      mediaType: mediaType,
                                      senderName: widget.receiverDisplayName,
                                    ),
                                    onDelete: () =>
                                        chatController.softDeleteMessage(
                                          chatId: widget.chatId,
                                          messageId: messageId,
                                        ),
                                  );
                                },
                                child: ReceiverMessage(
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
                              ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (replyingToMessageId != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: searchBarColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: whiteColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    color: uiColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Replying to ${replyingToSenderName ?? ''}',
                          style: const TextStyle(
                            color: whiteColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          replyingToText ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: whiteColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearReply,
                    child: Icon(
                      Icons.close,
                      color: whiteColor.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
                ],
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
            isGroupChat: false,
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
