import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/widgets/helpful_widgets/info_popup.dart';

class EmailVerificationDialog extends StatefulWidget {
  final String email;

  const EmailVerificationDialog({super.key, required this.email});

  @override
  State<EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  bool _isSendingEmail = false;
  bool _isChecking = false;
  bool _emailSent = false;

  Future<void> _sendVerificationEmail() async {
    setState(() => _isSendingEmail = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        InfoPopup.show(context, "Session expired. Please sign up again.");
        return;
      }
      await user.sendEmailVerification();
      if (mounted) {
        setState(() => _emailSent = true);
        InfoPopup.show(context, "Verification link sent to ${widget.email}");
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        InfoPopup.show(
          context,
          e.message ?? "Failed to send verification email.",
        );
      }
    } catch (_) {
      if (mounted)
        InfoPopup.show(context, "Failed to send verification email.");
    } finally {
      if (mounted) setState(() => _isSendingEmail = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        InfoPopup.show(context, "Session expired. Please sign up again.");
        return;
      }

      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;

      if (refreshed != null && refreshed.emailVerified) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        if (mounted) {
          InfoPopup.show(
            context,
            "Email not verified yet. Please click the link in your inbox first.",
          );
        }
      }
    } catch (_) {
      if (mounted)
        InfoPopup.show(context, "Could not check verification status.");
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = _isSendingEmail || _isChecking;

    return Dialog(
      backgroundColor: whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: uiColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_rounded,
                color: uiColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              _emailSent ? "Check your inbox" : "Verify your email",
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Text(
              _emailSent
                  ? "We sent a verification link to\n${widget.email}\n\nClick the link in your email, then come back and tap \"I've Verified\"."
                  : "Tap below to send a verification link to\n${widget.email}",
              style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: busy
                    ? null
                    : (_emailSent
                          ? _checkVerification
                          : _sendVerificationEmail),
                style: ElevatedButton.styleFrom(
                  backgroundColor: uiColor,
                  foregroundColor: whiteColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: whiteColor,
                        ),
                      )
                    : Text(
                        _emailSent
                            ? "I've Verified ✓"
                            : "Send Verification Link",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            if (_emailSent) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: busy ? null : _sendVerificationEmail,
                child: const Text(
                  "Resend link",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
