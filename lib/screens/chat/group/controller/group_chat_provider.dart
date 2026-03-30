import 'package:on_peace/screens/chat/group/controller/group_chat_controller.dart';
import 'package:on_peace/screens/chat/group/repository/group_chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final groupChatRepositoryProvider = Provider<GroupChatRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return GroupChatRepository(firestore: firestore);
});

final groupChatControllerProvider = Provider<GroupChatController>((ref) {
  final groupChatRepository = ref.watch(groupChatRepositoryProvider);
  return GroupChatController(
    groupChatRepository: groupChatRepository,
    ref: ref,
  );
});
