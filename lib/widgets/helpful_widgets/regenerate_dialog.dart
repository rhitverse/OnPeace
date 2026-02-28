import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';

class RegenerateDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const RegenerateDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: searchBarColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 20),
            Text(
              "Are you sure you want to generate a new QR code? Your existing QR code and invite link will no longer be valid.",
              style: TextStyle(color: whiteColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(color: whiteColor, fontSize: 20),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text(
            "Confirm",
            style: TextStyle(color: uiColor, fontSize: 20),
          ),
        ),
      ],
    );
  }
}

void showRegenerateDialog(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (context) => RegenerateDialog(onConfirm: onConfirm),
  );
}
