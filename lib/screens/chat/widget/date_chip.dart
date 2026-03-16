import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_clone/colors.dart';

String getSmartDate(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diff = today.difference(msgDay).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat('EEEE').format(dateTime);
  if (diff < 365) return DateFormat('d MMMM').format(dateTime);
  return DateFormat('d MMMM yyyy').format(dateTime);
}

class DateChip extends StatelessWidget {
  final DateTime dateTime;
  const DateChip({super.key, required this.dateTime});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: dateContainerDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          getSmartDate(dateTime),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
