import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;
  Stream<QuerySnapshot> getNotificationsStream() {
    return FirebaseAuth.instance.authStateChanges().switchMap((user) {
      if (user == null) return const Stream.empty();

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots();
    });
  }

  Stream<int> getUnreadCountStream() {
    return FirebaseAuth.instance.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value(0);

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snap) => snap.docs.length);
    });
  }

  Future<void> sendNotification({
    required String toUid,
    required String type,
    required String fromUid,
    required String fromName,
    required String chatId,
  }) async {
    await _firestore
        .collection('users')
        .doc(toUid)
        .collection('notifications')
        .add({
          'type': type,
          'fromUid': fromUid,
          'fromName': fromName,
          'chatId': chatId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
  }

  Future<void> markAsRead(String notifId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .set({'isRead': true}, SetOptions(merge: true))
        .catchError((_) {});
  }

  Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notifId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .delete();
  }

  Future<void> deleteDuplicateAccepted({
    required String toUid,
    required String chatId,
  }) async {
    final existing = await _firestore
        .collection('users')
        .doc(toUid)
        .collection('notifications')
        .where('type', isEqualTo: 'friend_request_accepted')
        .where('chatId', isEqualTo: chatId)
        .get();

    for (final doc in existing.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> acceptFriendRequest({
    required String currentUid,
    required String fromUid,
    required String chatId,
    required String notifId,
    required String myName,
  }) async {
    await _firestore.collection('Chats').doc(chatId).set({
      'participants': [currentUid, fromUid],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
      'unreadCount_$currentUid': 0,
      'unreadCount_$fromUid': 0,
      'status': 'accepted',
    }, SetOptions(merge: true));

    final batch = _firestore.batch();
    batch.set(_firestore.collection('Friends').doc('${currentUid}_$fromUid'), {
      'uid': currentUid,
      'friendUid': fromUid,
      'chatId': chatId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection('Friends').doc('${fromUid}_$currentUid'), {
      'uid': fromUid,
      'friendUid': currentUid,
      'chatId': chatId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await deleteDuplicateAccepted(toUid: fromUid, chatId: chatId);

    await sendNotification(
      toUid: fromUid,
      type: 'friend_request_accepted',
      fromUid: currentUid,
      fromName: myName,
      chatId: chatId,
    );

    await deleteNotification(notifId);
  }

  Future<void> ignoreFriendRequest({
    required String currentUid,
    required String chatId,
    required String notifId,
  }) async {
    await _firestore.collection('Chats').doc(chatId).delete();
    await deleteNotification(notifId);
  }
}
