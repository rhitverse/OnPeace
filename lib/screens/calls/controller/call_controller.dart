import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/common/utils/navigator_key.dart';
import 'package:whatsapp_clone/models/call_state.dart';
import 'package:whatsapp_clone/screens/calls/repository/call_repository.dart';
import 'package:whatsapp_clone/screens/calls/screen/incoming_call_screen.dart';
import 'package:whatsapp_clone/screens/calls/screen/calls_screen.dart';
import 'package:whatsapp_clone/widgets/helpful_widgets/custom_messenger.dart';

final callRepositoryProvider = Provider((ref) => CallRepository());

final callControllerProvider = StateNotifierProvider<CallController, CallState>(
  (ref) {
    final repository = ref.watch(callRepositoryProvider);
    return CallController(repo: repository, ref: ref);
  },
);

class CallController extends StateNotifier<CallState> {
  final CallRepository _repo;
  StreamSubscription? _incomingCallSub;
  bool _isStartingCall = false;
  bool _isAcceptingCall = false;
  bool _isIncomingUiOpen = false;

  CallController({required CallRepository repo, required Ref ref})
    : _repo = repo,
      super(const CallState()) {
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    try {
      await _initAgora();
      _listenIncomingCalls();
    } catch (e) {
      print('❌ Failed to initialize Agora: $e');
    }
  }

  RtcEngine get agoraEngine => _repo.agoraEngine;

  Future<void> _initAgora() async {
    try {
      await _repo.iniAgora();
      _repo.agoraEngine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            print('✅ Joined channel successfully');
            state = state.copyWith(isCallActive: true);
          },
          onUserJoined: (connection, uid, elapsed) {
            print('✅ Remote user joined - UID: $uid');
            state = state.copyWith(remoteUid: uid.toString());
          },
          onUserOffline: (connection, uid, reason) {
            print('❌ Remote user offline - UID: $uid');
            state = state.copyWith(clearRemoteUid: true);
            endCall(null);
          },
          onLeaveChannel: (connection, stats) {
            print('✅ Left channel');
            state = state.copyWith(isCallActive: false);
          },
          onError: (ErrorCodeType err, String msg) {
            print('❌ Agora Error: $err - $msg');
          },
        ),
      );
    } catch (e) {
      print('❌ Error initializing Agora: $e');
    }
  }

  void _listenIncomingCalls() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) return;
      _incomingCallSub?.cancel();
      _incomingCallSub = _repo.listenForIncomingCall(user.uid).listen((call) {
        if (call != null) {
          print('Incoming call from: ${call.callerName}');
          state = state.copyWith(incomingCall: call);

          if (!_isIncomingUiOpen) {
            _isIncomingUiOpen = true;
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                settings: const RouteSettings(name: 'incoming-call-screen'),
                builder: (_) => const IncomingCallScreen(),
              ),
            );
          }
        } else {
          if (state.incomingCall != null) {
            state = state.copyWith(clearIncomingCall: true);
          }
          _isIncomingUiOpen = false;
        }
      });
    });
  }

  Future<void> startCall({
    required String receiverId,
    required bool isVideo,
    required BuildContext context,
  }) async {
    if (_isStartingCall) {
      print(
        'Ignoring duplicate startCall while previous request is in progress',
      );
      return;
    }

    _isStartingCall = true;
    try {
      print('Starting call to: $receiverId');

      final channelName = await _repo.startCall(
        receiverId: receiverId,
        isVideo: isVideo,
      );
      state = state.copyWith(
        isVideoOn: isVideo,
        channelName: channelName,
        currentCallId: channelName,
      );

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'call-screen'),
          builder: (_) => const CallsScreen(),
        ),
      );
      print('Call started successfully');
    } catch (e) {
      print('Error starting call: $e');
      if (context.mounted) {
        CustomMessenger.show(context, 'Error starting call: $e');
      }
      rethrow;
    } finally {
      _isStartingCall = false;
    }
  }

  Future<void> acceptCall(BuildContext context) async {
    if (_isAcceptingCall) {
      print(
        'Ignoring duplicate acceptCall while previous request is in progress',
      );
      return;
    }

    _isAcceptingCall = true;
    try {
      if (state.incomingCall == null) {
        print('No incoming call to accept');
        return;
      }

      final call = state.incomingCall!;
      print('Accepting call from: ${call.callerName}');

      if (_isIncomingUiOpen) {
        navigatorKey.currentState?.pop();
        _isIncomingUiOpen = false;
      }

      state = state.copyWith(isVideoOn: call.isVideo, channelName: call.callId);
      await _repo.acceptCall(call);
      state = state.copyWith(
        currentCallId: call.callId,
        channelName: call.callId,
        clearIncomingCall: true,
      );

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'call-screen'),
          builder: (_) => const CallsScreen(),
        ),
      );
      print('Call accepted successfully');
    } catch (e) {
      print('Error accepting call: $e');
      state = state.copyWith(clearIncomingCall: true);
      if (context.mounted) {
        CustomMessenger.show(context, 'Error accepting call: $e');
      }
    } finally {
      _isAcceptingCall = false;
    }
  }

  void rejectCall(BuildContext context) {
    try {
      if (state.incomingCall == null) return;
      print('Call rejected');
      state = state.copyWith(clearIncomingCall: true);
      if (_isIncomingUiOpen) {
        navigatorKey.currentState?.pop();
        _isIncomingUiOpen = false;
      }
      CustomMessenger.show(context, 'Call rejected');
    } catch (e) {
      print('Error rejecting call: $e');
    }
  }

  Future<void> endCall(BuildContext? context) async {
    try {
      if (state.currentCallId.isEmpty) {
        print('No active call to end');
        state = state.copyWith(clearIncomingCall: true);
        _isIncomingUiOpen = false;
        return;
      }
      print('Ending call: ${state.currentCallId}');
      await _repo.endCall(state.currentCallId);
      state = const CallState();

      if (context != null && context.mounted) {
        navigatorKey.currentState?.pop();
      }

      print('call ended Successfully');
    } catch (e) {
      print('Error ending call: $e');
      if (context != null && context.mounted) {
        CustomMessenger.show(context, 'Error ending call: $e');
      }
    }
  }

  Future<void> toggleMute() async {
    try {
      final newMuteState = !state.isMuted;
      await _repo.muteAudio(newMuteState);
      state = state.copyWith(isMuted: newMuteState);
      print('${newMuteState ? '🔇' : '🔊'} Audio muted: $newMuteState');
    } catch (e) {
      print('Error toggling mute: $e');
    }
  }

  Future<void> toggleVideo() async {
    try {
      final newVideoState = !state.isVideoOn;
      await _repo.enableVideo(newVideoState);
      state = state.copyWith(isVideoOn: newVideoState);
      print(
        '${newVideoState ? 'videoDisable' : 'videoEnable'} Video enable: $newVideoState',
      );
    } catch (e) {
      print('❌ Error toggling video: $e');
    }
  }

  Future<void> switchCamera() async {
    try {
      await _repo.switchCamera();
      print('Camera switched');
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  @override
  Future<void> dispose() async {
    print('Disposing CallController');
    await _incomingCallSub?.cancel();
    await _repo.dispose();
    super.dispose();
  }
}
