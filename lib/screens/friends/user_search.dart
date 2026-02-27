import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp_clone/screens/mobile_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSearch extends StatefulWidget {
  const UserSearch({super.key});

  @override
  State<UserSearch> createState() => _UserSearchState();
}

enum AddButtonState { idle, loading, sent, chat }

class _UserSearchState extends State<UserSearch> {
  final TextEditingController searchController = TextEditingController();
  String searchText = "";
  AddButtonState _buttonState = AddButtonState.idle;

  String? _foundReceiverUid;
  String? _foundDisplayName;
  String? _foundProfilePic;
  String? _foundChatId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: whiteColor),
        ),
        title: Text("Add friends", style: TextStyle(color: whiteColor)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 1, 12, 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: searchBarColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: searchController,
                style: TextStyle(color: whiteColor),
                cursorColor: uiColor,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(right: 15, left: 17),
                    child: SvgPicture.asset(
                      "assets/svg/search_icon.svg",
                      width: 20,
                    ),
                  ),
                  hintText: "Search by username...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 9.6),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value.trim().toLowerCase();
                    _buttonState = AddButtonState.idle;
                    _foundReceiverUid = null;
                  });
                },
              ),
            ),
          ),

          Expanded(
            child: searchText.length < 4
                ? Center(
                    child: Text(
                      "Search users",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .where("username", isEqualTo: searchText)
                        .where("allowAddById", isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final users = snapshot.data!.docs;

                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            "User not found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      final user = users.first.data() as Map<String, dynamic>;
                      final receiverUid = users.first.id;

                      return Column(
                        children: [
                          SizedBox(height: 10),
                          _buildUserTile(user: user, receiverUid: receiverUid),

                          if (_buttonState == AddButtonState.sent)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: uiColor,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Friend request sent",
                                    style: TextStyle(
                                      color: uiColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile({
    required Map<String, dynamic> user,
    required String receiverUid,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: userSearchContainerColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                user["profilePic"] != null && user["profilePic"] != ""
                ? NetworkImage(user["profilePic"])
                : null,
            child: user["profilePic"] == null || user["profilePic"] == ""
                ? Icon(Icons.person, color: whiteColor, size: 24)
                : null,
          ),
          SizedBox(width: 12),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                user["displayname"] ?? "",
                style: TextStyle(
                  color: whiteColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          _buildIconButton(
            receiverUid: receiverUid,
            displayName: user["displayname"] ?? "",
            profilePic: user["profilePic"] ?? "",
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required String receiverUid,
    required String displayName,
    required String profilePic,
  }) {
    if (_buttonState == AddButtonState.loading) {
      return SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(color: uiColor, strokeWidth: 2),
      );
    }

    if (_buttonState == AddButtonState.sent ||
        _buttonState == AddButtonState.chat) {
      return GestureDetector(
        onTap: _navigateToChatScreen,
        child: SvgPicture.asset(
          "assets/svg/chat1.svg",
          width: 26,
          height: 26,
          colorFilter: ColorFilter.mode(whiteColor, BlendMode.srcIn),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onAddPressed(
        receiverUid: receiverUid,
        displayName: displayName,
        profilePic: profilePic,
      ),
      child: SvgPicture.asset(
        "assets/svg/addfriends.svg",
        width: 28,
        height: 28,
        colorFilter: ColorFilter.mode(whiteColor, BlendMode.srcIn),
      ),
    );
  }

  Future<void> _onAddPressed({
    required String receiverUid,
    required String displayName,
    required String profilePic,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    setState(() => _buttonState = AddButtonState.loading);

    try {
      final currentUid = currentUser.uid;
      final uids = [currentUid, receiverUid]..sort();
      final chatId = "${uids[0]}_${uids[1]}";

      final chatRef = FirebaseFirestore.instance
          .collection("Chats")
          .doc(chatId);
      final chatSnap = await chatRef.get();
      if (!chatSnap.exists) {
        await chatRef.set({
          "participants": [currentUid, receiverUid],
          "createdAt": FieldValue.serverTimestamp(),
          "lastMessage": "",
          "lastMessageTime": FieldValue.serverTimestamp(),
          "lastMessageSenderId": "",
          "unreadCount_$currentUid": 0,
          "unreadCount_$receiverUid": 0,
        });
      }

      final senderDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUid)
          .get();
      final senderName = senderDoc.data()?["displayname"] ?? "Someone";

      await FirebaseFirestore.instance
          .collection("users")
          .doc(receiverUid)
          .collection("notifications")
          .add({
            "type": "friend_request",
            "fromUid": currentUid,
            "fromName": senderName,
            "chatId": chatId,
            "message": "$senderName",
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
          });

      _foundReceiverUid = receiverUid;
      _foundDisplayName = displayName;
      _foundProfilePic = profilePic;
      _foundChatId = chatId;

      if (mounted) setState(() => _buttonState = AddButtonState.sent);
    } catch (e) {
      if (mounted) {
        setState(() => _buttonState = AddButtonState.idle);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  void _navigateToChatScreen() {
    if (_foundChatId == null || _foundReceiverUid == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileChatScreen(
          chatId: _foundChatId!,
          receiverUid: _foundReceiverUid!,
          receiverDisplayName: _foundDisplayName ?? "",
          receiverProfilePic: _foundProfilePic ?? "",
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
