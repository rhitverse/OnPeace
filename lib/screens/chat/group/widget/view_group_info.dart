import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/common/utils/utils.dart';
import 'package:on_peace/screens/chat/group/screen/group_edit_profile.dart';
import 'package:on_peace/screens/chat/group/screen/group_members_screen.dart';
import 'package:on_peace/screens/chat/group/screen/addUserGroup.dart';
import 'package:on_peace/screens/chat/widget/full_screen_image.dart';
import 'package:on_peace/screens/chat/group/widget/group_media.dart';

class ViewGroupInfo extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupProfilePic;
  final List<String> memberIds;

  const ViewGroupInfo({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupProfilePic,
    required this.memberIds,
  });

  @override
  State<ViewGroupInfo> createState() => _ViewGroupInfoState();
}

class _ViewGroupInfoState extends State<ViewGroupInfo> {
  bool _showMoreOptions = false;
  bool _isUpdatingPic = false;
  late List<String> memberList;
  late String groupProfilePic;
  late String groupName;
  String? _creatorId;
  @override
  void initState() {
    super.initState();
    memberList = widget.memberIds;
    groupProfilePic = widget.groupProfilePic;
    groupName = widget.groupName;
    _loadCreatorId();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCreatorId() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .get();
      if (!doc.exists) return;
      final creatorId = doc.data()?['creatorId'] as String?;
      if (!mounted) return;
      setState(() => _creatorId = creatorId);
    } catch (_) {}
  }

  void _viewGroupPhoto() {
    if (groupProfilePic.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImage(imageUrl: groupProfilePic),
      ),
    );
  }

  Future<void> _openGroupEdit(bool isCreator) async {
    if (!isCreator) {
      showSnackBar(context: context, content: 'Only creator can edit');
      return;
    }

    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupEditProfile(
          groupId: widget.groupId,
          groupName: groupName,
          groupProfilePic: groupProfilePic,
        ),
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      groupName = result['groupName'] ?? groupName;
      groupProfilePic = result['groupProfilePic'] ?? groupProfilePic;
    });
  }

  void _openAddMembers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddUserGroup(
          initialSelected: Set.from(memberList),
          onDone: (selected, selectedData) {
            if (!mounted) return;
            showSnackBar(
              context: context,
              content: '${selected.length} selected',
            );
          },
        ),
      ),
    );
  }

  void _openMembersScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupMembersScreen(
          groupId: widget.groupId,
          groupName: groupName,
          memberIds: memberList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = _creatorId != null
        ? currentUserId == _creatorId
        : currentUserId == memberList.first;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,

            color: searchBarColor,
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: whiteColor),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Column(
                  children: [
                    GestureDetector(
                      onTap: _viewGroupPhoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 65,
                            backgroundColor: Colors.grey[700],
                            backgroundImage: groupProfilePic.isNotEmpty
                                ? NetworkImage(groupProfilePic)
                                : null,
                            child: groupProfilePic.isEmpty
                                ? const Icon(
                                    Icons.group,
                                    size: 68,
                                    color: whiteColor,
                                  )
                                : null,
                          ),
                          if (_isUpdatingPic)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: whiteColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _openGroupEdit(isCreator),
                          child: Text(
                            groupName,
                            style: const TextStyle(
                              color: whiteColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isCreator)
                          GestureDetector(
                            onTap: () => _openGroupEdit(isCreator),
                            child: const Icon(
                              Icons.edit,
                              color: whiteColor,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        Icons.person_add,
                        'Add',
                        onTap: _openAddMembers,
                      ),
                      _buildActionButton(Icons.search, 'Search'),
                      _buildActionButton(Icons.notifications_outlined, 'Mute'),
                      _buildActionButton(
                        Icons.more_horiz,
                        'Options',
                        iconSize: 34,
                        onTap: () {
                          setState(() => _showMoreOptions = !_showMoreOptions);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                _buildHomeTab(),
              ],
            ),
          ),
          if (_showMoreOptions)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showMoreOptions = false),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                  child: Container(color: Colors.black.withOpacity(0.25)),
                ),
              ),
            ),
          if (_showMoreOptions)
            Positioned(
              right: 16,
              top: 250,
              child: Container(
                width: 130,
                decoration: BoxDecoration(
                  color: searchBarColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildMoreOption(
                      'Leave',
                      'assets/svg/groupLeave.svg',
                      iconWidth: 22,
                      iconHeight: 22,
                    ),
                    _buildMoreOption(
                      'Hide',
                      'assets/svg/hide.svg',
                      iconWidth: 23,
                      iconHeight: 23,
                    ),
                    _buildMoreOption(
                      'Restrict',
                      'assets/svg/restrictUser.svg',
                      iconWidth: 22,
                      iconHeight: 22,
                    ),
                    _buildMoreOption(
                      'Block',
                      'assets/svg/blockUser.svg',
                      iconWidth: 21,
                      iconHeight: 21,
                    ),
                    _buildMoreOption(
                      'Report',
                      'assets/svg/reportUser.svg',
                      iconWidth: 21,
                      iconHeight: 21,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    double iconSize = 28,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (_showMoreOptions) {
            setState(() => _showMoreOptions = false);
          }
          onTap?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            children: [
              Icon(icon, color: whiteColor, size: iconSize),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: whiteColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreOption(
    String label,
    String iconAsset, {
    double iconWidth = 22,
    double iconHeight = 22,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SvgPicture.asset(
            iconAsset,
            width: iconWidth,
            height: iconHeight,
            colorFilter: ColorFilter.mode(color ?? whiteColor, BlendMode.srcIn),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color ?? whiteColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('assets/svg/sunny.svg', 'Theme', 'Dark'),
          const SizedBox(height: 16),
          _buildInfoRow(
            'assets/svg/link.svg',
            'Invite link',
            'https://chat.link/group',
          ),
          const SizedBox(height: 16),
          _buildMembersRow(),
          const SizedBox(height: 16),
          _buildInfoRow('assets/svg/lock.svg', 'Privacy & safety', ''),
          const SizedBox(height: 20),
          GroupMediaSection(groupId: widget.groupId),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String iconAsset,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SvgPicture.asset(
                  iconAsset,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    whiteColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: whiteColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersRow() {
    return FutureBuilder<List<String>>(
      future: _fetchMemberNames(),
      builder: (context, snapshot) {
        final names = snapshot.data ?? [];
        final subtitle = _formatMemberSubtitle(names);
        return _buildInfoRow(
          'assets/svg/group.svg',
          'Members',
          subtitle,
          onTap: _openMembersScreen,
        );
      },
    );
  }

  String _formatMemberSubtitle(List<String> names) {
    if (names.isEmpty) {
      return '${memberList.length} members';
    }

    final firstTwo = names.take(2).toList();
    final othersCount = memberList.length - firstTwo.length;

    if (othersCount <= 0) {
      return firstTwo.join(', ');
    }

    return '${firstTwo.join(', ')} and $othersCount others';
  }

  Future<List<String>> _fetchMemberNames() async {
    try {
      final fetchIds = memberList.take(3).toList();
      if (fetchIds.isEmpty) return [];

      final futures = fetchIds.map((uid) async {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final data = doc.data();
        final name = data?['displayname'] ?? data?['name'] ?? '';
        return name is String ? name : '';
      });

      final results = await Future.wait(futures);
      return results.where((name) => name.trim().isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }
}
