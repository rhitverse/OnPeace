import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/screens/calls/controller/call_controller.dart';

class CallsScreen extends ConsumerStatefulWidget {
  const CallsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen> {
  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callControllerProvider);
    final callNotifier = ref.read(callControllerProvider.notifier);

    // Check if Agora engine is ready
    if (callNotifier.agoraEngine == null || !callState.isCallActive) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Initializing call...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ LOCAL VIDEO
          if (callState.isVideoOn)
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: callNotifier.agoraEngine,
                canvas: const VideoCanvas(uid: 0),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Video Off',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),

          // ✅ REMOTE VIDEO (small)
          if (callState.remoteUid != null &&
              callState.isVideoOn &&
              callState.channelName.isNotEmpty)
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white),
                ),
                child: AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: callNotifier.agoraEngine,
                    canvas: VideoCanvas(uid: int.parse(callState.remoteUid!)),
                    connection: RtcConnection(channelId: callState.channelName),
                  ),
                ),
              ),
            ),

          // ✅ CALL CONTROLS (Bottom)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute Button
                FloatingActionButton(
                  onPressed: () => callNotifier.toggleMute(),
                  backgroundColor: callState.isMuted
                      ? Colors.red
                      : Colors.grey[700],
                  child: Icon(
                    callState.isMuted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                ),

                // Video Button
                FloatingActionButton(
                  onPressed: () => callNotifier.toggleVideo(),
                  backgroundColor: callState.isVideoOn
                      ? Colors.grey[700]
                      : Colors.red,
                  child: Icon(
                    callState.isVideoOn ? Icons.videocam : Icons.videocam_off,
                    color: Colors.white,
                  ),
                ),

                // Switch Camera Button
                FloatingActionButton(
                  onPressed: () => callNotifier.switchCamera(),
                  backgroundColor: Colors.grey[700],
                  child: const Icon(Icons.flip_camera_ios, color: Colors.white),
                ),

                // End Call Button
                FloatingActionButton(
                  onPressed: () => callNotifier.endCall(context),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
