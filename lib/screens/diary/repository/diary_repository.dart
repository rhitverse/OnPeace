import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_clone/models/diary_model.dart';

class DiaryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;
  CollectionReference get _diaryRef =>
      _firestore.collection('users').doc(_uid).collection('diary');

  Future<void> addEntry(String text) async {
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
    await _diaryRef.add({
      'text': text,
      'day': now.day.toString(),
      'month': monthNames[now.month],
      'weekday': weekdays[now.weekday],
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
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
