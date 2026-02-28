import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_clone/screens/mobile_chat_screen.dart';

class NotificaionScreen extends StatelessWidget {
  const NotificaionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          "Notifications",
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: currentUid == null
          ? const Center(
              child: Text(
                "Not logged in",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          color: Colors.grey,
                          size: 52,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "No notifications yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
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

class _FriendRequestTile extends StatefulWidget {
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
  State<_FriendRequestTile> createState() => _FriendRequestTileState();
}

class _FriendRequestTileState extends State<_FriendRequestTile> {
  bool _loading = false;
  bool _accepted = false;
  bool _ignored = false;
  String _profilePic = '';

  @override
  void initState() {
    super.initState();
    _loadSenderPic();
    if (!widget.isRead) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUid)
          .collection('notifications')
          .doc(widget.notifId)
          .update({'isRead': true});
    }
  }

  Future<void> _loadSenderPic() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.fromUid)
          .get();
      if (mounted)
        setState(() => _profilePic = doc.data()?['profilePic'] ?? '');
    } catch (_) {}
  }

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      final chatRef = FirebaseFirestore.instance
          .collection('Chats')
          .doc(widget.chatId);
      final chatSnap = await chatRef.get();
      if (!chatSnap.exists) {
        await chatRef.set({
          'participants': [widget.currentUid, widget.fromUid],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
          'unreadCount_${widget.currentUid}': 0,
          'unreadCount_${widget.fromUid}': 0,
        });
      }

      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUid)
          .get();
      final myName = myDoc.data()?['displayname'] ?? 'Someone';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.fromUid)
          .collection('notifications')
          .add({
            'type': 'friend_request_accepted',
            'fromUid': widget.currentUid,
            'fromName': myName,
            'chatId': widget.chatId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUid)
          .collection('notifications')
          .doc(widget.notifId)
          .delete();

      if (mounted) setState(() => _accepted = true);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ignore() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUid)
        .collection('notifications')
        .doc(widget.notifId)
        .delete();
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
                  padding: const EdgeInsets.only(top: 4),
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
            padding: const EdgeInsets.only(top: 4),
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

class _GeneralNotifTile extends StatefulWidget {
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
  State<_GeneralNotifTile> createState() => _GeneralNotifTileState();
}

class _GeneralNotifTileState extends State<_GeneralNotifTile> {
  String _profilePic = '';

  @override
  void initState() {
    super.initState();
    _loadPic();
    if (!widget.isRead) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUid)
          .collection('notifications')
          .doc(widget.notifId)
          .update({'isRead': true});
    }
  }

  Future<void> _loadPic() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.fromUid)
          .get();
      if (mounted)
        setState(() => _profilePic = doc.data()?['profilePic'] ?? '');
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
                          receiverData['displayname'] ?? widget.displayName,
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: widget.displayName,
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
              padding: const EdgeInsets.only(top: 4),
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
