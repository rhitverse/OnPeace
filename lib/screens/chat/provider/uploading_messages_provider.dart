import 'package:flutter_riverpod/flutter_riverpod.dart';

class UploadingMessage {
  final String tempId;
  final String localFilePath;
  final String mediaType;
  final String? fileName;
  final int? fileSize;
  final int? duration;

  const UploadingMessage({
    required this.tempId,
    required this.localFilePath,
    required this.mediaType,
    this.fileName,
    this.fileSize,
    this.duration,
  });
}

final uploadingMessagesProvider =
    StateNotifierProvider<UploadingMessagesNotifier, List<UploadingMessage>>(
      (ref) => UploadingMessagesNotifier(),
    );

class UploadingMessagesNotifier extends StateNotifier<List<UploadingMessage>> {
  UploadingMessagesNotifier() : super([]);

  void add(UploadingMessage msg) => state = [...state, msg];

  void remove(String tempId) =>
      state = state.where((m) => m.tempId != tempId).toList();

  void addUploading(String id) {}
  void removeUploading(String id) {}
  bool isUploading(String id) => false;

  void clearAll() => state = [];
}
