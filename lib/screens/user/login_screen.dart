import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/features/auth/controller/auth_controller.dart';
import 'package:on_peace/features/auth/repository/auth_providers.dart';
import 'package:on_peace/screens/user/registe_screen.dart';
import 'package:on_peace/widgets/helpful_widgets/input_field.dart';
import 'package:on_peace/common/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/widgets/helpful_widgets/info_popup.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const LoginScreen({super.key, required this.onClose});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailOrPhoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isGoogleLoading = false;

  @override
  void initState() {
    super.initState();

    emailOrPhoneController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    emailOrPhoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool get isLoginEnabled {
    return emailOrPhoneController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  bool isEmail(String input) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
  }

  Future<void> handleLogin() async {
    if (!isLoginEnabled) return;

    setState(() => isLoading = true);

    final email = emailOrPhoneController.text.trim();
    final password = passwordController.text.trim();

    try {
      if (isEmail(email)) {
        await ref
            .read(authControllerProvider)
            .signInWithEmail(
              context: context,
              email: email,
              password: password,
            );
      } else {
        InfoPopup.show(
          context,
          "Phone login requires verification. Please use Register screen.",
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> handleGoogleSignIn() async {
    setState(() => isGoogleLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogle(context: context);
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Google sign-in failed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "Welcome Back!",
              style: TextStyle(
                color: Colors.black,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Email",
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),

                const SizedBox(height: 8),
                InputField(
                  hint: "Enter email",
                  controller: emailOrPhoneController,
                ),
                const SizedBox(height: 15),
                const Text(
                  "Password",
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
                const SizedBox(height: 8),
                InputField(
                  hint: "Enter password",
                  obscure: true,
                  controller: passwordController,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  showSnackBar(
                    context: context,
                    content: 'Password reset feature coming soon!',
                  );
                },
                child: Text(
                  "Forgot your password?",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (emailOrPhoneController.text.isEmpty) {
                    InfoPopup.show(
                      context,
                      'Please enter your email and password',
                    );
                    return;
                  }
                  handleLogin();
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: uiColor,
                  side: BorderSide(color: Colors.grey, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: whiteColor,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "Log In",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: whiteColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                  child: Text(
                    "or sign with",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
              ],
            ),
            SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: isGoogleLoading ? null : handleGoogleSignIn,

                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey, width: 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),

                child: isGoogleLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,

                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/google.png',
                            height: 32,
                            width: 32,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 50),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                children: [
                  const TextSpan(text: "Don't have an account?"),
                  TextSpan(
                    text: " Sign Up",
                    style: const TextStyle(color: uiColor),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisteScreen(),
                          ),
                        );
                      },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
