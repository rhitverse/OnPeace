import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';

class GroupMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> memberIds;

  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.memberIds,
  });

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  late final Future<List<_MemberInfo>> _membersFuture;
  String? _creatorId;
  List<String> _adminIds = [];
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _membersFuture = _fetchMembers();
    _loadCreatorId();
  }

  Future<void> _loadCreatorId() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      final creatorId = data['creatorId'] as String?;
      final adminsRaw = data['admins'];
      final admins = adminsRaw is List
          ? adminsRaw.whereType<String>().toList()
          : <String>[];
      if (creatorId != null && !admins.contains(creatorId)) {
        admins.add(creatorId);
        await FirebaseFirestore.instance
            .collection('GroupChats')
            .doc(widget.groupId)
            .update({'admins': admins});
      }
      if (!mounted) return;
      setState(() {
        _creatorId = creatorId;
        _adminIds = admins;
      });
    } catch (_) {}
  }

  Future<List<_MemberInfo>> _fetchMembers() async {
    if (widget.memberIds.isEmpty) return [];

    try {
      final futures = widget.memberIds.map((uid) async {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        final data = doc.data() ?? {};
        final displayName = data['displayname'] ?? data['name'] ?? '';
        final profilePic = data['profilePic'] ?? '';
        final bio = data['bio'] ?? '';

        return _MemberInfo(
          uid: uid,
          name: displayName is String && displayName.trim().isNotEmpty
              ? displayName
              : 'Unknown',
          profilePic: profilePic is String ? profilePic : '',
          bio: bio is String ? bio : '',
        );
      }).toList();

      return await Future.wait(futures);
    } catch (_) {
      return [];
    }
  }

  Future<void> _handleMemberAction(_MemberInfo member, String action) async {
    if (_currentUid == null) return;
    final isCreator = _currentUid == _creatorId;
    final isAdmin = _adminIds.contains(_currentUid);
    if (!isCreator && !isAdmin) return;

    if (action == 'make_admin') {
      if (member.uid == _creatorId) return;
      if (_adminIds.contains(member.uid)) return;
      try {
        await FirebaseFirestore.instance
            .collection('GroupChats')
            .doc(widget.groupId)
            .update({
              'admins': FieldValue.arrayUnion([member.uid]),
            });
        if (!mounted) return;
        setState(() {
          _adminIds = [..._adminIds, member.uid];
        });
      } catch (_) {}
    }

    if (action == 'remove_admin') {
      if (!isCreator) return;
      if (member.uid == _creatorId) return;
      if (!_adminIds.contains(member.uid)) return;
      try {
        await FirebaseFirestore.instance
            .collection('GroupChats')
            .doc(widget.groupId)
            .update({
              'admins': FieldValue.arrayRemove([member.uid]),
            });
        if (!mounted) return;
        setState(() {
          _adminIds = _adminIds.where((id) => id != member.uid).toList();
        });
      } catch (_) {}
    }
  }

  void _showMemberOptions(BuildContext context, _MemberInfo member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: searchBarColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: whiteColor.withOpacity(0.08), width: 0.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: whiteColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade700,
                    backgroundImage: member.profilePic.isNotEmpty
                        ? NetworkImage(member.profilePic)
                        : null,
                    child: member.profilePic.isEmpty
                        ? Text(
                            member.name.isNotEmpty
                                ? member.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: whiteColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: whiteColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        member.bio.isNotEmpty ? member.bio : 'Hey there!',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(color: whiteColor.withOpacity(0.07), height: 1),
            const SizedBox(height: 8),

            if (_currentUid == _creatorId || !_adminIds.contains(member.uid))
              Row(
                children: [
                  Expanded(
                    child: _SimpleOptionTile(
                      label: 'Remove user',
                      labelColor: Colors.redAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _handleMemberAction(member, 'kick');
                      },
                    ),
                  ),
                ],
              ),
            if (_currentUid == _creatorId &&
                member.uid != _creatorId &&
                _adminIds.contains(member.uid))
              Row(
                children: [
                  Expanded(
                    child: _SimpleOptionTile(
                      label: 'Remove admin',
                      labelColor: Colors.redAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _handleMemberAction(member, 'remove_admin');
                      },
                    ),
                  ),
                ],
              ),
            if (member.uid != _creatorId && !_adminIds.contains(member.uid))
              Row(
                children: [
                  Expanded(
                    child: _SimpleOptionTile(
                      label: 'Make admin',
                      onTap: () {
                        Navigator.pop(context);
                        _handleMemberAction(member, 'make_admin');
                      },
                    ),
                  ),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: _SimpleOptionTile(
                    label: 'Restrict',
                    labelColor: Colors.redAccent,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _SimpleOptionTile(
                    label: 'Block',
                    labelColor: whiteColor,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _SimpleOptionTile(
                    label: 'Report chat',
                    labelColor: Colors.redAccent,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: whiteColor),
        ),
        title: Text(
          widget.groupName.isNotEmpty ? widget.groupName : 'Members',
          style: const TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              '${widget.memberIds.length} members',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Divider(color: whiteColor.withOpacity(0.07), height: 1),
          Expanded(
            child: FutureBuilder<List<_MemberInfo>>(
              future: _membersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: whiteColor),
                  );
                }

                final members = snapshot.data ?? [];
                if (members.isEmpty) {
                  return const Center(
                    child: Text(
                      'No members found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final sortedMembers = List<_MemberInfo>.from(members);
                sortedMembers.sort((a, b) {
                  if (a.uid == _creatorId) return -1;
                  if (b.uid == _creatorId) return 1;
                  final aIsAdmin = _adminIds.contains(a.uid);
                  final bIsAdmin = _adminIds.contains(b.uid);
                  if (aIsAdmin && !bIsAdmin) return -1;
                  if (!aIsAdmin && bIsAdmin) return 1;
                  return 0;
                });

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: sortedMembers.length,
                  separatorBuilder: (_, __) => Divider(
                    color: whiteColor.withOpacity(0.05),
                    height: 1,
                    indent: 76,
                  ),
                  itemBuilder: (context, index) {
                    final member = sortedMembers[index];
                    final isCreator = member.uid == _creatorId;
                    final isAdmin = _adminIds.contains(member.uid);
                    final isOperator =
                        _currentUid == _creatorId ||
                        _adminIds.contains(_currentUid);
                    final canManage =
                        isOperator &&
                        !isCreator &&
                        (_currentUid == _creatorId || !isAdmin);

                    return Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 29,
                                  backgroundColor: Colors.grey.shade700,
                                  backgroundImage: member.profilePic.isNotEmpty
                                      ? NetworkImage(member.profilePic)
                                      : null,
                                  child: member.profilePic.isEmpty
                                      ? Text(
                                          member.name.isNotEmpty
                                              ? member.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: whiteColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.name,
                                        style: const TextStyle(
                                          color: whiteColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        member.bio.isNotEmpty
                                            ? member.bio
                                            : 'Hey there!',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (isCreator || isAdmin)
                          GestureDetector(
                            onTap:
                                (isAdmin || _currentUid == _creatorId) &&
                                    member.uid != _currentUid
                                ? () => _showMemberOptions(context, member)
                                : null,
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: whiteColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isCreator ? 'Creator' : 'Admin',
                                style: const TextStyle(
                                  color: whiteColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else if (canManage)
                          GestureDetector(
                            onTap: () => _showMemberOptions(context, member),
                            behavior: HitTestBehavior.opaque,
                            child: const SizedBox(
                              width: 48,
                              height: 56,
                              child: Icon(
                                Icons.more_vert,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
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

class _SimpleOptionTile extends StatelessWidget {
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  const _SimpleOptionTile({
    required this.label,
    required this.onTap,
    this.labelColor = whiteColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: whiteColor.withOpacity(0.04),
      highlightColor: whiteColor.withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MemberInfo {
  final String uid;
  final String name;
  final String profilePic;
  final String bio;

  const _MemberInfo({
    required this.uid,
    required this.name,
    required this.profilePic,
    required this.bio,
  });
}
