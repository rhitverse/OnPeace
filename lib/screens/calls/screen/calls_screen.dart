import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/screens/calls/controller/call_provider.dart';

class CallScreen extends ConsumerWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);
    final callNotifier = ref.read(callControllerProvider.notifier);
    final repo = ref.read(callRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (callState.remoteUid != null && callState.isVideoOn)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: repo.agoraEngine,
                  canvas: VideoCanvas(uid: callState.remoteUid),
                  connection: RtcConnection(channelId: callState.currentCallId),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[800],
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      callState.remoteUid == null ? 'Calling...' : 'Video Off',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),

            if (callState.isVideoOn)
              Positioned(
                top: 16,
                right: 16,
                width: 100,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: repo.agoraEngine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon: callState.isMuted ? Icons.mic_off : Icons.mic,
                    color: callState.isMuted ? Colors.red : Colors.white,
                    onTap: () => callNotifier.toggleMute(),
                  ),
                  _CallButton(
                    icon: Icons.call_end,
                    color: Colors.white,
                    backgroundColor: Colors.red,
                    size: 64,
                    onTap: () => callNotifier.endCall(context),
                  ),
                  _CallButton(
                    icon: callState.isVideoOn
                        ? Icons.videocam
                        : Icons.videocam_off,
                    color: callState.isVideoOn ? Colors.white : Colors.red,
                    onTap: () => callNotifier.toggleVideo(),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 16,
              left: 16,
              child: _CallButton(
                icon: Icons.flip_camera_ios,
                color: Colors.white,
                onTap: () => callNotifier.switchCamera(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color backgroundColor;
  final double size;

  const _CallButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.backgroundColor = Colors.white24,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: backgroundColor,
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}
