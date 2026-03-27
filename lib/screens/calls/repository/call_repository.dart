import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_clone/models/call_model.dart';
import 'package:whatsapp_clone/screens/calls/service/zego_engine_service.dart';

class CallRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ZegoEngineService _zegoService;

  CallRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ZegoEngineService? zegoService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _zegoService = zegoService ?? ZegoEngineService();

  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user;
  }

  Future<String> _resolveReceiverName(String receiverId) async {
    try {
      final doc = await _firestore.collection('users').doc(receiverId).get();
      final data = doc.data();
      if (data == null) return 'Unknown';
      return (data['displayname'] ?? data['username'] ?? 'Unknown').toString();
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<CallModel> createOutgoingCall({
    required String receiverId,
    required bool isVideo,
  }) async {
    final currentUser = _currentUser;
    final roomId =
        'call_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}';

    final call = CallModel(
      callId: roomId,
      callerId: currentUser.uid,
      callerName: currentUser.displayName ?? 'Unknown',
      receiverId: receiverId,
      isVideo: isVideo,
      status: 'ringing',
      startTime: DateTime.now(),
    );

    await _firestore.collection('calls').doc(roomId).set(call.toMap());
    return call;
  }

  Stream<CallModel?> listenForIncomingCall(String userId) {
    return _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final docs = snap.docs
              .map((d) => CallModel.fromMap(d.data()))
              .where((c) => c.status == 'ringing')
              .toList();
          if (docs.isEmpty) return null;
          docs.sort((a, b) {
            final aTime = a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return docs.first;
        });
  }

  Stream<CallModel?> watchCallById(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CallModel.fromMap(doc.data()!);
    });
  }

  Future<void> startCallEngine(CallModel call) async {
    final receiverName = await _resolveReceiverName(call.receiverId);
    if (call.isVideo) {
      await _zegoService.startVideoCall(
        roomId: call.callId,
        remoteUserId: call.receiverId,
        remoteUserName: receiverName,
      );
    } else {
      await _zegoService.startVoiceCall(
        roomId: call.callId,
        remoteUserId: call.receiverId,
        remoteUserName: receiverName,
      );
    }
  }

  Future<void> acceptIncomingCall(CallModel call) async {
    await _firestore.collection('calls').doc(call.callId).set({
      'status': 'accepted',
      'acceptedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    if (call.isVideo) {
      await _zegoService.startVideoCall(
        roomId: call.callId,
        remoteUserId: call.callerId,
        remoteUserName: call.callerName,
      );
    } else {
      await _zegoService.startVoiceCall(
        roomId: call.callId,
        remoteUserId: call.callerId,
        remoteUserName: call.callerName,
      );
    }
  }

  Future<void> rejectIncomingCall(CallModel call) async {
    await _firestore.collection('calls').doc(call.callId).set({
      'status': 'rejected',
      'endTime': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> endCall(String callId) async {
    await _zegoService.endCall();
    await _firestore.collection('calls').doc(callId).set({
      'status': 'ended',
      'endTime': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleMute() async {
    await _zegoService.toggleMicrophone();
  }

  Future<void> toggleVideo() async {
    await _zegoService.toggleCamera();
  }

  Future<void> switchCamera() async {
    await _zegoService.switchCamera();
  }

  Future<void> toggleSpeaker() async {
    await _zegoService.toggleSpeaker();
  }

  ZegoEngineService get zegoService => _zegoService;

  Future<void> dispose() async {
    await _zegoService.uninitializeZego();
  }
}
