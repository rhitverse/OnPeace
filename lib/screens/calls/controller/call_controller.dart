import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/common/utils/navigator_key.dart';
import 'package:on_peace/models/call_state.dart';
import 'package:on_peace/screens/calls/repository/call_repository.dart';
import 'package:on_peace/screens/calls/screen/calls_screen.dart';

class CallController extends StateNotifier<CallState> {
  final CallRepository _repo;
  StreamSubscription? _incomingCallSub;

  CallController({required CallRepository repo, required Ref ref})
    : _repo = repo,
      super(const CallState()) {
    _initAgora();
    _listenIncomingCalls();
  }

  Future<void> _initAgora() async {
    await _repo.initAgora();
    _repo.agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          state = state.copyWith(isCallActive: true);
        },
        onUserJoined: (connection, uid, elapsed) {
          state = state.copyWith(remoteUid: uid);
        },
        onUserOffline: (connection, uid, reason) {
          state = state.copyWith(clearRemoteUid: true);
          endCall(null);
        },
        onLeaveChannel: (connection, stats) {
          state = state.copyWith(isCallActive: false);
        },
      ),
    );
  }

  void _listenIncomingCalls() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) return;

      _incomingCallSub?.cancel();
      _incomingCallSub = _repo.listenForIncomingCall(user.uid).listen((call) {
        if (call != null) {
          state = state.copyWith(incomingCall: call);
        }
      });
    });
  }

  Future<void> startCall({
    required String receiverId,
    required bool isVideo,
    required BuildContext context,
  }) async {
    final callId = await _repo.startCall(
      receiverId: receiverId,
      isVideo: isVideo,
    );
    state = state.copyWith(currentCallId: callId, isVideoOn: isVideo);
    await _repo.enableVideo(isVideo);

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'call-screen'), // ✅ naam do
        builder: (_) => const CallScreen(),
      ),
    );
  }

  Future<void> acceptCall() async {
    if (state.incomingCall == null) return;
    final call = state.incomingCall!;

    state = state.copyWith(isVideoOn: call.isVideo, clearIncomingCall: true);
    await _repo.enableVideo(call.isVideo);
    await _repo.acceptCall(call);
    state = state.copyWith(currentCallId: call.callId);

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'call-screen'),
        builder: (_) => const CallScreen(),
      ),
    );
  }

  Future<void> endCall(BuildContext? context) async {
    if (state.currentCallId.isEmpty) {
      state = state.copyWith(clearIncomingCall: true);
      return;
    }

    await _repo.endCall(state.currentCallId);
    state = state.copyWith(
      isCallActive: false,
      clearRemoteUid: true,
      clearIncomingCall: true,
      currentCallId: '',
    );

    navigatorKey.currentState?.popUntil(
      (route) => route.settings.name != 'call-screen',
    );
  }

  Future<void> toggleMute() async {
    state = state.copyWith(isMuted: !state.isMuted);
    await _repo.muteAudio(state.isMuted);
  }

  Future<void> toggleVideo() async {
    state = state.copyWith(isVideoOn: !state.isVideoOn);
    await _repo.enableVideo(state.isVideoOn);
  }

  Future<void> switchCamera() async {
    await _repo.switchCamera();
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    _repo.dispose();
    super.dispose();
  }
}
