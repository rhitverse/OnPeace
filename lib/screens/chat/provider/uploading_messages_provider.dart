import 'package:flutter_riverpod/flutter_riverpod.dart';

final uploadingMessagesProvider =
    StateNotifierProvider<UploadingMessagesNotifier, Set<String>>((ref) {
      return UploadingMessagesNotifier();
    });

class UploadingMessagesNotifier extends StateNotifier<Set<String>> {
  UploadingMessagesNotifier() : super({});

  void addUploading(String messageId) {
    state = {...state, messageId};
  }

  void removeUploading(String messageId) {
    state = state.where((id) => id != messageId).toSet();
  }

  bool isUploading(String messageId) {
    return state.contains(messageId);
  }

  void clearAll() {
    state = {};
  }
}
