import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/screens/friends/repository/friend_repository.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository(firestore: FirebaseFirestore.instance);
});

final friendsStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  return ref.watch(friendRepositoryProvider).getFriendsStream();
});

final friendsCountProvider = FutureProvider<int>((ref) {
  return ref.watch(friendRepositoryProvider).getFriendCount();
});

final isFriendProvider = FutureProvider.family<bool, String>((ref, otherUid) {
  return ref.watch(friendRepositoryProvider).isFriend(otherUid);
});

class FriendController extends StateNotifier<AsyncValue<void>> {
  final FriendRepository _repo;

  FriendController({required FriendRepository repo})
    : _repo = repo,
      super(const AsyncValue.data(null));

  Future<void> addFriend({
    required String currentUid,
    required String friendUid,
    required String chatId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addFriend(
        currentUid: currentUid,
        friendUid: friendUid,
        chatId: chatId,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeFriend({
    required String currentUid,
    required String friendUid,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.removeFriend(currentUid: currentUid, friendUid: friendUid);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final friendControllerProvider =
    StateNotifierProvider<FriendController, AsyncValue<void>>((ref) {
      return FriendController(repo: ref.watch(friendRepositoryProvider));
    });
