import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_clone/models/call_model.dart';
import 'package:whatsapp_clone/screens/calls/controller/call_provider.dart';
import 'package:whatsapp_clone/screens/calls/service/zego_engine_service.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class CallsScreen extends ConsumerStatefulWidget {
  final CallModel call;
  const CallsScreen({super.key, required this.call});

  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen> {
  final ZegoEngineService _zegoService = ZegoEngineService();
  final String _myUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Widget? _localView;
  Widget? _remoteView;
  String? _currentRemoteStreamId;
  bool _isRemoteJoined = false;
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = false;
  bool _isFrontCamera = true;
  int _callDuration = 0;
  late Future<void> _initViewsFuture;

  @override
  void initState() {
    super.initState();
    // ── ORDER MATTERS ──
    // 1. Pehle listener set karo (future events ke liye)
    _setStreamListener();
    // 2. Phir async initialization start karo
    _initViewsFuture = _initViews();
    _startCallTimer();
  }

  // ── STEP 1: Future stream events ke liye listener ──
  void _setStreamListener() {
    ZegoExpressEngine.onRoomStreamUpdate =
        (roomID, updateType, streamList, extendedData) async {
          if (updateType == ZegoUpdateType.Add) {
            for (var stream in streamList) {
              // Apna stream skip karo
              if (stream.streamID == '$_myUserId-main') continue;

              print('🎯 New stream via listener: ${stream.streamID}');
              await _playRemoteStream(stream.streamID);
            }
          } else if (updateType == ZegoUpdateType.Delete) {
            for (final stream in streamList) {
              if (stream.streamID == _currentRemoteStreamId) {
                await _zegoService.stopPlayingStream(stream.streamID);
                if (mounted) {
                  setState(() {
                    _currentRemoteStreamId = null;
                    _remoteView = null;
                    _isRemoteJoined = false;
                  });
                }
              }
            }
          }
        };
  }

  // ── STEP 2: Local preview + pending streams check ──
  Future<void> _initViews() async {
    try {
      // Ensure Zego engine is initialized first
      try {
        await _zegoService.initializeZego();
        print('✅ [INIT] Zego engine initialized');
      } catch (e) {
        print('❌ [INIT] Error initializing Zego: $e');
        rethrow;
      }

      // Local video load karo
      if (widget.call.isVideo) {
        print('📷 [INIT] Loading local preview...');
        Widget? local;
        for (int i = 0; i < 3; i++) {
          try {
            local = await _zegoService.getLocalPreview();
            if (local != null) {
              print('✅ [INIT] Local preview loaded on attempt ${i + 1}');
              break;
            }
          } catch (e) {
            print('⚠️ [INIT] Local preview attempt ${i + 1} failed: $e');
          }
          if (i < 2) await Future.delayed(const Duration(milliseconds: 500));
        }
        if (mounted) {
          setState(() => _localView = local);
          if (local == null)
            print('❌ [INIT] Local preview is NULL after all attempts');
        }
      }

      // ── KEY FIX: Buffer check ──
      final pendingStreams = _zegoService.pendingRemoteStreamIds;
      print('📋 [INIT] Pending streams in buffer: ${pendingStreams.length}');

      if (pendingStreams.isNotEmpty) {
        for (final streamId in pendingStreams) {
          if (streamId == '$_myUserId-main') continue;
          print('🎯 [INIT] Playing buffered stream: $streamId');
          await _playRemoteStream(streamId);
        }
        _zegoService.clearPendingStreams();
      } else {
        print('📋 [INIT] Buffer empty — waiting for remote user to join...');
        // Wait up to 5 seconds for remote user to join
        await Future.delayed(const Duration(seconds: 5));
        if (_remoteView == null && mounted) {
          final remoteUserId = widget.call.callerId == _myUserId
              ? widget.call.receiverId
              : widget.call.callerId;
          print('🔄 [INIT] Fallback attempt for: $remoteUserId-main');
          await _playRemoteStream('$remoteUserId-main');
        }
      }
      print('✅ [INIT] View initialization complete');
    } catch (e) {
      print('❌ [INIT] Fatal error: $e');
    }
  }

  // ── Remote stream play karo (ek jagah se sab handle hota hai) ──
  Future<void> _playRemoteStream(String streamId) async {
    // Agar yahi stream already play ho raha hai toh skip
    if (_currentRemoteStreamId == streamId) return;

    // Purana stream stop karo
    if (_currentRemoteStreamId != null) {
      await _zegoService.stopPlayingStream(_currentRemoteStreamId!);
    }

    final view = await _zegoService.getRemotePreviewByStreamId(streamId);

    if (mounted) {
      setState(() {
        _currentRemoteStreamId = streamId;
        _remoteView = view;
        _isRemoteJoined = view != null;
      });

      if (view != null) {
        print('✅ Remote video showing for stream: $streamId');
      } else {
        print('❌ Failed to show remote video for: $streamId');
      }
    }
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
    if (h > 0)
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toggleMic() {
    _zegoService.toggleMicrophone();
    setState(() => _isMicMuted = !_isMicMuted);
  }

  void _toggleCamera() {
    _zegoService.toggleCamera();
    setState(() => _isCameraOff = !_isCameraOff);
  }

  void _toggleSpeaker() {
    _zegoService.toggleSpeaker();
    setState(() => _isSpeakerOn = !_isSpeakerOn);
  }

  void _flipCamera() {
    _zegoService.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  void _endCall() {
    ref.read(callControllerProvider.notifier).endCall(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder<void>(
          future: _initViewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return widget.call.isVideo
                  ? _buildWaitingScreen()
                  : _buildVoiceWaitingScreen();
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 50),
                    const SizedBox(height: 16),
                    Text(
                      'Init Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return widget.call.isVideo
                ? _buildVideoCallUI()
                : _buildVoiceCallUI();
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════
  // VIDEO CALL UI
  // ════════════════════════════════════
  Widget _buildVideoCallUI() {
    return Stack(
      children: [
        // Remote video — full screen
        if (_isRemoteJoined && _remoteView != null)
          Positioned.fill(
            child: Container(color: Colors.black, child: _remoteView!),
          ),

        // Waiting screen while remote connecting
        if (!(_isRemoteJoined && _remoteView != null))
          Positioned.fill(child: _buildWaitingScreen()),

        // Local video — top right corner
        if (_localView != null && !_isCameraOff)
          Positioned(
            top: 50,
            right: 16,
            width: 110,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _localView!,
              ),
            ),
          ),

        // Naam + Timer — top left
        Positioned(
          top: 50,
          left: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.call.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isRemoteJoined ? _formatDuration(_callDuration) : 'Ringing...',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),

        // Buttons — bottom
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: _buildControlButtons(isVideo: true),
        ),
      ],
    );
  }

  // ════════════════════════════════════
  // VOICE CALL UI
  // ════════════════════════════════════
  Widget _buildVoiceCallUI() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade900, Colors.blue.shade800],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey.shade700,
                  child: const Icon(
                    Icons.person,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.call.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isRemoteJoined
                      ? _formatDuration(_callDuration)
                      : 'Calling...',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                if (!_isRemoteJoined) ...[
                  const SizedBox(height: 30),
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: _buildControlButtons(isVideo: false),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════
  // WAITING SCREEN
  // ════════════════════════════════════
  Widget _buildWaitingScreen() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade800,
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              widget.call.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ringing...',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.white54),
            const SizedBox(height: 40),
            // ── DEBUG INFO ──
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black54,
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Info:',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '🎥 Local: ${_localView != null ? '✅ Created' : '❌ Not yet'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📹 Remote: ${_remoteView != null ? '✅ Created' : '⏳ Waiting'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stream: ${_currentRemoteStreamId?.substring(0, 8) ?? 'none'}...',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${_isRemoteJoined ? '🟢 Connected' : '🟡 Connecting'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceWaitingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade900, Colors.blue.shade800],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey.shade700,
              child: const Icon(Icons.person, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              widget.call.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Connecting...',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════
  // CONTROL BUTTONS
  // ════════════════════════════════════
  Widget _buildControlButtons({required bool isVideo}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRoundButton(
          icon: _isMicMuted ? Icons.mic_off : Icons.mic,
          label: _isMicMuted ? 'Unmute' : 'Mute',
          bgColor: _isMicMuted ? Colors.red : Colors.grey.shade700,
          onTap: _toggleMic,
        ),
        if (!isVideo)
          _buildRoundButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
            bgColor: _isSpeakerOn ? Colors.blue : Colors.grey.shade700,
            onTap: _toggleSpeaker,
          ),
        _buildRoundButton(
          icon: Icons.call_end,
          label: 'End',
          bgColor: Colors.red,
          onTap: _endCall,
          size: 70,
        ),
        if (isVideo)
          _buildRoundButton(
            icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
            label: _isCameraOff ? 'Cam On' : 'Cam Off',
            bgColor: _isCameraOff ? Colors.red : Colors.grey.shade700,
            onTap: _toggleCamera,
          ),
        if (isVideo)
          _buildRoundButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            bgColor: Colors.grey.shade700,
            onTap: _flipCamera,
          ),
      ],
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required VoidCallback onTap,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: bgColor,
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_currentRemoteStreamId != null) {
      _zegoService.stopPlayingStream(_currentRemoteStreamId!);
    }
    ZegoExpressEngine.onRoomStreamUpdate = null;
    super.dispose();
  }
}
