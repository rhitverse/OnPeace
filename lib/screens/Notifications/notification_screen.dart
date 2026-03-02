import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_clone/screens/Notifications/controller/notification_controller.dart';
import 'package:whatsapp_clone/screens/mobile_chat_screen.dart';

class NotificaionScreen extends ConsumerWidget {
  const NotificaionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final notifStream = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          "Notifications",
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => ref
                .read(notificationControllerProvider.notifier)
                .markAllAsRead(),
            child: Text(
              "Mark all read",
              style: TextStyle(color: uiColor, fontSize: 13),
            ),
          ),
        ],
      ),
      body: currentUid == null
          ? const Center(
              child: Text(
                "Not logged in",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : notifStream.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  "Error: $e",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              data: (snapshot) {
                if (snapshot.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -36),
                          child: SvgPicture.asset(
                            "assets/svg/notif.svg",
                            height: 70,
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "No notifications",
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "We'll let you know when there will be something\nto update you.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 17,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.docs;
                final seenAccepted = <String>{};

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final notifId = docs[index].id;
                    final type = data['type'] ?? '';
                    final fromUid = data['fromUid'] ?? '';
                    final fromName = data['fromName'] ?? 'Someone';
                    final chatId = data['chatId'] ?? '';
                    final isRead = data['isRead'] ?? false;

                    DateTime? time;
                    try {
                      time = (data['timestamp'] as Timestamp).toDate();
                    } catch (_) {}
                    final timeStr = time != null ? _formatTime(time) : '';

                    if (type == 'friend_request') {
                      return _FriendRequestTile(
                        notifId: notifId,
                        currentUid: currentUid,
                        fromUid: fromUid,
                        fromName: fromName,
                        chatId: chatId,
                        time: timeStr,
                        isRead: isRead,
                      );
                    }

                    if (type == 'friend_request_accepted') {
                      if (seenAccepted.contains(chatId)) {
                        ref
                            .read(notificationControllerProvider.notifier)
                            .deleteNotification(notifId);
                        return const SizedBox.shrink();
                      }
                      seenAccepted.add(chatId);

                      return _GeneralNotifTile(
                        notifId: notifId,
                        currentUid: currentUid,
                        fromUid: fromUid,
                        displayName: fromName,
                        message: "accepted your friend request.",
                        time: timeStr,
                        isRead: isRead,
                        chatId: chatId,
                      );
                    }

                    return const SizedBox.shrink();
                  },
                );
              },
            ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('d MMM').format(time);
  }
}

class _FriendRequestTile extends ConsumerStatefulWidget {
  final String notifId, currentUid, fromUid, fromName, chatId, time;
  final bool isRead;

  const _FriendRequestTile({
    required this.notifId,
    required this.currentUid,
    required this.fromUid,
    required this.fromName,
    required this.chatId,
    required this.time,
    required this.isRead,
  });

  @override
  ConsumerState<_FriendRequestTile> createState() => _FriendRequestTileState();
}

class _FriendRequestTileState extends ConsumerState<_FriendRequestTile> {
  bool _loading = false;
  bool _accepted = false;
  bool _ignored = false;
  String _profilePic = '';

  @override
  void initState() {
    super.initState();
    _loadSenderPic();
    if (!widget.isRead) {
      ref
          .read(notificationControllerProvider.notifier)
          .markAsRead(widget.notifId);
    }
  }

  Future<void> _loadSenderPic() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.fromUid)
          .get();
      if (mounted) {
        setState(() => _profilePic = doc.data()?['profilePic'] ?? '');
      }
    } catch (_) {}
  }

  Future<void> _accept() async {
    setState(() => _loading = true);
    await ref
        .read(notificationControllerProvider.notifier)
        .acceptFriendRequest(
          currentUid: widget.currentUid,
          fromUid: widget.fromUid,
          chatId: widget.chatId,
          notifId: widget.notifId,
        );
    if (mounted) setState(() => _accepted = true);
  }

  Future<void> _ignore() async {
    await ref
        .read(notificationControllerProvider.notifier)
        .ignoreFriendRequest(
          currentUid: widget.currentUid,
          chatId: widget.chatId,
          notifId: widget.notifId,
        );
    if (mounted) setState(() => _ignored = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_accepted || _ignored) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade800,
            backgroundImage: _profilePic.isNotEmpty
                ? NetworkImage(_profilePic)
                : null,
            child: _profilePic.isEmpty
                ? const Icon(Icons.person, color: whiteColor)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.fromName,
                          style: const TextStyle(
                            color: whiteColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text: " sent you a friend request",
                          style: TextStyle(
                            color: whiteColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: uiColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                            ),
                            onPressed: _accept,
                            child: const Text(
                              "Accept",
                              style: TextStyle(color: whiteColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: searchBarColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                            ),
                            onPressed: _ignore,
                            child: const Text(
                              "Ignore",
                              style: TextStyle(color: whiteColor),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.time,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralNotifTile extends ConsumerStatefulWidget {
  final String notifId, currentUid, fromUid, displayName, message, time, chatId;
  final bool isRead;

  const _GeneralNotifTile({
    required this.notifId,
    required this.currentUid,
    required this.fromUid,
    required this.displayName,
    required this.message,
    required this.time,
    required this.isRead,
    required this.chatId,
  });

  @override
  ConsumerState<_GeneralNotifTile> createState() => _GeneralNotifTileState();
}

class _GeneralNotifTileState extends ConsumerState<_GeneralNotifTile> {
  String _profilePic = '';
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (!widget.isRead) {
      ref
          .read(notificationControllerProvider.notifier)
          .markAsRead(widget.notifId);
    }
  }

  Future<void> _loadUserData() async {
    if (widget.fromUid.isEmpty || widget.fromUid == widget.currentUid) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.fromUid)
          .get();
      if (mounted) {
        setState(() {
          _profilePic = doc.data()?['profilePic'] ?? '';
          _displayName = doc.data()?['displayname'] ?? widget.displayName;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.chatId.isNotEmpty
          ? () async {
              final receiverDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.fromUid)
                  .get();
              final receiverData = receiverDoc.data() ?? {};
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MobileChatScreen(
                      chatId: widget.chatId,
                      receiverUid: widget.fromUid,
                      receiverDisplayName:
                          receiverData['displayname'] ?? _displayName,
                      receiverProfilePic: receiverData['profilePic'] ?? '',
                    ),
                  ),
                );
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey.shade800,
              backgroundImage: _profilePic.isNotEmpty
                  ? NetworkImage(_profilePic)
                  : null,
              child: _profilePic.isEmpty
                  ? const Icon(Icons.person, color: whiteColor)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _displayName.isNotEmpty
                            ? _displayName
                            : widget.displayName,
                        style: const TextStyle(
                          color: whiteColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: " ${widget.message}",
                        style: const TextStyle(
                          color: whiteColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.time,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
