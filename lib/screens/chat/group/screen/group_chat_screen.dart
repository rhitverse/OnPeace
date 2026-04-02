import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/calls/controller/call_provider.dart';
import 'package:on_peace/screens/chat/group/controller/group_chat_provider.dart';
import 'package:on_peace/screens/chat/provider/pending_messages_provider.dart';
import 'package:on_peace/screens/chat/provider/uploading_messages_provider.dart';
import 'package:on_peace/screens/chat/widget/bottom_chat_field.dart';
import 'package:on_peace/screens/chat/widget/chat_loader.dart';
import 'package:on_peace/screens/chat/widget/date_chip.dart';
import 'package:on_peace/screens/chat/widget/receiver_message.dart';
import 'package:on_peace/screens/chat/widget/sender_message.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final String groupProfilePic;
  final List<String> memberIds;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupProfilePic,
    required this.memberIds,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool showEmoji = false;
  FocusNode focusNode = FocusNode();
  String groupName = '';
  String groupProfilePic = '';

  @override
  void initState() {
    super.initState();
    groupName = widget.groupName;
    groupProfilePic = widget.groupProfilePic;

    focusNode.addListener(() {
      if (focusNode.hasFocus && showEmoji) {
        setState(() => showEmoji = false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        ref
            .read(groupChatControllerProvider)
            .markAsRead(widget.groupId, currentUserId);
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

  void _startGroupVideoCall() {
    ref
        .read(callControllerProvider.notifier)
        .startCall(receiverId: widget.groupId, isVideo: true, context: context);
  }

  void _startGroupVoiceCall() {
    ref
        .read(callControllerProvider.notifier)
        .startCall(
          receiverId: widget.groupId,
          isVideo: false,
          context: context,
        );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final currentUserData = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    final currentUserName = currentUserData.data()?['displayname'] ?? 'Unknown';
    final currentUserProfilePic = currentUserData.data()?['profilePic'] ?? '';

    if (currentUserId == null) return;

    final messageText = _messageController.text.trim();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    if (!mounted) return;

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
      if (!mounted) return;

      await ref
          .read(groupChatControllerProvider)
          .sendMessage(
            groupId: widget.groupId,
            senderId: currentUserId,
            senderName: currentUserName,
            senderProfilePic: currentUserProfilePic,
            text: messageText,
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
                if (mounted) {
                  ref
                      .read(pendingMessagesProvider.notifier)
                      .removePending(tempId);
                  _messageController.text = messageText;
                }
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

  Future<void> _openGroupInfo() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Group info screen')));
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
          onTap: _openGroupInfo,
          child: Row(
            children: [
              GestureDetector(
                onTap: _openGroupInfo,
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: groupProfilePic.isNotEmpty
                      ? NetworkImage(groupProfilePic)
                      : null,
                  child: groupProfilePic.isEmpty
                      ? const Icon(Icons.group, color: whiteColor)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      groupName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: whiteColor,
                      ),
                    ),
                    Text(
                      '${widget.memberIds.length} members',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _startGroupVideoCall,
            child: SvgPicture.asset(
              'assets/svg/videocall.svg',
              width: 27,
              height: 27,
              color: whiteColor,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _startGroupVoiceCall,
            child: SvgPicture.asset(
              'assets/svg/call1.svg',
              width: 27,
              height: 27,
              color: whiteColor,
            ),
          ),
          IconButton(
            onPressed: _openGroupInfo,
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
                  .read(groupChatControllerProvider)
                  .getMessages(widget.groupId),
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

                      if (senderMatch && mediaTypeMatch && fileNameMatch ||
                          timeMatch) {
                        isDuplicate = true;
                        break;
                      }
                    }
                  } catch (_) {}

                  if (!isDuplicate && pm.localFilePath != null) {
                    for (final fbMsg in firebaseMessages) {
                      if (fbMsg['mediaUrl'] == pm.localFilePath) {
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
                      'senderName': 'You',
                      'senderProfilePic': '',
                      'time': pm.sentTime.toIso8601String(),
                      'isPending': true,
                      'pendingStatus': pm.status,
                      'localFilePath': pm.localFilePath,
                      'mediaUrl': pm.mediaUrl,
                      'mediaType': pm.mediaType,
                      'fileName': pm.fileName,
                      'fileSize': pm.fileSize,
                      'duration': pm.duration,
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

                if (allMessages.isEmpty) {}

                return FutureBuilder<Map<String, dynamic>?>(
                  future: ref
                      .read(groupChatControllerProvider)
                      .getGroupInfo(widget.groupId),
                  builder: (context, groupInfoSnapshot) {
                    final groupInfo = groupInfoSnapshot.data;
                    final creatorName = groupInfo?['creatorName'] ?? 'Unknown';
                    final createdAt = groupInfo?['createdAt'];

                    String creationDateStr = '';
                    if (createdAt != null) {
                      try {
                        final createdDateTime = (createdAt as Timestamp)
                            .toDate();
                        creationDateStr = DateFormat(
                          'd MMM yyyy',
                        ).format(createdDateTime);
                      } catch (_) {}
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      itemCount: allMessages.length + 1,
                      itemBuilder: (context, index) {
                        // Show group creation info at the bottom (which appears at top due to reverse=true)
                        if (index == allMessages.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Text(
                                    'Group created by $creatorName',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (creationDateStr.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        creationDateStr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }

                        final messageData = allMessages[index];
                        final senderId = messageData['senderId'] ?? '';
                        final senderName = messageData['senderName'] ?? '';
                        final senderProfilePic =
                            messageData['senderProfilePic'] ?? '';
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
                            timeString = DateFormat(
                              'h:mm a',
                            ).format(msgDateTime);
                          }
                        } catch (_) {}

                        bool showTail = true;
                        bool isGrouped = false;
                        bool showTime = true;
                        bool showSenderInfo = !isMe;

                        bool showDateChip = false;
                        if (index == allMessages.length - 1) {
                          showDateChip = true;
                        } else {
                          showDateChip = _isDifferentDay(
                            timeStr,
                            allMessages[index + 1]['time'],
                          );
                        }

                        if (index > 0) {
                          final prev = allMessages[index - 1];
                          if (prev['senderId'] == senderId) {
                            showTail = false;
                            isGrouped = true;
                            showSenderInfo = false;
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
                            if (showDateChip && msgDateTime != null)
                              DateChip(dateTime: msgDateTime),
                            if (isMe)
                              SenderMessage(
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
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showSenderInfo)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        bottom: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          if (senderProfilePic.isNotEmpty)
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundImage: NetworkImage(
                                                senderProfilePic,
                                              ),
                                            )
                                          else
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.grey[700],
                                              child: Text(
                                                senderName.isNotEmpty
                                                    ? senderName[0]
                                                          .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  color: whiteColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          Text(
                                            senderName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ReceiverMessage(
                                    text: text,
                                    time: showTime ? timeString : '',
                                    showTail: showTail,
                                    isGrouped: isGrouped,
                                    showTime: showTime,
                                    mediaUrl: mediaUrl,
                                    mediaType: mediaType,
                                    fileName: fileName,
                                    fileSize: fileSize,
                                    duration: duration,
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
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
            chatId: widget.groupId,
            receiverUid: widget.groupId,
            isGroupChat: true,
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
