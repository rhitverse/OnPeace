import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:on_peace/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddUserGroup extends StatefulWidget {
  final Set<String> initialSelected;
  final Map<String, Map<String, dynamic>> initialSelectedData;
  final Function(Set<String>, Map<String, Map<String, dynamic>>) onDone;

  const AddUserGroup({
    super.key,
    this.initialSelected = const {},
    this.initialSelectedData = const {},
    required this.onDone,
  });

  @override
  State<AddUserGroup> createState() => _AddUserGroupState();
}

class _AddUserGroupState extends State<AddUserGroup> {
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
    _preloadSelectedData();
    searchController.addListener(() {
      setState(() {
        _showClear = searchController.text.isNotEmpty;
      });
    });
  }

  Future<void> _preloadSelectedData() async {
    if (selectedFriends.isEmpty) return;

    final missing = <String>[];
    for (final uid in selectedFriends) {
      final data = selectedFriendsData[uid];
      if (data == null || data.isEmpty) {
        missing.add(uid);
      }
    }

    if (missing.isEmpty) return;

    final fetched = <String, Map<String, dynamic>>{};
    try {
      for (final uid in missing) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists) {
          fetched[uid] = doc.data() ?? {};
        }
      }
    } catch (_) {}

    if (!mounted || fetched.isEmpty) return;
    setState(() {
      selectedFriendsData.addAll(fetched);
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
          'Add people',
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
              'Add',
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

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Friends')
                        .where('uid', isEqualTo: currentUid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      List<String> alreadyAdded = [];
                      List<String> recentFriends = [];

                      if (snapshot.hasData) {
                        for (final doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final friendUid = data['friendUid'] ?? '';
                          if (friendUid.isNotEmpty && friendUid != currentUid) {
                            if (widget.initialSelected.contains(friendUid)) {
                              alreadyAdded.add(friendUid);
                            } else {
                              recentFriends.add(friendUid);
                            }
                          }
                        }
                      }

                      if (alreadyAdded.isEmpty && recentFriends.isEmpty) {
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

                      return ListView(
                        children: [
                          if (alreadyAdded.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              child: Text(
                                "Group members",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            ...alreadyAdded.map(
                              (uid) => _FriendTile(
                                key: ValueKey('added_$uid'),
                                friendUid: uid,
                                currentUid: currentUid,
                                isSelected: selectedFriends.contains(uid),
                                showCheckbox: false,
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
                              ),
                            ),
                          ],

                          if (recentFriends.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              child: Text(
                                "Friends",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            ...recentFriends.map(
                              (uid) => _FriendTile(
                                key: ValueKey('recent_$uid'),
                                friendUid: uid,
                                currentUid: currentUid,
                                isSelected: selectedFriends.contains(uid),
                                showCheckbox: true,
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
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox.shrink(),
              ],
            ),
    );
  }
}

class _FriendTile extends StatefulWidget {
  final String friendUid;
  final String? currentUid;
  final bool isSelected;
  final bool showCheckbox;
  final String searchQuery;
  final Function(String uid, bool isSelected, Map<String, dynamic> userData)
  onSelected;

  const _FriendTile({
    required this.friendUid,
    this.currentUid,
    required this.isSelected,
    required this.showCheckbox,
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
    if (widget.currentUid != null && widget.friendUid == widget.currentUid) {
      return const SizedBox.shrink();
    }

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
          onTap: () {
            if (!widget.showCheckbox) return;
            widget.onSelected(widget.friendUid, !widget.isSelected, data);
          },
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
          trailing: widget.showCheckbox
              ? AnimatedContainer(
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
                )
              : null,
        );
      },
    );
  }
}
