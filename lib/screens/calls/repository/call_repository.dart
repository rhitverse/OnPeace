import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:whatsapp_clone/models/call_model.dart';
import 'package:whatsapp_clone/secret/secret.dart';

class CallRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String tokenServerUrl = Secrets.tokenServer;

  late RtcEngine agoraEngine;

  Future<String> getAgoraToken({
    required String channelName,
    required int uid,
  }) async {
    try {
      print('Requesting token for channel: $channelName');

      // Get Firebase ID token
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated. Please log in first.');
      }

      print('Current user: ${user.email} (UID: ${user.uid})');
      final firebaseToken = await user.getIdToken();
      if (firebaseToken == null || firebaseToken.isEmpty) {
        throw Exception('Failed to obtain Firebase token');
      }
      final tokenPreview = firebaseToken.substring(
        0,
        firebaseToken.length > 20 ? 20 : firebaseToken.length,
      );
      print('Firebase token obtained: $tokenPreview...');
      print('Token length: ${firebaseToken.length}');

      final response = await http
          .post(
            Uri.parse(tokenServerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'channelName': channelName,
              'uid': uid,
              'role': 'publisher',
              'firebaseToken': firebaseToken,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException(
              'Timeout: Could not reach token server at $tokenServerUrl',
            ),
          );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        print('Token received!');
        return token;
      } else {
        throw Exception('Failed to get token: ${response.body}');
      }
    } catch (e) {
      print('Error getting Agora token: $e');
      rethrow;
    }
  }

  Future<void> iniAgora() async {
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(RtcEngineContext(appId: Secrets.agoraAppId));
    await agoraEngine.enableAudio();
  }

  int _getUidFromUserId(String userId) {
    return userId.hashCode.abs() % 4294967295;
  }

  Future<void> enableVideo(bool enable) async {
    if (enable) {
      await agoraEngine.enableVideo();
    } else {
      await agoraEngine.disableVideo();
    }
  }

  Future<String> startCall({
    required String receiverId,
    required bool isVideo,
  }) async {
    try {
      final currentUser = _auth.currentUser!;
      final uid = _getUidFromUserId(currentUser.uid);
      final channelName =
          'MineChat_call_${DateTime.now().millisecondsSinceEpoch}';

      final agoraToken = await getAgoraToken(
        channelName: channelName,
        uid: uid,
      );
      final call = CallModel(
        callId: channelName,
        callerId: currentUser.uid,
        callerName: currentUser.displayName ?? 'Unknown',
        receiverId: receiverId,
        isVideo: isVideo,
        status: 'ringing',
      );
      await _firestore.collection('calls').doc(channelName).set(call.toMap());
      await agoraEngine.joinChannel(
        token: agoraToken,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      await enableVideo(isVideo);
      print('Call started - Channel: $channelName');
      return channelName;
    } catch (e) {
      print('Error starting call: $e');
      rethrow;
    }
  }

  Future<void> acceptCall(CallModel call) async {
    try {
      final currentUser = _auth.currentUser!;
      final uid = _getUidFromUserId(currentUser.uid);
      final agoraToken = await getAgoraToken(
        channelName: call.callId,
        uid: uid,
      );
      await _firestore.collection('calls').doc(call.callId).update({
        'status': 'accepted',
      });
      await agoraEngine.joinChannel(
        token: agoraToken,
        channelId: call.callId,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      await enableVideo(call.isVideo);
      print('Call accepted - Channel: ${call.callId}');
    } catch (e) {
      print('Error accepting call: $e');
      rethrow;
    }
  }

  Future<void> endCall(String callId) async {
    try {
      await agoraEngine.leaveChannel();
      await _firestore.collection('calls').doc(callId).update({
        'status': 'ended',
      });
      print('Call ended');
    } catch (e) {
      print('Error ending call: $e');
    }
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
}
