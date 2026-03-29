import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/widgets/helpful_widgets/info_popup.dart';

class EmailVerificationDialog extends StatefulWidget {
  final String email;
  final String generatedOtp;
  final Future<void> Function() onVerified;

  const EmailVerificationDialog({
    super.key,
    required this.email,
    required this.generatedOtp,
    required this.onVerified,
  });

  @override
  State<EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  int _attempts = 0;
  static const int _maxAttempts = 3;

  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Verify your email",
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter the 6-digit code sent to your email",
              style: TextStyle(color: Color(0xFF666666), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Email Code",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(fontSize: 16, color: Colors.black),
              decoration: InputDecoration(
                hintText: "Enter 6-digit code",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                counterText: "",
                filled: true,
                fillColor: const Color(0xffffffff),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(color: uiColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffe0e0e0),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final code = _codeController.text.trim();

                        if (code.isEmpty) {
                          InfoPopup.show(
                            context,
                            "Please enter the 6-digit verification code sent to your email",
                          );
                          return;
                        }

                        if (_attempts >= _maxAttempts) {
                          InfoPopup.show(
                            context,
                            "Too many requests. Please try again in a bit",
                          );
                          return;
                        }

                        //try {
                        //final functions = FirebaseFunctions.instanceFor(
                        //region: 'us-central1',
                        //);

                        //final result = await functions
                        //  .httpsCallable('verifyEmailOtp')
                        // .call({"email": widget.email, "otp": code});

                        //if (result.data["verified"] == true) {
                        if (code == widget.generatedOtp) {
                          _attempts = 0;
                          Navigator.pop(context);
                          await widget.onVerified();
                          // }
                          // } catch (e) {
                        } else {
                          _attempts++;

                          if (_attempts >= _maxAttempts) {
                            InfoPopup.show(
                              context,
                              "Too many requests. Please try again in a bit",
                            );
                          } else {
                            InfoPopup.show(context, "Incorrect code");
                          }
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: uiColor,
                        foregroundColor: whiteColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Verify",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
