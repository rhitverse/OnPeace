/*
import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/user/aga_screen.dart';

class UsernamePassword extends StatefulWidget {
  const UsernamePassword({super.key});

  @override
  State<UsernamePassword> createState() => _UsernamePasswordState();
}

class _UsernamePasswordState extends State<UsernamePassword> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode usernameFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool isUsernameInvalid = false;
  bool isUsernameFocused = false;
  bool isPasswordFocused = false;
  bool isPasswordVisible = false;

  String passwordStrength = "";

  final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_.]+$');
  final RegExp lowerCase = RegExp(r'[a-z]');
  final RegExp symbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  void validateUsername(String value) {
    if (value.isEmpty) {
      isUsernameInvalid = false;
    } else {
      isUsernameInvalid = !usernameRegex.hasMatch(value);
    }
    setState(() {});
  }

  void checkPasswordStrength(String value) {
    if (value.isEmpty) {
      passwordStrength = "";
    } else if (value.length < 8) {
      passwordStrength = "Weak";
    } else if (lowerCase.hasMatch(value) && symbol.hasMatch(value)) {
      passwordStrength = "Strong";
    } else {
      passwordStrength = "Medium";
    }
    setState(() {});
  }

  bool get isFormValid {
    return !isUsernameInvalid &&
        usernameController.text.isNotEmpty &&
        (passwordStrength == "Medium" || passwordStrength == "Strong");
  }

  Color get strengthColor {
    switch (passwordStrength) {
      case "Weak":
        return Colors.red;
      case "Medium":
        return Colors.orange;
      case "Strong":
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }

  @override
  void initState() {
    super.initState();

    usernameFocus.addListener(() {
      setState(() {
        isUsernameFocused = usernameFocus.hasFocus;
      });
    });

    passwordFocus.addListener(() {
      setState(() {
        isPasswordFocused = passwordFocus.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    usernameFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(
        backgroundColor: const Color(0xff040406),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsetsGeometry.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: whiteColor),
                ),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    "Next, create an account",
                    style: TextStyle(
                      color: whiteColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  "Username",
                  style: TextStyle(color: whiteColor70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xff1e2023),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUsernameInvalid
                          ? Colors.red
                          : Colors.transparent,
                      width: 1.3,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    focusNode: usernameFocus,
                    controller: usernameController,
                    onChanged: validateUsername,
                    style: const TextStyle(color: whiteColor),
                    cursorColor: Colors.green,
                    decoration: const InputDecoration(
                      hintText: "Username",
                      hintStyle: TextStyle(color: whiteColor54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (isUsernameFocused && !isUsernameInvalid)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      "Only use letters, number, underscores, and periods.",
                      style: TextStyle(color: whiteColor54, fontSize: 12),
                    ),
                  ),
                if (isUsernameInvalid)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 14),
                        SizedBox(width: 6),
                        Text(
                          "Please only use numbers, letters, underscores, or periods.",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
                const Text(
                  "Password",
                  style: TextStyle(color: whiteColor70, fontSize: 14),
                ),

                const SizedBox(height: 8),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xff1e2023),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    focusNode: passwordFocus,
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    onChanged: checkPasswordStrength,
                    style: const TextStyle(color: whiteColor),
                    cursorColor: Colors.green,
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: const TextStyle(color: whiteColor54),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                        child: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: whiteColor54,
                        ),
                      ),
                    ),
                  ),
                ),

                if (isPasswordFocused)
                  Column(
                    children: [
                      if (passwordStrength.isNotEmpty)
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                "Password Strength : $passwordStrength",
                                style: TextStyle(
                                  color: strengthColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const Padding(
                        padding: EdgeInsetsGeometry.only(top: 4),
                        child: Text(
                          "Password must be 8 or more characters. Strong password have a symbol, one uppercase, and lowercase letter.",
                          style: TextStyle(color: whiteColor54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isFormValid
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AgaScreen(),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: uiColor,
                      disabledBackgroundColor: uiColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Next",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: whiteColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
*/
