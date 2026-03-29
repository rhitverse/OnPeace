import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:on_peace/screens/Notifications/repository/notification_repository.dart';

final notificationRepostitoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(firestore: FirebaseFirestore.instance);
});

final notificationsStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  return ref.watch(notificationRepostitoryProvider).getNotificationsStream();
});

final unreadNotifCountProvider = StreamProvider<int>((ref) {
  return ref.watch(notificationRepostitoryProvider).getUnreadCountStream();
});

class NotificationController extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repo;

  NotificationController({
    required NotificationRepository repo,
    required Ref ref,
  }) : _repo = repo,
       super(const AsyncValue.data(null));

  Future<void> markAsRead(String notifId) async {
    await _repo.markAsRead(notifId);
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      await _repo.markAllAsRead();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteNotification(String notifId) async {
    await _repo.deleteNotification(notifId);
  }

  Future<void> acceptFriendRequest({
    required String currentUid,
    required String fromUid,
    required String chatId,
    required String notifId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .get();
      final myName = myDoc.data()?['displayname'] ?? 'Someone';
      await _repo.acceptFriendRequest(
        currentUid: currentUid,
        fromUid: fromUid,
        chatId: chatId,
        notifId: notifId,
        myName: myName,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> ignoreFriendRequest({
    required String currentUid,
    required String chatId,
    required String notifId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.ignoreFriendRequest(
        currentUid: currentUid,
        chatId: chatId,
        notifId: notifId,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendNotification({
    required String toUid,
    required String type,
    required String fromUid,
    required String fromName,
    required String chatId,
  }) async {
    await _repo.sendNotification(
      toUid: toUid,
      type: type,
      fromUid: fromUid,
      fromName: fromName,
      chatId: chatId,
    );
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
      return NotificationController(
        repo: ref.watch(notificationRepostitoryProvider),
        ref: ref,
      );
    });
