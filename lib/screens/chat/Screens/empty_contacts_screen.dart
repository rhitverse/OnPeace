import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';

class EmptyContactsScreen extends StatelessWidget {
  const EmptyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),

                child: Image.asset("assets/app.png", width: 120, height: 120),
              ),

              const SizedBox(height: 40),
              const Text(
                "No Contacts Yet",
                style: TextStyle(
                  color: whiteColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
              Text(
                "Start adding contacts to begin chatting.\nYour contacts will appear here.",
                style: TextStyle(
                  color: whiteColor.withOpacity(0.7),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
