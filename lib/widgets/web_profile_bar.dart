import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';

class WebProfileBar extends StatelessWidget {
  const WebProfileBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.077,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: webBackgroundColor),

      child: Row(
        children: [
          const Text(
            "WhatsApp",
            style: TextStyle(
              color: whiteColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          SizedBox(width: 25),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: whiteColor),
          ),
        ],
      ),
    );
  }
}
