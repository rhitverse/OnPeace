import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:on_peace/screens/chat/group/screen/selected_friend_group.dart';
import 'package:on_peace/screens/chat/group/controller/group_chat_provider.dart';
import 'package:on_peace/common/utils/common_cloudinary_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class CreateGroupChat extends ConsumerStatefulWidget {
  final Set<String> selectedFriends;
  final Map<String, Map<String, dynamic>> selectedFriendsData;

  const CreateGroupChat({
    super.key,
    required this.selectedFriends,
    required this.selectedFriendsData,
  });

  @override
  ConsumerState<CreateGroupChat> createState() => _CreateGroupChatState();
}

class _CreateGroupChatState extends ConsumerState<CreateGroupChat> {
  final TextEditingController groupNameController = TextEditingController();
  bool autoApproveMembers = true;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  final int _maxLength = 50;
  bool _isCreating = false;

  late Set<String> _selectedFriends;
  late Map<String, Map<String, dynamic>> _selectedFriendsData;

  @override
  void initState() {
    super.initState();
    _selectedFriends = Set.from(widget.selectedFriends);
    _selectedFriendsData = Map.from(widget.selectedFriendsData);
  }

  @override
  void dispose() {
    groupNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _goToAddFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectedFriendGroup(
          initialSelected: _selectedFriends,
          initialSelectedData: _selectedFriendsData,
          onDone: (newFriends, newData) {
            setState(() {
              _selectedFriends = newFriends;
              _selectedFriendsData = newData;
            });
          },
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    final finalName = groupNameController.text.isEmpty
        ? (widget.selectedFriendsData.values
                  .map((data) => data['displayname'] ?? 'Unknown')
                  .take(2)
                  .join(', ') +
              (widget.selectedFriendsData.length > 2
                  ? ' & ${widget.selectedFriendsData.length - 2} more'
                  : ''))
        : groupNameController.text;

    if (finalName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      print('Starting group creation...');
      print('Group name: $finalName');
      print('Members: ${_selectedFriends.length + 1}');
      print('Current user: $currentUserId');

      // Upload image if selected
      String groupProfilePic = '';
      if (_selectedImage != null) {
        print('Uploading group image...');
        final cloudinaryRepo = CommonCloudinaryRepository();
        final imageUrl = await cloudinaryRepo.storeFileToCloudinary(
          _selectedImage!,
        );
        if (imageUrl != null) {
          groupProfilePic = imageUrl;
          print('Image uploaded: $imageUrl');
        }
      }

      // Generate unique group ID
      const uuid = Uuid();
      final groupId = uuid.v4();
      print('Generated groupId: $groupId');

      // Add current user to members list
      final allMembers = [..._selectedFriends, currentUserId];
      print('All members: $allMembers');

      // Create group using controller
      final groupChatController = ref.read(groupChatControllerProvider);

      print('Calling createGroupChat...');
      await groupChatController.createGroupChat(
        groupId: groupId,
        groupName: finalName,
        members: allMembers,
        groupProfilePic: groupProfilePic,
      );
      print('Group created successfully in Firestore!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
        );

        // Wait a moment then navigate back to messages
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.popUntil(context, (route) {
            return route.isFirst;
          });
        }
      }
    } catch (e) {
      print('Error creating group: $e');
      print('Error stacktrace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating group: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String hintName = widget.selectedFriendsData.values
        .map((data) => data['displayname'] ?? 'Unknown')
        .take(2)
        .join(', ');
    if (widget.selectedFriendsData.length > 2) {
      hintName += ' & ${widget.selectedFriendsData.length - 2} more';
    }

    final charCount = groupNameController.text.length;

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
        title: const Text(
          "Set up group profile",
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                    ),
                  )
                : Text(
                    'Create',
                    style: TextStyle(
                      color: whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: searchBarColor,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : null,
                          child: _selectedImage == null
                              ? const Icon(
                                  Icons.groups_2,
                                  size: 40,
                                  color: whiteColor,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3A3A3A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: whiteColor,
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$charCount/$_maxLength',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        TextField(
                          controller: groupNameController,
                          onChanged: (val) => setState(() {}),
                          cursorColor: uiColor,
                          maxLength: _maxLength,
                          style: const TextStyle(
                            color: whiteColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: hintName,
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey,
                                width: 0.5,
                              ),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey,
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: uiColor,
                                width: 1.5,
                              ),
                            ),
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Members join automatically',
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Members join the group as soon as they\'re invited. Disable this setting to always require members to accept an invite before joining.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'More about groups',
                            style: TextStyle(
                              color: uiColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(
                      () => autoApproveMembers = !autoApproveMembers,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: autoApproveMembers
                            ? uiColor
                            : Colors.transparent,
                        border: Border.all(
                          color: autoApproveMembers ? uiColor : Colors.grey,
                          width: 1.5,
                        ),
                      ),
                      child: autoApproveMembers
                          ? const Icon(Icons.check, color: whiteColor, size: 16)
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Members ${_selectedFriends.length + 1}',
                    style: const TextStyle(
                      color: whiteColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedFriends.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: _goToAddFriends,
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 1.4,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: whiteColor,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final uid = _selectedFriends.elementAt(index - 1);
                        final data = _selectedFriendsData[uid] ?? {};
                        final name = data['displayname'] ?? 'Unknown';
                        final profilePic = data['profilePic'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
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
                                          _selectedFriends.remove(uid);
                                          _selectedFriendsData.remove(uid);
                                        });
                                      },
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: const BoxDecoration(
                                          color: Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 12,
                                          color: whiteColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 52,
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
