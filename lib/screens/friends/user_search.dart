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
          onPressed: () {
            Navigator.pop(context);
          },
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

                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade800,
                                backgroundImage:
                                    user["profilePic"] != null &&
                                        user["profilePic"] != ""
                                    ? NetworkImage(user["profilePic"])
                                    : null,
                                child:
                                    user["profilePic"] == null ||
                                        user["profilePic"] == ""
                                    ? Icon(
                                        Icons.person,
                                        color: whiteColor,
                                        size: 50,
                                      )
                                    : null,
                              ),
                              SizedBox(height: 16),
                              Text(
                                user["displayname"] ?? "",
                                style: TextStyle(
                                  color: whiteColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 24),
                              _buildActionButton(
                                receiverUid: receiverUid,
                                displayName: user["displayname"] ?? "",
                                profilePic: user["profilePic"] ?? "",
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String receiverUid,
    required String displayName,
    required String profilePic,
  }) {
    switch (_buttonState) {
      case AddButtonState.idle:
        return GestureDetector(
          onTap: () => _onAddPressed(
            receiverUid: receiverUid,
            displayName: displayName,
            profilePic: profilePic,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: uiColor, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "Add",
              style: TextStyle(
                color: uiColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      case AddButtonState.loading:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: uiColor, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: uiColor, strokeWidth: 2),
          ),
        );
      case AddButtonState.sent:
        return Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              decoration: BoxDecoration(
                color: uiColor.withOpacity(0.15),
                border: Border.all(color: uiColor, width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: uiColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Request Sent",
                    style: TextStyle(
                      color: uiColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: () => _navigateToChatScreen(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                decoration: BoxDecoration(
                  color: uiColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: backgroundColor,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Open Chat",
                      style: TextStyle(
                        color: backgroundColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case AddButtonState.chat:
        return GestureDetector(
          onTap: () => _navigateToChatScreen(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            decoration: BoxDecoration(
              color: uiColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: backgroundColor,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  "Open Chat",
                  style: TextStyle(
                    color: backgroundColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
    }
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
      final uids = [currentUid, receiverUid];
      uids.sort();
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

      if (mounted) {
        setState(() => _buttonState = AddButtonState.sent);
      }
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
