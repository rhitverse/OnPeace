import 'package:on_peace/models/call_model.dart';

class CallState {
  final bool isCallActive;
  final bool isMuted;
  final bool isVideoOn;
  final int? remoteUid;
  final CallModel? incomingCall;
  final String currentCallId;

  const CallState({
    this.isCallActive = false,
    this.isMuted = false,
    this.isVideoOn = true,
    this.remoteUid,
    this.incomingCall,
    this.currentCallId = '',
  });

  CallState copyWith({
    bool? isCallActive,
    bool? isMuted,
    bool? isVideoOn,
    int? remoteUid,
    CallModel? incomingCall,
    String? currentCallId,
    bool clearRemoteUid = false,
    bool clearIncomingCall = false,
  }) {
    return CallState(
      isCallActive: isCallActive ?? this.isCallActive,
      isMuted: isMuted ?? this.isMuted,
      isVideoOn: isVideoOn ?? this.isVideoOn,
      remoteUid: clearRemoteUid ? null : remoteUid ?? this.remoteUid,
      incomingCall: clearIncomingCall
          ? null
          : incomingCall ?? this.incomingCall,
      currentCallId: currentCallId ?? this.currentCallId,
    );
  }
}
