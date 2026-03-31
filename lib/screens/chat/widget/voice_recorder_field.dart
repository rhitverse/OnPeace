import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/chat/provider/chat_provider.dart';

class VoiceRecorderField extends ConsumerStatefulWidget {
  final String chatId;
  final String receiverUid;
  final bool isGroupChat;
  final VoidCallback onRecordingDone;

  const VoiceRecorderField({
    super.key,
    required this.chatId,
    required this.receiverUid,
    this.isGroupChat = false,
    required this.onRecordingDone,
  });

  @override
  ConsumerState<VoiceRecorderField> createState() => _VoiceRecorderFieldState();
}

class _VoiceRecorderFieldState extends ConsumerState<VoiceRecorderField>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordedFilePath;
  Duration _recordDuration = Duration.zero;
  final List<double> _waveformBars = List.generate(40, (i) => 0.08);
  int _waveIndex = 0;
  bool _isRecording = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
    });
  }

  Future<void> _startRecording() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      widget.onRecordingDone();
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );

    setState(() {
      _recordedFilePath = path;
      _recordDuration = Duration.zero;
      _isRecording = true;
    });

    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return false;

      final isRecording = await _audioRecorder.isRecording();
      if (!isRecording) return false;

      final amplitude = await _audioRecorder.getAmplitude();
      final normalized = ((amplitude.current + 60) / 60).clamp(0.05, 1.0);

      if (mounted) {
        setState(() {
          _recordDuration += const Duration(milliseconds: 100);
          _waveformBars[_waveIndex % _waveformBars.length] = normalized;
          _waveIndex++;
        });
      }
      return true;
    });
  }

  Future<void> _resetRecording() async {
    await _audioRecorder.cancel();
    setState(() {
      _isRecording = false;
      _recordedFilePath = null;
      _recordDuration = Duration.zero;
      _waveIndex = 0;
      _waveformBars.fillRange(0, _waveformBars.length, 0.8);
    });
  }

  Future<void> _sendVoiceMessage() async {
    final path = _recordedFilePath;
    if (path == null) return;

    await _audioRecorder.stop();

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      widget.onRecordingDone();
      return;
    }

    widget.onRecordingDone();

    try {
      await ref
          .read(chatControllerProvider)
          .sendFile(
            chatId: widget.chatId,
            senderId: currentUid,
            file: File(path),
            receiverId: widget.receiverUid,
            fileType: 'audio',
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send voice message')),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  void dispose() {
    _slideController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: backgroundColor),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isRecording ? null : _startRecording,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFF2A2A2A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[800]!, width: 1.6),
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: _isRecording ? uiColor : Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isRecording
                    ? _formatDuration(_recordDuration)
                    : 'Tap to record',
                style: TextStyle(
                  color: _isRecording ? Colors.white70 : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              if (_isRecording)
                SizedBox(
                  height: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(_waveformBars.length, (i) {
                      final barIndex =
                          (_waveIndex - _waveformBars.length + i) %
                          _waveformBars.length;
                      final h =
                          (_waveformBars[barIndex.abs() %
                                      _waveformBars.length] *
                                  32)
                              .clamp(3.0, 32.0);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        width: 3,
                        height: h,
                        decoration: BoxDecoration(
                          color: Colors.white60,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _resetRecording,
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),

                  GestureDetector(
                    onTap: _sendVoiceMessage,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: uiColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
