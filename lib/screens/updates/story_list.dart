import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/info.dart';

class StoryList extends StatelessWidget {
  const StoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final storyUsers = info.where((user) => user['hasStory'] == true).toList();
    return Container(
      height: 120,
      color: backgroundColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: storyUsers.length + 1,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _yourStory();
          }
          final user = storyUsers[index - 1];
          return _storyItem(
            name: user['name']?.toString() ?? '',
            image: user['profilePic']?.toString() ?? '',
          );
        },
      ),
    );
  }

  Widget _yourStory() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Stack(
            children: [
              _gradientBorder(
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: const NetworkImage(
                    "https://upload.wikimedia.org/wikipedia/en/thumb/9/91/Mike_Wheeler.png/250px-Mike_Wheeler.png",
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    color: uiColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "It's yours",
            style: TextStyle(color: whiteColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _storyItem({required String name, required String image}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          _gradientBorder(
            child: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(image),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: whiteColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBorder({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: uiColor),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: child,
      ),
    );
  }
}
