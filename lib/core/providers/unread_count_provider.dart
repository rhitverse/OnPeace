import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final unreadChatsCountProvider = StreamProvider<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('Chats')
      .where('participants', arrayContains: uid)
      .where('status', isEqualTo: 'accepted')
      .snapshots()
      .map((snap) {
        int total = 0;
        for (final doc in snap.docs) {
          final data = doc.data();
          final val = data['unreadCount_$uid'];
          if (val != null) {
            total += (val as num).toInt();
          }
        }
        return total;
      });
});

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('notifications')
      .doc(uid)
      .collection('userNotifications')
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snap) => snap.docs.length);
});
