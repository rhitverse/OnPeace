import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/features/auth/controller/auth_controller.dart';
import 'package:on_peace/features/auth/repository/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BioScreen extends ConsumerStatefulWidget {
  const BioScreen({super.key});

  @override
  ConsumerState<BioScreen> createState() => _BioScreenState();
}

class _BioScreenState extends ConsumerState<BioScreen> {
  final TextEditingController bioController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    bioController.dispose();
    super.dispose();
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Your Bio",
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
            bioController.text = user.bio ?? '';
            _isInitialized = true;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                TextField(
                  controller: bioController,
                  cursorColor: uiColor,
                  maxLength: 120,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: "Write something about yourself",
                    counterText: '',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: uiColor, width: 1.2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: uiColor, width: 1.2),
                    ),
                    suffixIcon: bioController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              bioController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(authControllerProvider)
                          .updateBio(bioController.text.trim());

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: uiColor,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
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

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
