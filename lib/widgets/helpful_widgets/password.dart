import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';

class Password extends StatefulWidget {
  final TextEditingController? controller;
  final void Function(bool isValid)? onChanged;
  const Password({super.key, this.controller, this.onChanged});

  @override
  State<Password> createState() => _PasswordState();
}

class _PasswordState extends State<Password> {
  late final TextEditingController passwordController;
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  bool isPasswordVisible = false;
  bool isConfirmPasswordWrong = false;
  bool isConfirmPasswordVisible = false;
  bool isPasswordFocused = false;
  bool _isDisposed = false;

  String passwordStrength = "";
  final RegExp lowerCase = RegExp(r'[a-z]');
  final RegExp symbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

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

    validateConfirmPassword();
    notifyParent();

    if (mounted) {
      setState(() {});
    }
  }

  void validateConfirmPassword() {
    if (_isDisposed) return;

    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    final bool wrong = confirm.isNotEmpty && !password.startsWith(confirm);

    if (mounted) {
      setState(() {
        isConfirmPasswordWrong = wrong;
      });
    }

    notifyParent();
  }

  void notifyParent() {
    if (_isDisposed) return;
    final isValid =
        (passwordStrength == "Medium" || passwordStrength == "Strong") &&
        !isConfirmPasswordWrong &&
        confirmPasswordController.text.isNotEmpty;

    widget.onChanged?.call(isValid);
  }

  Color get strengthColor {
    switch (passwordStrength) {
      case "Weak":
        return Colors.red;
      case "Medium":
        return Colors.orangeAccent;
      case "Strong":
        return uiColor;
      default:
        return Colors.transparent;
    }
  }

  void _onPasswordFocusChange() {
    if (_isDisposed) return;

    if (passwordFocus.hasFocus && mounted) {
      setState(() {
        isPasswordFocused = true;
      });
    }
  }

  void _onPasswordChange() {
    if (_isDisposed) return;
    checkPasswordStrength(passwordController.text);
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      passwordController = widget.controller!;
    } else {
      passwordController = TextEditingController();
    }

    passwordFocus.addListener(_onPasswordFocusChange);
    passwordController.addListener(_onPasswordChange);
  }

  @override
  void dispose() {
    _isDisposed = true;
    passwordFocus.removeListener(_onPasswordFocusChange);
    passwordController.removeListener(_onPasswordChange);
    if (widget.controller == null) {
      passwordController.dispose();
    }
    confirmPasswordController.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Password",
          style: TextStyle(color: Colors.black, fontSize: 14),
        ),
        const SizedBox(height: 6),
        _passwordField(
          controller: passwordController,
          focusNode: passwordFocus,
          isVisible: isPasswordVisible,
          hint: "New Password",
          onToggle: () {
            if (mounted) {
              setState(() => isPasswordVisible = !isPasswordVisible);
            }
            validateConfirmPassword();
          },
          onChanged: checkPasswordStrength,
        ),
        if (isPasswordFocused && passwordStrength.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              "Password Strength : $passwordStrength",
              style: TextStyle(
                color: strengthColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        const SizedBox(height: 10),
        Text(
          "Confirm Password",
          style: TextStyle(color: Colors.black, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Transform.translate(
          offset: Offset(
            0,
            (isPasswordFocused && passwordStrength.isNotEmpty) ? -4 : 0,
          ),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: Color(0xffffffff),
              borderRadius: BorderRadius.circular(17),

              border: Border.all(
                color: isConfirmPasswordWrong ? Colors.red : Colors.grey,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),

            child: TextField(
              controller: confirmPasswordController,
              focusNode: confirmPasswordFocus,
              obscureText: !isConfirmPasswordVisible,
              cursorColor: uiColor,
              onChanged: (_) => validateConfirmPassword(),
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Confirm Password",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffixIcon: GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                      });
                      validateConfirmPassword();
                    }
                  },
                  child: Icon(
                    isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isConfirmPasswordWrong)
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 14),
              SizedBox(width: 6),
              Text(
                "Wrong password, try again",
                style: TextStyle(color: Colors.red, fontSize: 11),
              ),
            ],
          ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isVisible,
    required String hint,
    required VoidCallback onToggle,
    required Function(String) onChanged,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: !isVisible,
        onChanged: onChanged,
        cursorColor: uiColor,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
