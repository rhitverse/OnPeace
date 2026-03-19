import 'dart:io';
import 'package:whatsapp_clone/common/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_clone/screens/mobile_screen_layout.dart';
import 'package:whatsapp_clone/widgets/helpful_widgets/app_loader.dart';
import 'package:whatsapp_clone/widgets/helpful_widgets/info_popup.dart';
import 'package:whatsapp_clone/widgets/helpful_widgets/input_field.dart';
import 'package:whatsapp_clone/widgets/helpful_widgets/profilepic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisplayName extends ConsumerStatefulWidget {
  const DisplayName({super.key});

  @override
  ConsumerState<DisplayName> createState() => _DisplayNameState();
}

class _DisplayNameState extends ConsumerState<DisplayName> {
  final TextEditingController nameController = TextEditingController();
  bool isSaving = false;
  File? image;

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
  }

  void selectImage() async {
    image = await pickImageFromGallery(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        title: Text(
          "Create a new account",
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Other people on MINE can see your display name and \n profile media.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    profileAvatar(
                      radius: 34,
                      image: image,
                      photoUrl:
                          'https://yt3.ggpht.com/a/default-user=s600-k-no-rp-mo',
                    ),

                    InkWell(
                      onTap: () {
                        selectImage();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          size: 20,
                          color: whiteColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Display Name",
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),

                const SizedBox(height: 8),
                InputField(
                  hint: "What's your name?",
                  controller: nameController,
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Text(
              "You can use emoji and special characters.",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) {
                          InfoPopup.show(
                            context,
                            "Please enter a display name",
                          );
                          return;
                        }

                        setState(() {
                          isSaving = true;
                        });

                        OverlayEntry? loader;

                        try {
                          loader = AppLoader.show(
                            context,
                            message: "Creating your account...",
                          );

                          await ref
                              .read(authControllerProvider)
                              .saveUserDataToFirebase(
                                context,
                                nameController.text.trim(),
                                image,
                              );

                          await Future.delayed(
                            const Duration(milliseconds: 800),
                          );
                          loader.remove();
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MobileScreenLayout(),
                            ),
                            (route) => false,
                          );
                        } catch (e) {
                          loader?.remove();
                          setState(() {
                            isSaving = false;
                          });

                          if (!mounted) return;

                          InfoPopup.show(
                            context,
                            "Error creating account. Please try again",
                          );
                          debugPrint("Account creation error: $e");
                        }
                      },

                style: ElevatedButton.styleFrom(
                  backgroundColor: isSaving ? Colors.grey : uiColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: whiteColor,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Next",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: whiteColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
