class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String receiverId;
  final bool isVideo;
  final String status;

  CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.isVideo,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'callId': callId,
    'callerId': callerId,
    'callerName': callerName,
    'receiverId': receiverId,
    'isVideo': isVideo,
    'status': status,
    'timestamp': DateTime.now().toIso8601String(),
  };

  factory CallModel.fromMap(Map<String, dynamic> map) => CallModel(
    callId: map['callId'] ?? '',
    callerId: map['callerId'] ?? '',
    callerName: map['callerName'] ?? 'Unknown',
    receiverId: map['receiverId'] ?? '',
    isVideo: map['isVideo'] ?? false,
    status: map['status'] ?? 'ended',
  );
}
