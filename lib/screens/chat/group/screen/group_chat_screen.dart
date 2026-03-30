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
            .read(chatControllerProvider)
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
    final currentUserName = currentUserData.data()?['displayName'] ?? 'Unknown';
    final currentUserProfilePic = currentUserData.data()?['profilePic'] ?? '';

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
      await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .collection('messages')
          .add({
            'senderId': currentUserId,
            'senderName': currentUserName,
            'senderProfilePic': currentUserProfilePic,
            'text': messageText,
            'isRead': false,
            'time': FieldValue.serverTimestamp(),
          });

      // Remove pending message after successful send
      ref.read(pendingMessagesProvider.notifier).removePending(tempId);
    } catch (e) {
      // Update status to failed
      ref.read(pendingMessagesProvider.notifier).updateStatus(tempId, 'failed');

      if (mounted) {
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

  Future<void> _openGroupInfo() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Group info screen')));
  }

  String _formatTime(dynamic timeObj) {
    try {
      if (timeObj is Timestamp) {
        return DateFormat('hh:mm a').format(timeObj.toDate());
      } else if (timeObj is String) {
        return DateFormat('hh:mm a').format(DateTime.parse(timeObj));
      }
      return '';
    } catch (_) {
      return '';
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('GroupChats')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final firebaseMessages = <Map<String, dynamic>>[];

                if (snapshot.hasData) {
                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    firebaseMessages.add({'id': doc.id, ...data});
                  }
                }

                final pendingMessages = ref.watch(pendingMessagesProvider);

                // Combine Firebase messages and pending messages, filtering out duplicates
                final allMessages = <Map<String, dynamic>>[];

                // Add Firebase messages
                allMessages.addAll(firebaseMessages);

                // Add pending messages, but skip ones that already appear in Firebase
                for (final pm in pendingMessages) {
                  bool isDuplicate = false;

                  // Check if this pending message matches an existing Firebase message
                  try {
                    for (final fbMsg in firebaseMessages) {
                      if (fbMsg['text'] == pm.text &&
                          fbMsg['senderId'] == pm.senderId &&
                          fbMsg['time'] != null) {
                        final fbTime = (fbMsg['time'] is Timestamp)
                            ? (fbMsg['time'] as Timestamp).toDate()
                            : DateTime.tryParse(fbMsg['time'].toString());

                        if (fbTime != null) {
                          final timeDiff = fbTime
                              .difference(pm.sentTime)
                              .inSeconds
                              .abs();
                          if (timeDiff < 2) {
                            isDuplicate = true;
                            break;
                          }
                        }
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
                      'time': pm.sentTime.toIso8601String(),
                      'isPending': true,
                      'pendingStatus': pm.status,
                      'localFilePath': pm.localFilePath,
                    });
                  }
                }

                // Sort by time (latest first)
                allMessages.sort((a, b) {
                  try {
                    final timeA = a['time'] is Timestamp
                        ? (a['time'] as Timestamp).toDate()
                        : DateTime.parse(a['time'] ?? '');
                    final timeB = b['time'] is Timestamp
                        ? (b['time'] as Timestamp).toDate()
                        : DateTime.parse(b['time'] ?? '');
                    return timeB.compareTo(timeA);
                  } catch (_) {
                    return 0;
                  }
                });

                // Show loading state if still loading initial data
                if (!snapshot.hasData && pendingMessages.isEmpty) {
                  return const ChatLoader();
                }

                // Show loading state if no messages yet
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
                    final senderName = messageData['senderName'] ?? '';
                    final senderProfilePic =
                        messageData['senderProfilePic'] ?? '';
                    final text = messageData['text'] ?? '';
                    final timeStr = messageData['time'];
                    final isMe = senderId == currentUserId;

                    final mediaUrl = messageData['mediaUrl'];
                    final mediaType = messageData['mediaType'];
                    final fileName = messageData['fileName'];
                    final fileSize = messageData['fileSize'];
                    final duration = messageData['duration'];

                    String? prevTime = index < allMessages.length - 1
                        ? allMessages[index + 1]['time']
                        : null;

                    DateTime? messageDateTime;
                    try {
                      messageDateTime = timeStr is Timestamp
                          ? timeStr.toDate()
                          : DateTime.parse(timeStr ?? '');
                    } catch (_) {
                      messageDateTime = DateTime.now();
                    }

                    final showDateChip = _isDifferentDay(timeStr, prevTime);

                    return Column(
                      children: [
                        if (showDateChip) DateChip(dateTime: messageDateTime),
                        if (isMe)
                          SenderMessage(
                            text: text,
                            mediaUrl: mediaUrl,
                            mediaType: mediaType,
                            fileName: fileName,
                            fileSize: fileSize,
                            duration: duration ?? 0,
                            time: _formatTime(timeStr),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                mediaUrl: mediaUrl,
                                mediaType: mediaType,
                                fileName: fileName,
                                fileSize: fileSize,
                                duration: duration ?? 0,
                                time: _formatTime(timeStr),
                              ),
                            ],
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
            chatId: widget.groupId,
            receiverUid: widget.groupId,
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
