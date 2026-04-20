/*import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/calls/controller/call_provider.dart';

class VoiceCallScreen extends ConsumerStatefulWidget {
  final String remoteUserName;
  final String remoteUserAvatar;

  const VoiceCallScreen({
    super.key,
    required this.remoteUserName,
    required this.remoteUserAvatar,
  });

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen> {
  int _callDuration = 0;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _startCallTimer();
  }

  void _startCallTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _callDuration++);
        _startCallTimer();
      }
    });
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callControllerProvider);
    final callNotifier = ref.read(callControllerProvider.notifier);
    final repo = ref.read(callRepositoryProvider);

    final bool isConnected = callState.remoteUid != null;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade900, Colors.blue.shade700],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // ── Center Content ──
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey,
                        backgroundImage: widget.remoteUserAvatar.isNotEmpty
                            ? NetworkImage(widget.remoteUserAvatar)
                            : null,
                        child: widget.remoteUserAvatar.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 70,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        widget.remoteUserName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: whiteColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isConnected
                            ? _formatDuration(_callDuration)
                            : 'Calling...',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      if (!isConnected) ...[
                        const SizedBox(height: 30),
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation(uiColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Bottom Buttons ──
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute button
                      _buildButton(
                        icon: callState.isMuted ? Icons.mic_off : Icons.mic,
                        color: callState.isMuted
                            ? Colors.red
                            : Colors.grey[700]!,
                        onTap: () => callNotifier.toggleMute(),
                      ),

                      // Speaker button
                      _buildButton(
                        icon: _isSpeakerOn
                            ? Icons.volume_up
                            : Icons.volume_down,
                        color: _isSpeakerOn ? Colors.blue : Colors.grey[700]!,
                        onTap: () async {
                          setState(() => _isSpeakerOn = !_isSpeakerOn);
                          await repo.agoraEngine.setEnableSpeakerphone(
                            _isSpeakerOn,
                          );
                        },
                      ),

                      // End call button
                      _buildButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        onTap: () => callNotifier.endCall(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, color: whiteColor, size: 28),
      ),
    );
  }
}*/
