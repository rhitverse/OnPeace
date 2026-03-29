import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/common/utils/utils.dart';
import 'package:on_peace/features/auth/controller/auth_controller.dart';
import 'package:on_peace/features/auth/repository/auth_providers.dart';
import 'package:on_peace/models/user_model.dart';
import 'package:on_peace/screens/Profile/bio_screen.dart';
import 'package:on_peace/screens/Profile/birthday_screen.dart';
import 'package:on_peace/screens/Profile/display_edit_screen.dart';
import 'package:on_peace/screens/Profile/username_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/screens/settings/widget/image_crop_helper.dart';
import 'package:on_peace/widgets/helpful_widgets/profilepic.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String formatBirthday(String date) {
  final dob = DateTime.parse(date);
  return DateFormat('dd MMMM yyyy').format(dob);
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  bool isSaving = false;
  bool allowAddById = true;
  bool _allowAddLoaded = false;
  File? image;
  File? bannerImage;

  String formatBirthday(String date) {
    final dob = DateTime.parse(date);
    return DateFormat('dd MMMM yyyy').format(dob);
  }

  Future<void> _loadAllowAddById() async {
    if (_allowAddLoaded) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final val = doc.data()?['allowAddById'];
      if (mounted) {
        setState(() {
          allowAddById = val ?? true;
          _allowAddLoaded = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleAllowAddById(bool value) async {
    setState(() => allowAddById = value);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'allowAddById': value,
      });
    } catch (_) {}
  }

  void selectImage() async {
    final picked = await pickImageFromGallery(context);
    if (picked == null) return;

    final cropped = await ImageCropHelper.cropProfilePic(picked);
    if (cropped == null) return;

    setState(() {
      image = cropped;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAllowAddById();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (UserModel user) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: whiteColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Profile",
                  style: TextStyle(
                    color: whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                TextButton(
                  onPressed: (image == null || isSaving)
                      ? null
                      : () {
                          Navigator.pop(context);
                          ref
                              .read(authControllerProvider)
                              .saveUserDataToFirebase(
                                context,
                                nameController.text.trim(),
                                image,
                              );
                        },
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.disabled)) {
                        return Colors.grey;
                      }
                      return uiColor;
                    }),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        selectImage();
                      },
                      onLongPress: () {
                        if (image == null &&
                            (user.profilePic.isEmpty ||
                                user.profilePic ==
                                    'https://yt3.ggpht.com/a/default-user=s600-k-no-rp-mo')) {
                          return;
                        }
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: backgroundColor,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (_) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.remove_red_eye,
                                    color: whiteColor,
                                  ),
                                  title: const Text(
                                    'View',
                                    style: TextStyle(color: whiteColor),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: image != null
                                            ? Image.file(
                                                image!,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                user.profilePic,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: backgroundColor,
                                        title: const Text(
                                          'Delete Profile Picture?',
                                          style: TextStyle(color: whiteColor),
                                        ),
                                        content: const Text(
                                          'Are you sure you want to delete your profile picture?',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: whiteColor,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      setState(() {
                                        isSaving = true;
                                        image = null;
                                      });
                                      await ref
                                          .read(authControllerProvider)
                                          .deleteProfilePicture(
                                            context: context,
                                          );
                                      setState(() {
                                        isSaving = false;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          profileAvatar(
                            radius: 66,
                            image: image,
                            photoUrl: user.profilePic,
                          ),
                          if (isSaving)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: whiteColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _tile(
                    "Display name",
                    value: user.displayname,
                    onTap: () => _go(context, const DisplayEditScreen()),
                  ),
                  _tile(
                    "Bio",
                    value: user.bio,
                    onTap: () => _go(context, const BioScreen()),
                  ),
                  const SizedBox(height: 8),
                  _tile(
                    "Usename",
                    value: user.username,
                    onTap: () => _go(context, const UsernameScreen()),
                  ),
                  const SizedBox(height: 17),
                  const Divider(),
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Allow others to add me by ID",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: whiteColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              allowAddById
                                  ? "Others can add you as a friend searching your ID"
                                  : "Others can add you as a friend searching your ID",
                              style: TextStyle(
                                fontSize: 14,
                                color: allowAddById ? Colors.grey : Colors.grey,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: allowAddById,
                          onChanged: _toggleAllowAddById,
                          activeThumbColor: whiteColor,
                          activeTrackColor: uiColor,
                          inactiveThumbColor: whiteColor,
                          inactiveTrackColor: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      DateTime dob;
                      if (user.birthday == null || user.birthday!.isEmpty) {
                        dob = DateTime.now();
                      } else {
                        dob = DateTime.parse(user.birthday!);
                      }
                      _go(
                        context,
                        BirthdayScreen(
                          birthday: dob,
                          showBirthday: user.showBirthday,
                          showBirthYear: user.showBirthYear,
                          onShowBirthdayChanged: (val) {
                            ref
                                .read(authControllerProvider)
                                .updateShowBirthday(val);
                          },
                          onShowBirthYearChanged: (val) {
                            ref
                                .read(authControllerProvider)
                                .updateShowBirthYear(val);
                          },
                          onBirthdayChanged: (newDob) {
                            ref
                                .read(authControllerProvider)
                                .updateBirthday(context: context, dob: newDob);
                          },
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const Text(
                            "Birthday",
                            style: TextStyle(color: whiteColor, fontSize: 18),
                          ),
                          const Spacer(),
                          Text(
                            user.showBirthday
                                ? (user.birthday != null &&
                                          user.birthday!.isNotEmpty
                                      ? (user.showBirthYear
                                            ? formatBirthday(user.birthday!)
                                            : DateFormat('dd MMMM').format(
                                                DateTime.parse(user.birthday!),
                                              ))
                                      : "Not set")
                                : "Hidden",
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tile(String title, {String? value, VoidCallback? onTap}) {
    final bool hasValue = value != null && value.trim().isNotEmpty;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.normal,
          color: Colors.grey,
          fontSize: 13,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          hasValue ? value : "Not set",
          style: TextStyle(
            color: hasValue ? whiteColor : Colors.grey,
            fontSize: 17,
          ),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
