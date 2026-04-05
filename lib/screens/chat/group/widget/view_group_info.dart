import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/common/utils/common_cloudinary_repository.dart';
import 'package:on_peace/common/utils/utils.dart';
import 'package:on_peace/screens/chat/widget/full_screen_image.dart';
import 'package:on_peace/screens/chat/group/widget/group_media.dart';
import 'package:on_peace/screens/settings/widget/image_crop_helper.dart';

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
  String? _creatorId;
  @override
  void initState() {
    super.initState();
    memberList = widget.memberIds;
    groupProfilePic = widget.groupProfilePic;
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

  Future<void> _changeGroupPhoto(bool isCreator) async {
    if (!isCreator) {
      if (!mounted) return;
      showSnackBar(context: context, content: 'Only creator can change photo');
      return;
    }

    final picked = await pickImageFromGallery(context);
    if (picked == null) return;

    final cropped = await ImageCropHelper.cropProfilePic(picked);
    if (cropped == null) return;

    setState(() => _isUpdatingPic = true);

    try {
      final cloudinaryRepo = CommonCloudinaryRepository();
      final imageUrl = await cloudinaryRepo.storeFileToCloudinary(cropped);

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .update({'groupProfilePic': imageUrl});

      if (!mounted) return;
      setState(() => groupProfilePic = imageUrl);
    } catch (e) {
      if (mounted) {
        showSnackBar(context: context, content: 'Photo update failed');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPic = false);
      }
    }
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
                      onTap: () => _changeGroupPhoto(isCreator),
                      onLongPress: _viewGroupPhoto,
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
                        Text(
                          widget.groupName,
                          style: const TextStyle(
                            color: whiteColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isCreator)
                          const Icon(Icons.edit, color: whiteColor, size: 16),
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
                      _buildActionButton(Icons.person_add, 'Add'),
                      _buildActionButton(Icons.search, 'Search'),
                      _buildActionButton(Icons.notifications_outlined, 'Mute'),
                      GestureDetector(
                        onTap: () {
                          setState(() => _showMoreOptions = !_showMoreOptions);
                        },
                        child: Column(
                          children: [
                            const Icon(
                              Icons.more_horiz,
                              color: whiteColor,
                              size: 34,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Options',
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
            Positioned(
              right: 16,
              top: 220,
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildMoreOption('Leave', Icons.logout),
                    _buildMoreOption('Hide', Icons.visibility_off),
                    _buildMoreOption('Restrict', Icons.lock),
                    _buildMoreOption('Block', Icons.block),
                    _buildMoreOption('Report', Icons.report, color: Colors.red),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () => setState(() => _showMoreOptions = false),
      child: Column(
        children: [
          Icon(icon, color: whiteColor, size: 28),
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
    );
  }

  Widget _buildMoreOption(String label, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color ?? whiteColor, size: 18),
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

  Widget _buildInfoRow(String iconAsset, String title, String subtitle) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SvgPicture.asset(
              iconAsset,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(whiteColor, BlendMode.srcIn),
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
    );
  }

  Widget _buildMembersRow() {
    return FutureBuilder<List<String>>(
      future: _fetchMemberNames(),
      builder: (context, snapshot) {
        final names = snapshot.data ?? [];
        final subtitle = _formatMemberSubtitle(names);
        return _buildInfoRow('assets/svg/group.svg', 'Members', subtitle);
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
