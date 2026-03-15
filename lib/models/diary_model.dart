import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryModel {
  final String id;
  final String text;
  final String day;
  final String month;
  final String weekday;
  final String time;
  final DateTime createdAt;
  final int weatherIndex;
  final int moodIndex;

  DiaryModel({
    required this.id,
    required this.text,
    required this.day,
    required this.month,
    required this.weekday,
    required this.time,
    required this.createdAt,
    this.weatherIndex = 0,
    this.moodIndex = 0,
  });

  factory DiaryModel.fromMap(String id, Map<String, dynamic> map) {
    return DiaryModel(
      id: id,
      text: map['text'] ?? '',
      day: map['day'] ?? '',
      month: map['month'] ?? '',
      weekday: map['weekday'] ?? '',
      time: map['time'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weatherIndex: map['weatherIndex'] ?? 0,
      moodIndex: map['moodIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    final monthNames = [
      '',
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final weekdays = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return {
      'text': text,
      'day': now.day.toString(),
      'month': monthNames[now.month],
      'weekday': weekdays[now.weekday],
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'createdAt': Timestamp.fromDate(now),
      'weatherIndex': weatherIndex,
      'moodIndex': moodIndex,
    };
  }
}
