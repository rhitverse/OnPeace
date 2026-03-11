import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';
import 'diary_data.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

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

class DiaryCard extends StatelessWidget {
  final String month, day, weekday, time, text;
  final bool showCloudIcon;
  const DiaryCard({
    super.key,
    required this.month,
    required this.day,
    required this.weekday,
    required this.time,
    required this.text,
    this.showCloudIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                    height: 1.1,
                  ),
                ),
                Text(
                  weekday,
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade300),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 60, color: Colors.blue.shade100),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade300,
                      ),
                    ),
                    if (showCloudIcon)
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.grey,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
