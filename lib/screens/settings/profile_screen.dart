import 'dart:io';
import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/common/utils/utils.dart';
import 'package:whatsapp_clone/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_clone/features/auth/repository/auth_providers.dart';
import 'package:whatsapp_clone/models/user_model.dart';
import 'package:whatsapp_clone/screens/Profile/bio_screen.dart';
import 'package:whatsapp_clone/screens/Profile/birthday_screen.dart';
import 'package:whatsapp_clone/screens/Profile/display_edit_screen.dart';
import 'package:whatsapp_clone/screens/Profile/username_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/widgets/helpful_widgets/profilepic.dart';
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
    image = await pickImageFromGallery(context);
    setState(() {});
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
                                    'https://scontent-ssn1-1.cdninstagram.com/v/t51.2885-19/573323465_1219825463302212_7278921664109726296_n.png?stp=dst-jpg_e0_s150x150_tt6&efg=eyJ2ZW5jb2RlX3RhZyI6InByb2ZpbGVfcGljLmRqYW5nby4xNTAuYzIifQ&_nc_ht=scontent-ssn1-1.cdninstagram.com&_nc_cat=1&_nc_oc=Q6cZ2QH-D4ZS7uKSql_7HpxPaexdEIDjMMfhNvl9oU4gByxeIGsh_5gJXnszJMFR51u0JMs&_nc_ohc=2tyZ8HJj7tUQ7kNvwFR5mRI&_nc_gid=GRpEBnRVsBgnwu3BMSgGcQ&edm=AGqCYasBAAAA&ccb=7-5&ig_cache_key=YW5vbnltb3VzX3Byb2ZpbGVfcGlj.3-ccb7-5&oh=00_AfwDar6o1e1hMOGViptl34FG0-BsdSVP7vcySd3H1JcG6g&oe=69B5FAEA&_nc_sid=6c5dea')) {
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
                  SizedBox(height: 17),
                  const Divider(),
                  SizedBox(height: 9),
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
                  SizedBox(height: 10),
                  const Divider(),
                  SizedBox(height: 6),
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
                          Spacer(),
                          Text(
                            user.birthday != null && user.birthday!.isNotEmpty
                                ? formatBirthday(user.birthday!)
                                : "Not set",
                            style: TextStyle(
                              color:
                                  user.birthday != null &&
                                      user.birthday!.isEmpty
                                  ? Colors.grey
                                  : Colors.white60,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.grey),
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
