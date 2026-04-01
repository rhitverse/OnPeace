import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/screens/chat/group/controller/group_chat_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/chat/provider/chat_provider.dart';
import 'package:on_peace/screens/chat/provider/pending_messages_provider.dart';
import 'package:on_peace/screens/chat/provider/uploading_messages_provider.dart';

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
  bool _isSending = false;
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

    setState(() => _isSending = true);

    await _audioRecorder.stop();

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      if (mounted) {
        setState(() => _isSending = false);
        widget.onRecordingDone();
      }
      return;
    }

    final durationSeconds = _recordDuration.inSeconds;
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final file = File(path);

    try {
      if (widget.isGroupChat) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();

        final senderName =
            userData.data()?['displayname'] ??
            userData.data()?['username'] ??
            'Unknown';
        final senderProfilePic = userData.data()?['profilePic'] ?? '';

        // Add pending message for group chat audio
        if (mounted) {
          ref
              .read(pendingMessagesProvider.notifier)
              .addPending(
                PendingMessage(
                  tempId: tempId,
                  text: 'Audio',
                  senderId: currentUid,
                  sentTime: DateTime.now(),
                  status: 'sending',
                  mediaType: 'audio',
                  mediaUrl: null,
                  localFilePath: path,
                  fileName:
                      'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
                  fileSize: await file.length(),
                  duration: durationSeconds,
                ),
              );

          // Track in uploading messages
          ref.read(uploadingMessagesProvider.notifier).addUploading(tempId);
        }

        if (!mounted) return;

        await ref
            .read(groupChatControllerProvider)
            .sendAudio(
              groupId: widget.chatId,
              senderId: currentUid,
              senderName: senderName,
              senderProfilePic: senderProfilePic,
              audioFile: file,
              duration: durationSeconds,
            );

        if (mounted) {
          ref.read(pendingMessagesProvider.notifier).removePending(tempId);
          // Remove from uploading messages
          ref.read(uploadingMessagesProvider.notifier).removeUploading(tempId);
        }
        debugPrint('✅ Group audio sent successfully');
      } else {
        // One-to-one chat audio - no pending message needed
        // sendFile handles the upload directly
        if (!mounted) return;

        await ref
            .read(chatControllerProvider)
            .sendFile(
              chatId: widget.chatId,
              senderId: currentUid,
              file: file,
              receiverId: widget.receiverUid,
              fileType: 'audio',
            );

        debugPrint('✅ One-to-one audio sent successfully');
      }

      if (mounted) {
        setState(() => _isSending = false);
        // Smooth close animation
        await _slideController.reverse();
        widget.onRecordingDone();
      }
    } catch (e) {
      debugPrint('❌ Audio send error: $e');
      if (mounted) {
        ref.read(pendingMessagesProvider.notifier).removePending(tempId);
        ref.read(uploadingMessagesProvider.notifier).removeUploading(tempId);
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send audio: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}',
            ),
            duration: const Duration(seconds: 3),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isRecording || _isSending ? null : _startRecording,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFF2A2A2A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecording ? uiColor : Colors.grey[800]!,
                      width: 2,
                    ),
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: uiColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: _isRecording ? uiColor : Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isSending
                    ? 'Sending...'
                    : _isRecording
                    ? _formatDuration(_recordDuration)
                    : 'Tap to record',
                style: TextStyle(
                  color: _isSending
                      ? uiColor
                      : _isRecording
                      ? Colors.white70
                      : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              if (_isRecording)
                SizedBox(
                  height: 40,
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
                                  36)
                              .clamp(3.0, 36.0);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        width: 2.5,
                        height: h,
                        decoration: BoxDecoration(
                          color: uiColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              if (_isRecording) const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _isSending ? null : _resetRecording,
                    child: Icon(
                      Icons.delete_outline,
                      color: _isSending ? Colors.grey[600] : Colors.red,
                      size: 32,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSending ? null : _sendVoiceMessage,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _isSending ? uiColor.withOpacity(0.6) : uiColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: uiColor.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
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
