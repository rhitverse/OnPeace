import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/diary/screen/diary_data.dart';
import 'package:whatsapp_clone/screens/diary/screen/entry_screen.dart';

class DiaryTabScreen extends StatelessWidget {
  const DiaryTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: diaryEntries.length,
            itemBuilder: (context, index) {
              final e = diaryEntries[index];
              return DiaryCard(
                month: e["month"]!,
                day: e["day"]!,
                weekday: e["weekday"]!,
                time: e["time"]!,
                text: e["text"]!,
              );
            },
          ),
        ),
        _BottomBar(count: diaryEntries.length),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int count;
  const _BottomBar({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      color: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.edit, color: whiteColor, size: 24),
          Text(
            "$count diary",
            style: const TextStyle(
              color: whiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
