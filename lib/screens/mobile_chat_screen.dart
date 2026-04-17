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
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool showEmoji = false;
  FocusNode focusNode = FocusNode();
  String receiverDisplayName = '';
  String receiverProfilePic = '';

  // FIX: _allMessages is updated safely via post-frame callback, never in build
  List<Map<String, dynamic>> _allMessages = [];

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

  void _doScrollAndHighlight(String messageId, GlobalKey key) {
    if (key.currentContext == null) return;

    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );

    setState(() => _highlightedMessageId = messageId);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  void _scrollToMessage(String? messageId) {
    if (messageId == null) return;

    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      _doScrollAndHighlight(messageId, key!);
      return;
    }

    final index = _allMessages.indexWhere((m) => m['id'] == messageId);
    if (index == -1) return;

    const double estimatedItemHeight = 72.0;
    final totalCount = _allMessages.length;
    final int reverseIndex = totalCount - 1 - index;
    final double estimatedOffset = reverseIndex * estimatedItemHeight;

    final double safeOffset = _scrollController.hasClients
        ? estimatedOffset.clamp(0.0, _scrollController.position.maxScrollExtent)
        : estimatedOffset;

    _scrollController.jumpTo(safeOffset);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final k = _messageKeys[messageId];
      if (k?.currentContext != null) {
        _doScrollAndHighlight(messageId, k!);
      }
    });
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

    final replyId = replyingToMessageId;
    final replyText = replyingToText;
    final replyMedia = replyingToMediaUrl;
    final replyMediaType = replyingToMediaType;
    final replySender = replyingToSenderName;

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
    _clearReply();

    try {
      await ref
          .read(chatControllerProvider)
          .sendMessage(
            chatId: widget.chatId,
            senderId: currentUserId,
            text: messageText,
            receiverId: widget.receiverUid,
            replyToMessageId: replyId,
            replyToText: replyText,
            replyToMediaUrl: replyMedia,
            replyToMediaType: replyMediaType,
            replyToSenderName: replySender,
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

  List<Map<String, dynamic>> _buildMessageList(
    List<Map<String, dynamic>> firebaseMessages,
    List<PendingMessage> pendingMessages,
  ) {
    final allMessages = <Map<String, dynamic>>[];
    allMessages.addAll(firebaseMessages);

    for (final pm in pendingMessages) {
      final alreadyExists = firebaseMessages.any((fbMsg) {
        final fbTime = DateTime.tryParse(fbMsg['time'] as String? ?? '');
        final sameSender = fbMsg['senderId'] == pm.senderId;

        if (pm.fileName != null &&
            pm.fileName!.isNotEmpty &&
            fbMsg['fileName'] == pm.fileName) {
          return sameSender;
        }

        if (pm.localFilePath != null &&
            fbMsg['localFilePath'] == pm.localFilePath) {
          return true;
        }

        final sameText = pm.text.isNotEmpty && fbMsg['text'] == pm.text;
        final withinWindow =
            fbTime != null &&
            pm.sentTime.difference(fbTime).inSeconds.abs() < 10;

        return sameSender && sameText && withinWindow;
      });

      if (!alreadyExists) {
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
        final cmp = timeB.compareTo(timeA);
        if (cmp != 0) return cmp;
        final aPending = (a['isPending'] as bool?) ?? false;
        final bPending = (b['isPending'] as bool?) ?? false;
        if (aPending != bPending) return aPending ? -1 : 1;
        return 0;
      } catch (_) {
        return 0;
      }
    });

    return allMessages;
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
          const SizedBox(width: 16),
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
            icon: const Icon(
              Icons.more_vert_outlined,
              size: 26,
              color: whiteColor,
            ),
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

                if (!snapshot.hasData && pendingMessages.isEmpty) {
                  return const ChatLoader();
                }

                final allMessages = _buildMessageList(
                  firebaseMessages,
                  pendingMessages,
                );

                if (allMessages.isEmpty) {
                  return const ChatLoader();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _allMessages = allMessages;
                });

                return ListView.builder(
                  key: const PageStorageKey('chat_list'),
                  controller: _scrollController,
                  reverse: true,
                  cacheExtent: 1500,
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

                    final replyToText = messageData['replyToText'] as String?;
                    final replyToSenderName =
                        messageData['replyToSenderName'] as String?;
                    final replyToMediaUrl =
                        messageData['replyToMediaUrl'] as String?;
                    final replyToMediaType =
                        messageData['replyToMediaType'] as String?;

                    _messageKeys.putIfAbsent(messageId, () => GlobalKey());

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
                                  key: _messageKeys[messageId],
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
                                  replyToText: replyToText,
                                  replyToSenderName: replyToSenderName,
                                  replyToMediaUrl: replyToMediaUrl,
                                  replyToMediaType: replyToMediaType,
                                  isHighlighted:
                                      _highlightedMessageId == messageId,
                                  onReplyTap: () => _scrollToMessage(
                                    messageData['replyToMessageId'],
                                  ),
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
                                  key: _messageKeys[messageId],
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
                                  replyToText: replyToText,
                                  replyToSenderName: replyToSenderName,
                                  replyToMediaUrl: replyToMediaUrl,
                                  replyToMediaType: replyToMediaType,
                                  senderName: widget.receiverDisplayName,
                                  isHighlighted:
                                      _highlightedMessageId == messageId,
                                  onReplyTap: () => _scrollToMessage(
                                    messageData['replyToMessageId'],
                                  ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.reply, color: uiColor, size: 20),
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
                        const SizedBox(height: 6),
                        if (replyingToMediaType != null &&
                            replyingToMediaType!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              constraints: const BoxConstraints(
                                maxHeight: 50,
                                maxWidth: 50,
                              ),
                              child: replyingToMediaType == 'image'
                                  ? Image.network(
                                      replyingToMediaUrl ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[700],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.image,
                                                    color: whiteColor,
                                                  ),
                                                ),
                                              ),
                                    )
                                  : Container(
                                      color: Colors.grey[700],
                                      child: Center(
                                        child: Icon(
                                          replyingToMediaType == 'video'
                                              ? Icons.videocam
                                              : Icons.attachment,
                                          color: whiteColor,
                                        ),
                                      ),
                                    ),
                            ),
                          )
                        else
                          Text(
                            replyingToText ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: whiteColor.withOpacity(0.7),
                              fontSize: 13,
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
