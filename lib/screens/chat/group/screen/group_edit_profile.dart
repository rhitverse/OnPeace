import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/common/utils/common_cloudinary_repository.dart';
import 'package:on_peace/common/utils/utils.dart';
import 'package:on_peace/screens/settings/widget/image_crop_helper.dart';

class GroupEditProfile extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupProfilePic;

  const GroupEditProfile({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupProfilePic,
  });

  @override
  State<GroupEditProfile> createState() => _GroupEditProfileState();
}

class _GroupEditProfileState extends State<GroupEditProfile> {
  final TextEditingController _nameController = TextEditingController();
  bool _isUpdatingName = false;
  bool _isUpdatingPic = false;
  late String _groupName;
  late String _groupProfilePic;
  late String _initialName;
  late String _initialProfilePic;

  @override
  void initState() {
    super.initState();
    _groupName = widget.groupName;
    _groupProfilePic = widget.groupProfilePic;
    _initialName = widget.groupName;
    _initialProfilePic = widget.groupProfilePic;
    _nameController.text = _groupName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final nextName = _nameController.text.trim();
    if (nextName.isEmpty || nextName == _groupName) return;

    setState(() => _isUpdatingName = true);
    try {
      await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .update({'groupName': nextName});

      if (!mounted) return;
      setState(() => _groupName = nextName);
    } catch (_) {
      if (mounted) {
        showSnackBar(context: context, content: 'Name update failed');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingName = false);
      }
    }
  }

  bool get _hasChanges =>
      _nameController.text.trim() != _initialName ||
      _groupProfilePic != _initialProfilePic;

  Future<void> _handleSave() async {
    if (!_hasChanges) return;
    await _saveName();
    if (!mounted) return;
    _close();
  }

  Future<void> _changeGroupPhoto() async {
    final picked = await pickImageFromGallery(context);
    if (picked == null) return;

    final cropped = await ImageCropHelper.cropProfilePic(picked);
    if (cropped == null) return;

    setState(() => _isUpdatingPic = true);
    try {
      final cloudinaryRepo = CommonCloudinaryRepository();
      final imageUrl = await cloudinaryRepo.storeFileToCloudinary(cropped);
      if (imageUrl == null) throw Exception('Failed to upload image');

      await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .update({'groupProfilePic': imageUrl});

      if (!mounted) return;
      setState(() => _groupProfilePic = imageUrl);
    } catch (_) {
      if (mounted) {
        showSnackBar(context: context, content: 'Photo update failed');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPic = false);
      }
    }
  }

  Future<void> _removeGroupPhoto() async {
    if (_groupProfilePic.isEmpty) return;
    setState(() => _isUpdatingPic = true);
    try {
      await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .update({'groupProfilePic': ''});

      if (!mounted) return;
      setState(() => _groupProfilePic = '');
    } catch (_) {
      if (mounted) {
        showSnackBar(context: context, content: 'Photo remove failed');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPic = false);
      }
    }
  }

  void _close() {
    Navigator.pop(context, {
      'groupName': _groupName,
      'groupProfilePic': _groupProfilePic,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Edit group', style: TextStyle(color: whiteColor)),
        leading: IconButton(
          onPressed: _close,
          icon: const Icon(Icons.arrow_back_ios, color: whiteColor),
        ),
        actions: [
          if (_isUpdatingName)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: whiteColor,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _hasChanges ? _handleSave : null,
              child: Text(
                'Save',
                style: TextStyle(color: _hasChanges ? uiColor : Colors.grey),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _changeGroupPhoto,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _groupProfilePic.isNotEmpty
                        ? NetworkImage(_groupProfilePic)
                        : null,
                    child: _groupProfilePic.isEmpty
                        ? const Icon(Icons.group, size: 56, color: whiteColor)
                        : null,
                  ),
                  if (_groupProfilePic.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: GestureDetector(
                        onTap: _removeGroupPhoto,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: whiteColor,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  if (_isUpdatingPic)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
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
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: whiteColor),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Group name',
                labelStyle: TextStyle(color: Colors.grey[500]),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: whiteColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
