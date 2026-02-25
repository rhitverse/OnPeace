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

class _UserSearchState extends State<UserSearch> {
  final TextEditingController searchController = TextEditingController();
  String searchText = "";

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
                              SizedBox(height: 4),
                              Text(
                                "@${user["username"] ?? ""}",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 24),
                              GestureDetector(
                                onTap: () {
                                  _navigateToChatScreen(
                                    receiverUid: receiverUid,
                                    displayName: user["displayname"] ?? "",
                                    profilePic: user["profilePic"] ?? "",
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: uiColor,
                                      width: 1.5,
                                    ),
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

  Future<void> _navigateToChatScreen({
    required String receiverUid,
    required String displayName,
    required String profilePic,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login first")));
        return;
      }
      final currentUid = currentUser.uid;
      final uids = [currentUid, receiverUid];
      uids.sort();
      final chatId = "${uids[0]}_${uids[1]}";

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MobileChatScreen(
              chatId: chatId,
              receiverUid: receiverUid,
              receiverDisplayName: displayName,
              receiverProfilePic: profilePic,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
