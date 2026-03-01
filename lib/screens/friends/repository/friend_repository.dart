import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRepository {
  final FirebaseFirestore _firestore;
  FriendRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Stream<QuerySnapshot> getFriendsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('Friends')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }

  Future<bool> isFriend(String otherUid) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final docId = '${uid}_$otherUid';
    final doc = await _firestore.collection('Friends').doc(docId).get();
    return doc.exists;
  }

  Future<void> addFriend({
    required String currentUid,
    required String friendUid,
    required String chatId,
  }) async {
    final batch = _firestore.batch();
    final doc1 = _firestore
        .collection('Friends')
        .doc('${currentUid}_$friendUid');
    final doc2 = _firestore
        .collection('Friends')
        .doc('${friendUid}_$currentUid');

    batch.set(doc1, {
      'uid': currentUid,
      'friendUid': friendUid,
      'chatId': chatId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(doc2, {
      'uid': friendUid,
      'friendUid': currentUid,
      'chatId': chatId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> removeFriend({
    required String currentUid,
    required String friendUid,
  }) async {
    final batch = _firestore.batch();
    batch.delete(
      _firestore.collection('Friends').doc('${currentUid}_$friendUid'),
    );
    batch.delete(
      _firestore.collection('Friends').doc('${friendUid}_$currentUid'),
    );
    await batch.commit();
  }

  Future<Map<String, dynamic>?> getFriendData(String friendUid) async {
    try {
      final doc = await _firestore.collection('users').doc(friendUid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Future<int> getFriendCount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    final snap = await _firestore
        .collection('Friends')
        .where('uid', isEqualTo: uid)
        .count()
        .get();
    return snap.count ?? 0;
  }
}
