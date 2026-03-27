import 'package:cloud_firestore/cloud_firestore.dart';

class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String receiverId;
  final bool isVideo;
  final String status;
  final DateTime? startTime;
  final DateTime? endTime;

  CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.isVideo,
    required this.status,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() => {
    'callId': callId,
    'callerId': callerId,
    'callerName': callerName,
    'receiverId': receiverId,
    'isVideo': isVideo,
    'status': status,
    'startTime':
        startTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'timestamp': FieldValue.serverTimestamp(),
  };

  factory CallModel.fromMap(Map<String, dynamic> map) => CallModel(
    callId: map['callId'] ?? '',
    callerId: map['callerId'] ?? '',
    callerName: map['callerName'] ?? 'Unknown',
    receiverId: map['receiverId'] ?? '',
    isVideo: map['isVideo'] ?? false,
    status: map['status'] ?? 'ended',
    startTime: map['startTime'] != null
        ? DateTime.parse(map['startTime'])
        : null,
    endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
  );
}
