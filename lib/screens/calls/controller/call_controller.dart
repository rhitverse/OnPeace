import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/common/utils/navigator_key.dart';
import 'package:whatsapp_clone/models/call_model.dart';
import 'package:whatsapp_clone/models/call_state.dart';
import 'package:whatsapp_clone/screens/calls/repository/call_repository.dart';
import 'package:whatsapp_clone/screens/calls/screen/calls_screen.dart';

class CallController extends StateNotifier<CallState> {
  final CallRepository _repo;
  StreamSubscription<CallModel?>? _incomingCallSub;
  StreamSubscription<CallModel?>? _activeCallSub;
  bool _isBusy = false;

  CallController({required CallRepository repo, required Ref ref})
    : _repo = repo,
      super(const CallState()) {
    _listenIncomingCalls();
  }

  void _listenIncomingCalls() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _incomingCallSub?.cancel();
    _incomingCallSub = _repo.listenForIncomingCall(user.uid).listen((call) {
      if (call == null) {
        if (state.incomingCall != null) {
          state = state.copyWith(clearIncomingCall: true);
        }
        return;
      }

      if (state.currentCallId == call.callId) {
        return;
      }

      state = state.copyWith(incomingCall: call);
    });
  }

  void _watchActiveCallStatus(String callId) {
    _activeCallSub?.cancel();
    _activeCallSub = _repo.watchCallById(callId).listen((call) {
      if (call == null) return;

      if (call.status == 'ended' || call.status == 'rejected') {
        state = const CallState();

        final context = navigatorKey.currentContext;
        if (context != null && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  Future<void> startCall({
    required String receiverId,
    required bool isVideo,
    required BuildContext context,
  }) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      final call = await _repo.createOutgoingCall(
        receiverId: receiverId,
        isVideo: isVideo,
      );

      try {
        await _repo.startCallEngine(call);
      } catch (e) {
        debugPrint('Error starting call engine: $e');
        // Clean up the call record
        await _repo.rejectIncomingCall(call);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start call: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        rethrow;
      }

      state = state.copyWith(
        currentCallId: call.callId,
        channelName: call.callId,
        isVideoOn: isVideo,
        isCallActive: true,
        remoteUid: call.receiverId,
      );

      _watchActiveCallStatus(call.callId);

      final navState = navigatorKey.currentState;
      if (navState != null) {
        navState.push(
          MaterialPageRoute(builder: (_) => CallsScreen(call: call)),
        );
      } else if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CallsScreen(call: call)),
        );
      }
    } catch (e) {
      debugPrint('Error starting call: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isBusy = false;
    }
  }

  Future<void> acceptCall(BuildContext context) async {
    final call = state.incomingCall;
    if (call == null || _isBusy) return;
    _isBusy = true;

    try {
      await _repo.acceptIncomingCall(call);

      state = state.copyWith(
        clearIncomingCall: true,
        currentCallId: call.callId,
        channelName: call.callId,
        isVideoOn: call.isVideo,
        isCallActive: true,
        remoteUid: call.callerId,
      );

      _watchActiveCallStatus(call.callId);

      final navState = navigatorKey.currentState;
      if (navState != null) {
        navState.push(
          MaterialPageRoute(builder: (_) => CallsScreen(call: call)),
        );
      } else if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CallsScreen(call: call)),
        );
      }
    } catch (e) {
      debugPrint('Error accepting call: $e');

      // Mark call as rejected if acceptance failed
      try {
        await _repo.rejectIncomingCall(call);
      } catch (_) {}

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept call: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      state = state.copyWith(clearIncomingCall: true);
    } finally {
      _isBusy = false;
    }
  }

  Future<void> rejectCall() async {
    final call = state.incomingCall;
    if (call == null) return;
    await _repo.rejectIncomingCall(call);
    state = state.copyWith(clearIncomingCall: true);
  }

  Future<void> endCall([BuildContext? context]) async {
    if (state.currentCallId.isEmpty) return;

    try {
      await _repo.endCall(state.currentCallId);
      _activeCallSub?.cancel();
      state = const CallState();

      if (context != null && context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error ending call: $e');
    }
  }

  Future<void> toggleMute() async {
    await _repo.toggleMute();
    state = state.copyWith(isMuted: !state.isMuted);
  }

  Future<void> toggleVideo() async {
    await _repo.toggleVideo();
    state = state.copyWith(isVideoOn: !state.isVideoOn);
  }

  Future<void> switchCamera() async {
    await _repo.switchCamera();
  }

  Future<void> toggleSpeaker() async {
    await _repo.toggleSpeaker();
  }

  CallRepository get repository => _repo;

  @override
  Future<void> dispose() async {
    await _incomingCallSub?.cancel();
    await _activeCallSub?.cancel();
    await _repo.dispose();
    super.dispose();
  }
}
