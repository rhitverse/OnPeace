import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/features/app/welcome/welcome_page.dart';
import 'package:on_peace/features/auth/controller/auth_controller.dart';
import 'package:on_peace/screens/user/display_name.dart';
import 'package:on_peace/widgets/helpful_widgets/app_loader.dart';
import 'package:on_peace/widgets/helpful_widgets/email_verfication_dialog.dart';
import 'package:on_peace/widgets/helpful_widgets/info_popup.dart';
import 'package:on_peace/widgets/helpful_widgets/input_field.dart';
import 'package:on_peace/widgets/helpful_widgets/password.dart';

class RegisteScreen extends ConsumerStatefulWidget {
  const RegisteScreen({super.key});

  @override
  ConsumerState<RegisteScreen> createState() => _RegisteScreenState();
}

class _RegisteScreenState extends ConsumerState<RegisteScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  DateTime? selectedDate;
  bool receiveEmails = true;
  bool isLoading = false;
  String? errorText;

  String generate6DigiCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  String get formattedDate {
    if (selectedDate == null) return "";
    return DateFormat("MM/dd/yyyy").format(selectedDate!);
  }

  bool get isDobValid {
    if (selectedDate == null) return false;
    final now = DateTime.now();
    int age = now.year - selectedDate!.year;

    if (now.month < selectedDate!.month ||
        (now.month == selectedDate!.month && now.day < selectedDate!.day)) {
      age--;
    }
    return age >= 13;
  }

  void openDatePicker() async {
    final date = await DatePicker.showSimpleDatePicker(
      context,
      initialDate: DateTime(2004),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      dateFormat: "dd-MMMM_yyyy",
      locale: DateTimePickerLocale.en_us,
      titleText: "Date of Birth",
      textColor: Colors.black,
      backgroundColor: whiteColor,
      itemTextStyle: const TextStyle(color: Colors.black, fontSize: 18),
      looping: false,
      confirmText: "CONFIRM",
      cancelText: "CANCEL",
    );

    if (date != null) {
      final age = DateTime.now().year - date.year;
      setState(() {
        errorText = age < 13 ? "Please enter a valid date of birth" : null;
        selectedDate = date;
      });
    }
  }

  Future<void> createAccountAfterVerification() async {
    setState(() => isLoading = true);
    final loader = AppLoader.show(context, message: "Creating your account...");

    try {
      await ref
          .read(authControllerProvider)
          .signUpWithEmail(
            context: context,
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      if (selectedDate != null) {
        await ref
            .read(authControllerProvider)
            .updateBirthday(context: context, dob: selectedDate!);
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DisplayName()),
      );
    } catch (e) {
      InfoPopup.show(context, "Failed to create account. Please try again.");
    } finally {
      loader.remove();
      setState(() => isLoading = false);
    }
  }

  Future<void> handleSignUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      InfoPopup.show(context, "Fill up your Details");
      return;
    }

    if (selectedDate == null) {
      InfoPopup.show(context, "Please select your Date of Birth");
      return;
    }

    if (!isDobValid) {
      InfoPopup.show(context, "You must be 13 years or older to sign up.");
      return;
    }

    try {
      final generatedOtp = generate6DigiCode();

      print("Generated OTP: $generatedOtp");

      // final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

      // await functions.httpsCallable('sendEmailOtp').call({
      // "email": email,
      //"otp": generatedOtp,
      //});

      showEmailVerificationDialog(generatedOtp);
    } catch (e) {
      InfoPopup.show(
        context,
        "Failed to send verification email. Please try again.",
      );
    }
  }

  void showEmailVerificationDialog(String otp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return EmailVerificationDialog(
          email: emailController.text.trim(),
          generatedOtp: otp,
          onVerified: () async {
            await createAccountAfterVerification();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff73c088), Color(0xff12b13d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.111,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            "Create Your\nAccount",
                            style: TextStyle(
                              color: whiteColor,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        ),
                        Image.asset(
                          "assets/app.png",
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, 56),
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      decoration: const BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          Text(
                            "Email",
                            style: TextStyle(color: Colors.black, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          InputField(
                            hint: "Email",
                            controller: emailController,
                          ),
                          const SizedBox(height: 12),
                          Password(controller: passwordController),
                          SizedBox(height: 8),
                          Text(
                            "Date of Birth",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: openDatePicker,
                            child: Container(
                              height: 58,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xffffffff),
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                selectedDate == null
                                    ? "DD / MM / YYYY"
                                    : formattedDate,
                                style: TextStyle(
                                  color: selectedDate == null
                                      ? Colors.grey
                                      : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          if (errorText != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  errorText!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 45),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: uiColor,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 0.5,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : handleSignUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: whiteColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                                children: [
                                  const TextSpan(
                                    text: "Already have an account?",
                                  ),
                                  TextSpan(
                                    text: " Sign In",
                                    style: const TextStyle(color: uiColor),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const WelcomePage(),
                                          ),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
