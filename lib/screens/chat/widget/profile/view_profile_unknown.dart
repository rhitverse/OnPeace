import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:on_peace/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

final receiverProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.data();
    });

String _formatDob(String raw, bool showYear) {
  try {
    final dt = DateTime.parse(raw);
    return showYear
        ? DateFormat('dd MMMM yyyy').format(dt)
        : DateFormat('dd MMMM').format(dt);
  } catch (_) {
    return raw;
  }
}

enum _AddState { idle, loading, sent }

class ViewProfileUnknown extends ConsumerStatefulWidget {
  final String receiverUid;
  final String receiverDisplayName;
  final String receiverProfilePic;

  const ViewProfileUnknown({
    super.key,
    required this.receiverUid,
    required this.receiverDisplayName,
    required this.receiverProfilePic,
  });

  @override
  ConsumerState<ViewProfileUnknown> createState() => _ViewProfileUnknownState();
}

class _ViewProfileUnknownState extends ConsumerState<ViewProfileUnknown> {
  _AddState _addState = _AddState.idle;
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _sendFriendRequest() async {
    if (_currentUid.isEmpty) return;
    setState(() => _addState = _AddState.loading);

    try {
      final uids = [_currentUid, widget.receiverUid]..sort();
      final chatId = "${uids[0]}_${uids[1]}";

      final chatRef = FirebaseFirestore.instance
          .collection("Chats")
          .doc(chatId);
      final chatSnap = await chatRef.get();

      if (!chatSnap.exists) {
        await chatRef.set({
          "participants": [_currentUid, widget.receiverUid],
          "createdAt": FieldValue.serverTimestamp(),
          "lastMessage": "",
          "lastMessageTime": FieldValue.serverTimestamp(),
          "lastMessageSenderId": "",
          "unreadCount_$_currentUid": 0,
          "unreadCount_${widget.receiverUid}": 0,
          "status": "pending",
        });
      }

      final senderDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(_currentUid)
          .get();
      final senderName = senderDoc.data()?["displayname"] ?? "Unknown";

      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.receiverUid)
          .collection("notifications")
          .add({
            "type": "friend_request",
            "fromUid": _currentUid,
            "fromName": senderName,
            "chatId": chatId,
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
          });
      if (mounted) setState(() => _addState = _AddState.sent);
    } catch (e) {
      if (mounted) {
        setState(() => _addState = _AddState.idle);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  Future<void> _checkIfAlreadySent() async {
    if (_currentUid.isEmpty) return;
    final uids = [_currentUid, widget.receiverUid]..sort();
    final chatId = "${uids[0]}_${uids[1]}";
    final chatSnap = await FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatId)
        .get();
    if (!mounted) return;
    if (chatSnap.exists && chatSnap.data()?['status'] == 'pending') {
      setState(() => _addState = _AddState.sent);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkIfAlreadySent();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(receiverProfileProvider(widget.receiverUid));
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.188,
            pinned: true,
            backgroundColor: backgroundColor,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: whiteColor),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: whiteColor),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(height: 180, color: const Color(0xFFD4E8C2)),
                  Positioned(
                    bottom: 0,
                    left: 20,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundImage: widget.receiverProfilePic.isNotEmpty
                          ? NetworkImage(widget.receiverProfilePic)
                          : null,
                      backgroundColor: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: profileAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (data) {
                final bio = (data?['bio'] as String?)?.trim() ?? '';
                final rawDob = (data?['birthday'] as String?)?.trim() ?? '';
                final showBirthday = data?['showBirthday'] ?? true;
                final showBirthYear = data?['showBirthYear'] ?? true;
                final shouldShowDob = showBirthday && rawDob.isNotEmpty;
                final dobText = shouldShowDob
                    ? _formatDob(rawDob, showBirthYear)
                    : '';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.receiverDisplayName,
                        style: const TextStyle(
                          color: whiteColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (shouldShowDob)
                        Row(
                          children: [
                            const Icon(
                              Icons.cake_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dobText,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: _addState == _AddState.idle
                                    ? _sendFriendRequest
                                    : null,
                                icon: _addState == _AddState.loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: whiteColor,
                                        ),
                                      )
                                    : Icon(
                                        _addState == _AddState.sent
                                            ? Icons.check_circle_outline
                                            : Icons.person_add_alt_1,
                                        size: 20,
                                        color: whiteColor,
                                      ),
                                label: Text(
                                  _addState == _AddState.sent
                                      ? 'Request Sent'
                                      : 'Add Friend',
                                  style: const TextStyle(
                                    color: whiteColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _addState == _AddState.sent
                                      ? Colors.grey[700]
                                      : uiColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 19),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: SvgPicture.asset(
                              "assets/svg/chat1.svg",
                              colorFilter: const ColorFilter.mode(
                                whiteColor,
                                BlendMode.srcIn,
                              ),
                              width: 32,
                              height: 32,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),

                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: attacment,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bio',
                                style: TextStyle(
                                  color: whiteColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                bio,
                                style: const TextStyle(
                                  color: whiteColor,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
