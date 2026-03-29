import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/common/enum/username_result.dart';
import 'package:on_peace/features/auth/controller/auth_controller.dart';
import 'package:on_peace/features/auth/repository/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsernameScreen extends ConsumerStatefulWidget {
  const UsernameScreen({super.key});

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreen();
}

class _UsernameScreen extends ConsumerState<UsernameScreen> {
  final TextEditingController nameController = TextEditingController();
  bool _isInitialized = false;
  String? usernameError;
  bool isButtonEnabled = false;

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
  }

  void _updateButtonState() {
    final text = nameController.text.trim();
    setState(() {
      isButtonEnabled = text.length >= 4;

      if (text.isEmpty) {
        usernameError = null;
      } else if (text.length < 4) {
        usernameError = "Username must  be at least 4 characters";
      } else if (text.length > 20) {
        usernameError = "Username must be less than 20 characters";
      } else if (text != text.toLowerCase()) {
        usernameError = "Username cannot contain uppercase letters";
      } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(text)) {
        usernameError =
            "Username can only contain letters, numbers and underscore";
      } else {
        usernameError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            fontWeight: FontWeight.w100,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Username",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),

        data: (user) {
          if (!_isInitialized) {
            nameController.text = user.username ?? '';
            _isInitialized = true;
            _updateButtonState();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30),
                const Text(
                  "Username",
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),

                const SizedBox(height: 8),
                Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: usernameError != null ? Colors.red : uiColor,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: TextField(
                      controller: nameController,
                      cursorColor: uiColor,
                      maxLength: 20,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Choose a unique username like you",
                        counterText: "",
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        suffixIcon: nameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 17),
                                onPressed: () {
                                  nameController.clear();
                                  _updateButtonState();
                                  setState(() {});
                                  usernameError = null;
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        _updateButtonState();
                        setState(() {});
                      },
                    ),
                  ),
                ),
                if (usernameError != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      usernameError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isButtonEnabled && usernameError == null
                        ? () async {
                            final name = nameController.text.trim();
                            final result = await ref
                                .read(authControllerProvider)
                                .setUsername(username: name);
                            switch (result) {
                              case UsernameResult.alreadyExists:
                                setState(() {
                                  usernameError = "Username already exists";
                                });
                                break;

                              case UsernameResult.toEarly:
                                setState(() {
                                  usernameError =
                                      "You can change your username after 30 days";
                                });
                                break;

                              case UsernameResult.success:
                                if (context.mounted) Navigator.pop(context);
                                break;
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isButtonEnabled && usernameError == null
                          ? uiColor
                          : Colors.green.withOpacity(0.4),
                      disabledBackgroundColor: Colors.green.withOpacity(0.4),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        color: whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          );
        },
      ),
    );
  }
}
