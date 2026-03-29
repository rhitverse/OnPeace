import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';

class WebSearchBar extends StatelessWidget {
  const WebSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.044,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: websearchBarColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.search, color: Colors.grey, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                style: const TextStyle(color: whiteColor, fontSize: 14),
                cursorColor: Colors.green,
                decoration: const InputDecoration(
                  hintText: 'Ask Meta AI or Search',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
