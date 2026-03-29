import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/features/auth/controller/auth_controller.dart';
import 'package:on_peace/features/auth/repository/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/widgets/helpful_widgets/info_popup.dart';

class DisplayEditScreen extends ConsumerStatefulWidget {
  const DisplayEditScreen({super.key});

  @override
  ConsumerState<DisplayEditScreen> createState() => _DisplayEditScreenState();
}

class _DisplayEditScreenState extends ConsumerState<DisplayEditScreen> {
  final TextEditingController nameController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
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
          "Display name",
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
            nameController.text = user.displayname;
            _isInitialized = true;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30),
                const Text(
                  "Display Name",
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 58,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    color: Colors.transparent,
                    border: Border.all(color: uiColor, width: 1.5),
                  ),
                  child: Center(
                    child: TextField(
                      controller: nameController,
                      cursorColor: uiColor,
                      maxLength: 20,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Enter your name",
                        counterText: "",
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        suffixIcon: nameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 17),
                                onPressed: () {
                                  nameController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();

                      if (name.isEmpty) {
                        InfoPopup.show(context, "Enter your name");
                        return;
                      }

                      await ref
                          .read(authControllerProvider)
                          .saveUserDataToFirebase(context, name, null);

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: uiColor,
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
