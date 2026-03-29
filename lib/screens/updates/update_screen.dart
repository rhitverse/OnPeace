import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/updates/story_list.dart';

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          "Updates",
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search_outlined, size: 28, color: whiteColor),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert_outlined, size: 28, color: whiteColor),
          ),
        ],
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            const Text(
              "Status",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: whiteColor,
              ),
            ),
            const SizedBox(height: 8),
            const StoryList(),
          ],
        ),
      ),
    );
  }
}
