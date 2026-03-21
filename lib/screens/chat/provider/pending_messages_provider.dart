import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingMessage {
  final String tempId;
  final String text;
  final String senderId;
  final DateTime sentTime;
  final String status; // 'sending', 'sent', 'failed'
  final String? mediaUrl;
  final String? mediaType;
  final String? fileName;
  final int? fileSize;
  final int? duration;
  final String? localFilePath; // For local file preview

  const PendingMessage({
    required this.tempId,
    required this.text,
    required this.senderId,
    required this.sentTime,
    this.status = 'sending',
    this.mediaUrl,
    this.mediaType,
    this.fileName,
    this.fileSize,
    this.duration,
    this.localFilePath,
  });

  PendingMessage copyWith({
    String? tempId,
    String? text,
    String? senderId,
    DateTime? sentTime,
    String? status,
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    int? fileSize,
    int? duration,
    String? localFilePath,
  }) {
    return PendingMessage(
      tempId: tempId ?? this.tempId,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      sentTime: sentTime ?? this.sentTime,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}

final pendingMessagesProvider =
    StateNotifierProvider<PendingMessagesNotifier, List<PendingMessage>>(
      (ref) => PendingMessagesNotifier(),
    );

class PendingMessagesNotifier extends StateNotifier<List<PendingMessage>> {
  PendingMessagesNotifier() : super([]);

  void addPending(PendingMessage msg) => state = [...state, msg];

  void updateStatus(String tempId, String status) {
    state = [
      for (final msg in state)
        if (msg.tempId == tempId) msg.copyWith(status: status) else msg,
    ];
  }

  void removePending(String tempId) =>
      state = state.where((m) => m.tempId != tempId).toList();

  void clearForChat(String chatId) => state = [];
}
