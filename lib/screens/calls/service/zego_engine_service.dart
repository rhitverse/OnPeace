import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_peace/secret/secret.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class ZegoEngineService {
  static final ZegoEngineService _instance = ZegoEngineService._internal();
  factory ZegoEngineService() => _instance;
  ZegoEngineService._internal();

  final ZegoExpressEngine _zegoEngine = ZegoExpressEngine.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isCallActive = false;
  String? _currentCallId;
  String? _currentRoomId;
  bool _isMicMuted = false;
  bool _isCameraMuted = false;
  bool _isSpeakerOn = false;
  bool _isEngineInitialized = false;
  bool _isUsingFrontCamera = true;
  bool _isRoomLoggedIn = false;

  // ── KEY FIX: Stream buffer ──
  // CallsScreen open hone SE PEHLE jo remote streams aaye unhe yahan store karo
  final List<String> _pendingRemoteStreamIds = [];
  List<String> get pendingRemoteStreamIds =>
      List.unmodifiable(_pendingRemoteStreamIds);
  void clearPendingStreams() => _pendingRemoteStreamIds.clear();

  bool get isCallActive => _isCallActive;
  bool get isMicMuted => _isMicMuted;
  bool get isCameraMuted => _isCameraMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  Future<void> _ensureMediaPermissions({required bool isVideo}) async {
    final permissions = <Permission>[
      Permission.microphone,
      if (isVideo) Permission.camera,
    ];

    print(
      '🔐 [PERMS] Requesting permissions: ${permissions.map((p) => p.toString()).join(', ')}',
    );
    final result = await permissions.request();

    print('🔐 [PERMS] Results: $result');

    final denied = result.entries.where((e) => !e.value.isGranted).toList();
    if (denied.isEmpty) {
      print('✅ [PERMS] All permissions granted');
      return;
    }

    final deniedNames = denied
        .map((e) => e.key.toString().split('.').last)
        .join(', ');
    print('❌ [PERMS] Permissions denied: $deniedNames');
    throw Exception('Permission denied: $deniedNames');
  }

  Future<void> initializeZego() async {
    if (_isEngineInitialized) return;
    try {
      await ZegoExpressEngine.createEngineWithProfile(
        ZegoEngineProfile(
          Secrets.zegoCloudAppId,
          ZegoScenario.StandardVideoCall,
          appSign: Secrets.appSign,
        ),
      );
      _setupEventHandlers();
      _isEngineInitialized = true;
      print('✅ Zego Engine Initialized');
    } catch (e) {
      print('❌ Zego Init Error: $e');
      rethrow;
    }
  }

  void _setupEventHandlers() {
    ZegoExpressEngine.onRoomUserUpdate =
        (String roomID, ZegoUpdateType updateType, List<ZegoUser> userList) {
          for (var user in userList) {
            print(
              updateType == ZegoUpdateType.Add
                  ? '👤 User Joined: ${user.userID}'
                  : '👤 User Left: ${user.userID}',
            );
          }
        };

    // ── KEY FIX: Buffer streams, CallsScreen ka handler inhe pick up karega ──
    ZegoExpressEngine.onRoomStreamUpdate =
        (
          String roomID,
          ZegoUpdateType updateType,
          List<ZegoStream> streamList,
          Map<String, dynamic> extendedData,
        ) {
          final myUserId = _auth.currentUser?.uid ?? '';
          for (final stream in streamList) {
            print('📡 Stream Update: ${stream.streamID} - $updateType');
            if (updateType == ZegoUpdateType.Add) {
              if (stream.streamID == '$myUserId-main') continue; // apna skip
              if (!_pendingRemoteStreamIds.contains(stream.streamID)) {
                _pendingRemoteStreamIds.add(stream.streamID);
                print('📥 Buffered: ${stream.streamID}');
              }
            } else {
              _pendingRemoteStreamIds.remove(stream.streamID);
            }
          }
        };

    ZegoExpressEngine.onRoomStateChanged =
        (roomID, reason, errorCode, extendedData) {
          print('🏠 Room State: $reason (Error: $errorCode)');
          if (errorCode != 0) _isCallActive = false;
        };

    ZegoExpressEngine.onAudioRouteChange = (ZegoAudioRoute audioRoute) {
      _isSpeakerOn = (audioRoute == ZegoAudioRoute.Speaker);
    };

    ZegoExpressEngine.onEngineStateUpdate = (ZegoEngineState state) {
      print('⚙️ Engine State: $state');
    };
  }

  Future<void> startVoiceCall({
    required String roomId,
    required String remoteUserId,
    required String remoteUserName,
  }) async {
    try {
      _pendingRemoteStreamIds.clear();
      print('🎙️ [VOICE CALL] Starting call with remote: $remoteUserId');

      // Validate Firebase auth
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid.isEmpty) {
        throw Exception(
          '❌ Not logged in to Firebase. Current user: $currentUser',
        );
      }
      print('✅ [VOICE CALL] Firebase user authenticated: ${currentUser.uid}');

      await _ensureMediaPermissions(isVideo: false);
      print('✅ [VOICE CALL] Permissions granted');

      await initializeZego();
      print('✅ [VOICE CALL] Zego initialized with AppID: 111575819');

      // Logout from previous room if still connected
      if (_isRoomLoggedIn &&
          _currentRoomId != null &&
          _currentRoomId != roomId) {
        print(
          '🔓 [VOICE CALL] Logging out from previous room: $_currentRoomId',
        );
        try {
          await _zegoEngine.logoutRoom(_currentRoomId!);
          _isRoomLoggedIn = false;
          _currentRoomId = null;
        } catch (e) {
          print('⚠️ [VOICE CALL] Logout error (ignored): $e');
        }
      }

      final user = ZegoUser(
        currentUser.uid,
        currentUser.displayName ?? 'User_${currentUser.uid.substring(0, 8)}',
      );
      print('📱 [VOICE CALL] User: ${user.userID} / ${user.userName}');
      print('🎙️ [VOICE CALL] Room ID: $roomId');

      final roomConfig = ZegoRoomConfig.defaultConfig()
        ..isUserStatusNotify = true
        ..maxMemberCount = 2;

      print('🔗 [VOICE CALL] Logging into room: $roomId as ${user.userID}');
      final result = await _zegoEngine
          .loginRoom(roomId, user, config: roomConfig)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Room login timeout'),
          );

      if (result.errorCode == 0) {
        print('✅ [VOICE CALL] Room login successful');
        _isRoomLoggedIn = true;
        _currentRoomId = roomId;

        print('🔊 [VOICE CALL] Enabling microphone...');
        await _zegoEngine.muteMicrophone(false);
        await Future.delayed(const Duration(milliseconds: 200));
        print('✅ [VOICE CALL] Microphone ready');

        print('📤 [VOICE CALL] Publishing stream: ${user.userID}-main');
        await _zegoEngine.startPublishingStream('${user.userID}-main');
        await Future.delayed(const Duration(milliseconds: 300));
        print('✅ [VOICE CALL] Stream published');

        _isCallActive = true;
        _currentCallId = roomId;
        print('🟢 [VOICE CALL] Voice call started successfully!');
      } else {
        final errMsg =
            'Room login failed: error code ${result.errorCode}\n'
            'Check:\n'
            '• ZegoCloud credentials (AppID/AppSign)\n'
            '• Device authentication\n'
            '• Network connection';
        print('❌ [VOICE CALL] $errMsg');
        throw Exception(errMsg);
      }
    } catch (e) {
      print('❌ [VOICE CALL] ERROR: $e');
      rethrow;
    }
  }

  Future<void> startVideoCall({
    required String roomId,
    required String remoteUserId,
    required String remoteUserName,
  }) async {
    try {
      _pendingRemoteStreamIds.clear();
      print('🔴 [VIDEO CALL] Starting call with remote: $remoteUserId');

      await _ensureMediaPermissions(isVideo: true);
      print('✅ [VIDEO CALL] Permissions granted');

      await initializeZego();
      print('✅ [VIDEO CALL] Zego initialized');

      // Logout from previous room if still connected
      if (_isRoomLoggedIn &&
          _currentRoomId != null &&
          _currentRoomId != roomId) {
        print(
          '🔓 [VIDEO CALL] Logging out from previous room: $_currentRoomId',
        );
        try {
          await _zegoEngine.logoutRoom(_currentRoomId!);
          _isRoomLoggedIn = false;
          _currentRoomId = null;
        } catch (e) {
          print('⚠️ [VIDEO CALL] Logout error (ignored): $e');
        }
      }

      final user = ZegoUser(
        _auth.currentUser?.uid ?? 'unknown',
        _auth.currentUser?.displayName ?? 'User',
      );

      final roomConfig = ZegoRoomConfig.defaultConfig()
        ..isUserStatusNotify = true
        ..maxMemberCount = 2;

      print('🔗 [VIDEO CALL] Logging into room: $roomId as ${user.userID}');
      final result = await _zegoEngine
          .loginRoom(roomId, user, config: roomConfig)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception('Room login timeout after 15 seconds'),
          );

      if (result.errorCode == 0) {
        print('✅ [VIDEO CALL] Room login successful');
        _isRoomLoggedIn = true;
        _currentRoomId = roomId;

        print('🔊 [VIDEO CALL] Enabling microphone...');
        await _zegoEngine.muteMicrophone(false);
        await Future.delayed(const Duration(milliseconds: 200));
        print('✅ [VIDEO CALL] Microphone ready');

        print('📷 [VIDEO CALL] Enabling camera...');
        await _zegoEngine.enableCamera(true);
        await Future.delayed(const Duration(milliseconds: 300));
        print('✅ [VIDEO CALL] Camera ready');

        print('📤 [VIDEO CALL] Publishing stream: ${user.userID}-main');
        await _zegoEngine.startPublishingStream('${user.userID}-main');
        await Future.delayed(const Duration(milliseconds: 500));
        print('✅ [VIDEO CALL] Stream published');

        _isCallActive = true;
        _currentCallId = roomId;
        print('🟢 [VIDEO CALL] Video call started successfully!');
      } else {
        final errMsg =
            'Room login failed: error code ${result.errorCode}\n'
            'Possible reasons:\n'
            '• AppID/AppSign mismatch in ZegoCloud\n'
            '• User/Device authentication failed\n'
            '• Network connectivity issue\n'
            'Check your ZegoCloud dashboard configuration';
        print('❌ [VIDEO CALL] $errMsg');
        throw Exception(errMsg);
      }
    } catch (e) {
      print('❌ [VIDEO CALL] ERROR: $e');
      rethrow;
    }
  }

  Future<Widget?> getLocalPreview() async {
    try {
      int viewID = -1;
      print('📸 [LOCAL] Creating canvas view...');

      final view = await _zegoEngine
          .createCanvasView((id) {
            viewID = id;
            print('📸 [LOCAL] ViewID CALLBACK received: $id');
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏱️ [LOCAL] Canvas view creation timeout!');
              return null;
            },
          );

      print('📸 [LOCAL] Canvas returned: ${view != null ? 'YES' : 'NULL'}');

      if (view == null) {
        print('❌ [LOCAL] Canvas view is NULL!');
        return null;
      }

      if (viewID == -1) {
        print('⚠️ [LOCAL] ViewID callback NOT triggered yet, waiting...');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('📸 [LOCAL] Starting preview on viewID: $viewID');
      await _zegoEngine.startPreview(canvas: ZegoCanvas.view(viewID));

      // ── CRITICAL: Wait for rendering pipeline ──
      await Future.delayed(const Duration(milliseconds: 1000));

      print('✅ [LOCAL] Preview started and rendering');
      return view;
    } catch (e) {
      print('❌ [LOCAL] ERROR: $e');
      return null;
    }
  }

  Future<Widget?> getRemotePreview(String remoteUserId) =>
      getRemotePreviewByStreamId('$remoteUserId-main');

  Future<Widget?> getRemotePreviewByStreamId(String streamId) async {
    try {
      int viewID = -1;
      print('📺 [REMOTE] Creating canvas for stream: $streamId');

      final view = await _zegoEngine
          .createCanvasView((id) {
            viewID = id;
            print(
              '📺 [REMOTE] ViewID CALLBACK received: $id for stream: $streamId',
            );
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print(
                '⏱️ [REMOTE] Canvas view creation timeout for stream: $streamId',
              );
              return null;
            },
          );

      print('📺 [REMOTE] Canvas returned: ${view != null ? 'YES' : 'NULL'}');

      if (view == null) {
        print('❌ [REMOTE] Canvas view is NULL for stream: $streamId');
        return null;
      }

      if (viewID == -1) {
        print('⚠️ [REMOTE] ViewID callback NOT triggered yet, waiting...');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print(
        '📺 [REMOTE] Starting playback for stream: $streamId on viewID: $viewID',
      );
      await _zegoEngine.startPlayingStream(
        streamId,
        canvas: ZegoCanvas.view(viewID),
      );

      // ── CRITICAL: Wait for rendering pipeline ──
      await Future.delayed(const Duration(milliseconds: 1500));

      print('✅ [REMOTE] Playback started and rendering for stream: $streamId');
      return view;
    } catch (e) {
      print('❌ [REMOTE] ERROR for stream $streamId: $e');
      return null;
    }
  }

  Future<void> stopPlayingStream(String streamId) async {
    try {
      await _zegoEngine.stopPlayingStream(streamId);
    } catch (_) {}
  }

  Future<void> toggleMicrophone() async {
    try {
      _isMicMuted = !_isMicMuted;
      await _zegoEngine.muteMicrophone(_isMicMuted);
    } catch (e) {
      print('Mic Error: $e');
    }
  }

  Future<void> toggleCamera() async {
    try {
      _isCameraMuted = !_isCameraMuted;
      await _zegoEngine.enableCamera(!_isCameraMuted);
    } catch (e) {
      print('Camera Error: $e');
    }
  }

  Future<void> switchCamera() async {
    try {
      _isUsingFrontCamera = !_isUsingFrontCamera;
      await _zegoEngine.useFrontCamera(_isUsingFrontCamera);
    } catch (e) {
      print('Switch Camera Error: $e');
    }
  }

  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerOn = !_isSpeakerOn;
      await _zegoEngine.setAudioRouteToSpeaker(_isSpeakerOn);
    } catch (e) {
      print('Speaker Error: $e');
    }
  }

  Future<void> endCall() async {
    try {
      if (_currentCallId != null) {
        print('🛑 [END CALL] Stopping call: $_currentCallId');

        try {
          await _zegoEngine.stopPreview();
          print('✅ [END CALL] Preview stopped');
        } catch (e) {
          print('⚠️ [END CALL] Error stopping preview: $e');
        }

        try {
          await _zegoEngine.stopPublishingStream();
          print('✅ [END CALL] Stream publishing stopped');
        } catch (e) {
          print('⚠️ [END CALL] Error stopping stream: $e');
        }

        try {
          await _zegoEngine.logoutRoom(_currentCallId!);
          print('✅ [END CALL] Room logged out');
        } catch (e) {
          print('⚠️ [END CALL] Error logging out room: $e');
        }

        try {
          await _firestore.collection('calls').doc(_currentCallId).update({
            'status': 'ended',
            'endTime': DateTime.now().toIso8601String(),
          });
          print('✅ [END CALL] Firestore updated');
        } catch (e) {
          print('⚠️ [END CALL] Error updating Firestore: $e');
        }

        _isCallActive = false;
        _currentCallId = null;
        _isRoomLoggedIn = false;
        _currentRoomId = null;
        _isMicMuted = false;
        _isCameraMuted = false;
        _pendingRemoteStreamIds.clear();
        print('🟢 [END CALL] Call fully cleaned up');
      }
    } catch (e) {
      print('❌ [END CALL] Unexpected error: $e');
    }
  }

  Future<void> uninitializeZego() async {
    try {
      if (_isCallActive) await endCall();
      ZegoExpressEngine.onRoomUserUpdate = null;
      ZegoExpressEngine.onRoomStreamUpdate = null;
      ZegoExpressEngine.onRoomStateChanged = null;
      ZegoExpressEngine.onAudioRouteChange = null;
      ZegoExpressEngine.onEngineStateUpdate = null;
      await ZegoExpressEngine.destroyEngine();
      _isEngineInitialized = false;
    } catch (e) {
      print('Uninitialize Error: $e');
    }
  }
}
