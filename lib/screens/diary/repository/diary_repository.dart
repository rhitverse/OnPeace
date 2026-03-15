import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_clone/models/diary_model.dart';

class DiaryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;
  CollectionReference get _diaryRef =>
      _firestore.collection('users').doc(_uid).collection('diary');

  static const _monthNames = [
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
  static const _weekdays = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Future<void> addEntry(
    String text, {
    int weatherIndex = 0,
    int moodIndex = 0,
  }) async {
    final now = DateTime.now();
    await _diaryRef.add({
      'text': text,
      'day': now.day.toString(),
      'month': _monthNames[now.month],
      'weekday': _weekdays[now.weekday],
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'createdAt': Timestamp.fromDate(now),
      'weatherIndex': weatherIndex,
      'moodIndex': moodIndex,
    });
  }

  Stream<List<DiaryModel>> getEntriesStream() {
    return _diaryRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => DiaryModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Future<void> updateEntry(String entryId, String newText) async {
    await _diaryRef.doc(entryId).update({'text': newText});
  }

  Future<void> deleteEntry(String entryId) async {
    await _diaryRef.doc(entryId).delete();
  }
}
