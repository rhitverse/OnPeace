import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:whatsapp_clone/models/call_model.dart';
import 'package:whatsapp_clone/secret/secret.dart';

class CallRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String tokenServerUrl = Secrets.tokenServer;

  late RtcEngine agoraEngine;

  List<String> _tokenServerCandidates() {
    // Keep Railway first for prod, then fast local fallbacks in debug.
    final endpoints = <String>[
      tokenServerUrl,
      Secrets.tokenServerLocalDeviceLan,
    ];
    if (kDebugMode) {
      endpoints.add(Secrets.tokenServerLocalEmulator);
    }
    return endpoints.toSet().toList();
  }

  Future<String> getAgoraToken({
    required String channelName,
    required int uid,
  }) async {
    Exception? lastError;

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

      for (final endpoint in _tokenServerCandidates()) {
        try {
          print('Trying token endpoint: $endpoint');
          final response = await http
              .post(
                Uri.parse(endpoint),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'channelName': channelName,
                  'uid': uid,
                  'role': 'publisher',
                  'firebaseToken': firebaseToken,
                }),
              )
              .timeout(
                const Duration(seconds: 6),
                onTimeout: () => throw TimeoutException(
                  'Timeout: Could not reach token server at $endpoint',
                ),
              );

          print('Response Status: ${response.statusCode}');
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final token = data['token'];
            if (token == null || token.toString().isEmpty) {
              throw Exception('Empty token from endpoint: $endpoint');
            }
            print('Token received from: $endpoint');
            return token.toString();
          }

          lastError = Exception(
            'Failed token response (${response.statusCode}) from $endpoint: ${response.body}',
          );
          print(lastError);
        } catch (e) {
          lastError = Exception('Endpoint failed ($endpoint): $e');
          print(lastError);
        }
      }

      throw lastError ??
          Exception(
            'All token endpoints failed. Make sure token server is running and phone/emulator can reach it.',
          );
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
    return userId.hashCode.abs() % 2147483647;
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

      await agoraEngine.joinChannel(
        token: agoraToken,
        channelId: call.callId,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      await _firestore.collection('calls').doc(call.callId).update({
        'status': 'accepted',
      });

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
