/*import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_clone/models/call_model.dart';
import 'package:whatsapp_clone/secret/secret.dart';

class CallRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late RtcEngine agoraEngine;
  static const String appId = Secrets.agoraAppId;

  Future<void> initAgora() async {
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(RtcEngineContext(appId: appId));
    await agoraEngine.enableAudio();
  }

  int _getUidFromUserId(String userId) {
    return userId.hashCode.abs() %
        4294967295; // Ensure positive int and within Agora UID range
  }

  Future<void> enableVideo(bool enable) async {
    if (enable) {
      await agoraEngine.enableVideo();
    } else {
      await agoraEngine.disableVideo();
    }
  }

  static const String _tempToken = Secrets.tempToken;
  static const String _testChannel = 'test';

  Future<String> startCall({
    required String receiverId,
    required bool isVideo,
  }) async {
    final currentUser = _auth.currentUser!;
    final callId = _testChannel;

    final call = CallModel(
      callId: callId,
      callerId: currentUser.uid,
      callerName: currentUser.displayName ?? 'Unknown',
      receiverId: receiverId,
      isVideo: isVideo,
      status: 'ringing',
    );
    await _firestore.collection('calls').doc(callId).set(call.toMap());

    final uid = _getUidFromUserId(currentUser.uid);
    await agoraEngine.joinChannel(
      token: _tempToken,
      channelId: callId,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    return callId;
  }

  Future<void> acceptCall(CallModel call) async {
    await _firestore.collection('calls').doc(call.callId).update({
      'status': 'accepted',
    });
    final currentUser = _auth.currentUser!;
    final uid = _getUidFromUserId(currentUser.uid);
    await agoraEngine.joinChannel(
      token: _tempToken,
      channelId: call.callId,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> endCall(String callId) async {
    await agoraEngine.leaveChannel();
    await _firestore.collection('calls').doc(callId).update({
      'status': 'ended',
    });
  }

  Stream<CallModel?> listenForIncomingCall(String userId) {
    return _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return CallModel.fromMap(snap.docs.first.data());
        });
  }

  Future<void> muteAudio(bool mute) async {
    await agoraEngine.muteLocalAudioStream(mute);
  }

  Future<void> switchCamera() async {
    await agoraEngine.switchCamera();
  }

  Future<void> dispose() async {
    await agoraEngine.leaveChannel();
    await agoraEngine.release();
  }
}*/
