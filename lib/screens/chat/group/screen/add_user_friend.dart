import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:on_peace/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddUserFriend extends StatefulWidget {
  const AddUserFriend({super.key});

  @override
  State<AddUserFriend> createState() => _AddUserFriendState();
}

class _AddUserFriendState extends State<AddUserFriend> {
  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';
  bool _showClear = false;
  Set<String> selectedFriends = {};

  @override
  void initState() {
    searchController.addListener(() {
      setState(() {
        _showClear = searchController.text.isNotEmpty;
      });
    });
    super.initState();
  }

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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text(
          "Choose friends",
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: selectedFriends.isEmpty
                ? null
                : () {
                    print('Selected: $selectedFriends');
                  },
            child: Text(
              'Next',
              style: TextStyle(
                color: selectedFriends.isEmpty ? Colors.grey : whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
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
          : Column(
              children: [
                Container(
                  height: 42,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: searchBarColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: searchController,
                    cursorColor: uiColor,
                    style: const TextStyle(color: whiteColor),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 15, left: 17),
                        child: SvgPicture.asset(
                          "assets/svg/search_icon.svg",
                          width: 20,
                        ),
                      ),
                      hintText: "Search by name",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      suffixIcon: _showClear
                          ? IconButton(
                              icon: const Icon(Icons.close, color: whiteColor),
                              onPressed: () {
                                setState(() {
                                  searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
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
                          if (friendUid.isNotEmpty) {
                            friends.add({'friendUid': friendUid});
                          }
                        }
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (friends.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                "assets/svg/friendempty.svg",
                                height: 180,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No friends yet!",
                                style: TextStyle(
                                  color: whiteColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          return _FriendCheckboxTile(
                            friendUid: friends[index]['friendUid'],
                            isSelected: selectedFriends.contains(
                              friends[index]['friendUid'],
                            ),
                            searchQuery: _searchQuery,
                            onSelected: (uid, isSelected) {
                              setState(() {
                                if (isSelected) {
                                  selectedFriends.add(uid);
                                } else {
                                  selectedFriends.remove(uid);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _FriendCheckboxTile extends StatefulWidget {
  final String friendUid;
  final bool isSelected;
  final String searchQuery;
  final Function(String, bool) onSelected;

  const _FriendCheckboxTile({
    required this.friendUid,
    required this.isSelected,
    required this.searchQuery,
    required this.onSelected,
    super.key,
  });

  @override
  State<_FriendCheckboxTile> createState() => _FriendCheckboxTileState();
}

class _FriendCheckboxTileState extends State<_FriendCheckboxTile> {
  late final Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.friendUid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final displayName =
            data['displayname'] ?? data['username'] ?? 'Unknown';
        final profilePic = data['profilePic'] ?? '';

        if (widget.searchQuery.isNotEmpty &&
            !displayName.toLowerCase().contains(widget.searchQuery)) {
          return const SizedBox.shrink();
        }

        return ListTile(
          onTap: () => widget.onSelected(widget.friendUid, !widget.isSelected),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          leading: CircleAvatar(
            radius: 26,
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
              fontSize: 16,
            ),
          ),
          trailing: GestureDetector(
            onTap: () =>
                widget.onSelected(widget.friendUid, !widget.isSelected),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isSelected ? uiColor : Colors.transparent,
                border: Border.all(
                  color: widget.isSelected ? uiColor : Colors.grey,
                  width: 1.3,
                ),
              ),
              child: widget.isSelected
                  ? const Icon(Icons.check, color: whiteColor, size: 16)
                  : null,
            ),
          ),
        );
      },
    );
  }
}
