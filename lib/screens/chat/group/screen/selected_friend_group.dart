import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:on_peace/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SelectedFriendGroup extends StatefulWidget {
  final Set<String> initialSelected;
  final Map<String, Map<String, dynamic>> initialSelectedData;
  final Function(Set<String>, Map<String, Map<String, dynamic>>) onDone;

  const SelectedFriendGroup({
    super.key,
    this.initialSelected = const {},
    this.initialSelectedData = const {},
    required this.onDone,
  });

  @override
  State<SelectedFriendGroup> createState() => _SelectedFriendGroupState();
}

class _SelectedFriendGroupState extends State<SelectedFriendGroup> {
  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';
  bool _showClear = false;
  late Set<String> selectedFriends;
  late Map<String, Map<String, dynamic>> selectedFriendsData;

  @override
  void initState() {
    super.initState();
    selectedFriends = Set.from(widget.initialSelected);
    selectedFriendsData = Map.from(widget.initialSelectedData);
    searchController.addListener(() {
      setState(() {
        _showClear = searchController.text.isNotEmpty;
      });
    });
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
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: whiteColor),
        ),
        title: Text(
          selectedFriends.isEmpty
              ? 'Add people'
              : '${selectedFriends.length} selected',
          style: const TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: selectedFriends.isEmpty
                ? null
                : () {
                    widget.onDone(selectedFriends, selectedFriendsData);
                    Navigator.pop(context);
                  },
            child: Text(
              'Invite',
              style: TextStyle(
                color: selectedFriends.isEmpty ? Colors.grey : whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 17,
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
                // Search bar
                Container(
                  height: 42,
                  margin: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 2,
                    bottom: 8,
                  ),
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

                // Friends list
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
                          final uid = friends[index]['friendUid'];
                          return _FriendTile(
                            key: ValueKey(uid),
                            friendUid: uid,
                            isSelected: selectedFriends.contains(uid),
                            searchQuery: _searchQuery,
                            onSelected: (uid, isSelected, userData) {
                              setState(() {
                                if (isSelected) {
                                  selectedFriends.add(uid);
                                  selectedFriendsData[uid] = userData;
                                } else {
                                  selectedFriends.remove(uid);
                                  selectedFriendsData.remove(uid);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),

                // Bottom selected avatars row
                if (selectedFriends.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: const Border(
                        top: BorderSide(color: Colors.white12, width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: SizedBox(
                      height: 75,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedFriends.length,
                        itemBuilder: (context, index) {
                          final uid = selectedFriends.elementAt(index);
                          final data = selectedFriendsData[uid] ?? {};
                          final name = data['displayname'] ?? 'Unknown';
                          final profilePic = data['profilePic'] ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.grey.shade700,
                                      backgroundImage: profilePic.isNotEmpty
                                          ? NetworkImage(profilePic)
                                          : null,
                                      child: profilePic.isEmpty
                                          ? Text(
                                              name.isNotEmpty
                                                  ? name[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: whiteColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedFriends.remove(uid);
                                            selectedFriendsData.remove(uid);
                                          });
                                        },
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            color: Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 10,
                                            color: whiteColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _FriendTile extends StatefulWidget {
  final String friendUid;
  final bool isSelected;
  final String searchQuery;
  final Function(String uid, bool isSelected, Map<String, dynamic> userData)
  onSelected;

  const _FriendTile({
    required this.friendUid,
    required this.isSelected,
    required this.searchQuery,
    required this.onSelected,
    super.key,
  });

  @override
  State<_FriendTile> createState() => _FriendTileState();
}

class _FriendTileState extends State<_FriendTile> {
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
        final displayName = data['displayname'] ?? 'Unknown';
        final profilePic = data['profilePic'] ?? '';

        if (widget.searchQuery.isNotEmpty &&
            !displayName.toLowerCase().contains(widget.searchQuery)) {
          return const SizedBox.shrink();
        }

        return ListTile(
          onTap: () =>
              widget.onSelected(widget.friendUid, !widget.isSelected, data),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
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
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isSelected ? uiColor : Colors.transparent,
              border: Border.all(
                color: widget.isSelected ? uiColor : Colors.grey,
                width: 1.5,
              ),
            ),
            child: widget.isSelected
                ? const Icon(Icons.check, color: whiteColor, size: 16)
                : null,
          ),
        );
      },
    );
  }
}
