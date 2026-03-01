import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/friends/user_search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_clone/screens/mobile_chat_screen.dart';

class FriendsNewchat extends StatefulWidget {
  const FriendsNewchat({super.key});

  @override
  State<FriendsNewchat> createState() => _FriendsNewchatState();
}

class _FriendsNewchatState extends State<FriendsNewchat> {
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: searchBarColor, height: 1),
        ),
        leading: isSearching
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios),
              ),
        title: isSearching
            ? Container(
                height: 45,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: searchBarColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: searchController,
                  cursorColor: uiColor,
                  autofocus: true,
                  style: const TextStyle(color: whiteColor),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Search",
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: whiteColor),
                      onPressed: () {
                        setState(() {
                          searchController.clear();
                          _searchQuery = '';
                          isSearching = false;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              )
            : const Text(
                "New Chat",
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: isSearching
            ? []
            : [
                IconButton(
                  icon: const Icon(Icons.search, color: whiteColor, size: 27),
                  onPressed: () => setState(() => isSearching = true),
                ),
                const Icon(Icons.more_vert, color: whiteColor, size: 27),
                const SizedBox(width: 10),
              ],
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
                  .collection('Friends')
                  .where('uid', isEqualTo: currentUid)
                  .snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> friends = [];
                if (snapshot.hasData) {
                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final friendUid = data['friendUid'] ?? '';
                    final chatId = data['chatId'] ?? '';
                    if (friendUid.isNotEmpty && chatId.isNotEmpty) {
                      friends.add({'chatId': chatId, 'receiverUid': friendUid});
                    }
                  }
                }

                return ListView(
                  children: [
                    ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserSearch()),
                      ),
                      leading: SvgPicture.asset(
                        "assets/svg/addfriends.svg",
                        width: 30,
                        height: 30,
                        color: whiteColor,
                      ),
                      title: const Text(
                        "Add Friends",
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      onTap: () {},
                      leading: SvgPicture.asset(
                        "assets/svg/addgroup.svg",
                        width: 34,
                        height: 34,
                        color: whiteColor,
                      ),
                      title: const Text(
                        "New Group",
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (friends.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              color: Colors.grey,
                              size: 48,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "No friends yet",
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Add friends to start chatting",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...friends.map(
                        (friend) => _FriendTile(
                          chatId: friend['chatId'],
                          receiverUid: friend['receiverUid'],
                          searchQuery: _searchQuery,
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final String chatId;
  final String receiverUid;
  final String searchQuery;

  const _FriendTile({
    required this.chatId,
    required this.receiverUid,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(receiverUid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final displayName =
            data['displayname'] ?? data['username'] ?? 'Unknown';
        final bio = data['bio'] ?? '';
        final profilePic = data['profilePic'] ?? '';

        if (searchQuery.isNotEmpty &&
            !displayName.toLowerCase().contains(searchQuery)) {
          return const SizedBox.shrink();
        }

        return ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MobileChatScreen(
                chatId: chatId,
                receiverUid: receiverUid,
                receiverDisplayName: displayName,
                receiverProfilePic: profilePic,
              ),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade700,
            backgroundImage: profilePic.isNotEmpty
                ? NetworkImage(profilePic)
                : null,
            child: profilePic.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          title: Text(
            displayName,
            style: const TextStyle(
              color: whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            bio.isNotEmpty ? bio : "Hey there!",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
