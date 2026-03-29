import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/features/auth/repository/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String verificationId;
  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final int otpLength = 6;
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();

    controllers = List.generate(otpLength, (_) => TextEditingController());
    focusNodes = List.generate(otpLength, (_) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNodes[0].requestFocus();
    });
  }

  Widget otpBox(int index) {
    return SizedBox(
      width: 45,
      height: 55,
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          color: whiteColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        cursorColor: Colors.green,
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: const Color(0xff1e2023),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => onChanged(value, index),
      ),
    );
  }

  void onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < otpLength - 1) {
        focusNodes[index + 1].requestFocus();
      }
    } else {
      if (index > 0) {
        focusNodes[index - 1].requestFocus();
      }
    }
    setState(() {});
  }

  bool get isOtpComplete => controllers.every((c) => c.text.isNotEmpty);

  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff040406),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Confirm Your Number",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter the 6-digit code sent to",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  color: whiteColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(otpLength, otpBox),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  debugPrint("Resend OTP");
                },
                child: const Text(
                  "Resend code",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isOtpComplete
                      ? () {
                          final otp = controllers.map((c) => c.text).join();
                          final authRepo = ref.read(authRepositoryProvider);
                          authRepo.verifyOtp(
                            context: context,
                            verificationId: widget.verificationId,
                            otp: otp,
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
                    "Continue",
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
      ),
    );
  }
}
