import 'package:on_peace/models/call_model.dart';

class CallState {
  final String currentCallId;
  final String? remoteUid;
  final bool isVideoOn;
  final bool isMuted;
  final bool isCallActive;
  final CallModel? incomingCall;
  final String channelName;

  const CallState({
    this.currentCallId = '',
    this.remoteUid,
    this.isVideoOn = false,
    this.isMuted = false,
    this.isCallActive = false,
    this.incomingCall,
    this.channelName = '',
  });

  CallState copyWith({
    String? currentCallId,
    String? remoteUid,
    bool? isVideoOn,
    bool? isMuted,
    bool? isCallActive,
    CallModel? incomingCall,
    String? channelName,
    bool clearRemoteUid = false,
    bool clearIncomingCall = false,
  }) {
    return CallState(
      currentCallId: currentCallId ?? this.currentCallId,
      remoteUid: clearRemoteUid ? null : (remoteUid ?? this.remoteUid),
      isVideoOn: isVideoOn ?? this.isVideoOn,
      isMuted: isMuted ?? this.isMuted,
      isCallActive: isCallActive ?? this.isCallActive,
      incomingCall: clearIncomingCall
          ? null
          : (incomingCall ?? this.incomingCall),
      channelName: channelName ?? this.channelName,
    );
  }
}
