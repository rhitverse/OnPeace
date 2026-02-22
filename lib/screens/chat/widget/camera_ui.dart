import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/chat/widget/camera_bottom_bar.dart';
import 'package:whatsapp_clone/screens/chat/widget/filter.dart';

class CameraUi extends StatefulWidget {
  const CameraUi({super.key});
  @override
  State<CameraUi> createState() => _CameraUiState();
}

class _CameraUiState extends State<CameraUi>
    with SingleTickerProviderStateMixin {
  final bool _gridVisible = false;
  bool _isFrontCamera = false;
  FlashMode _flashMode = FlashMode.off;
  late AnimationController _shutterController;
  late Animation<double> _shutterAnimation;
  CameraController? _camController;
  List<CameraDescription> _cameras = [];
  bool _camReady = false;
  bool _isTakingPhoto = false;
  bool _isSwitching = false;
  bool _frontFlashActive = false;

  double _currentZoom = 1.0;
  double _baseZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 8.0;

  int _selectedFilterIndex = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _shutterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _shutterAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _shutterController, curve: Curves.easeInOut),
    );

    _initCamera(front: false);
  }

  Future<void> _initCamera({required bool front}) async {
    if (!mounted) return;

    setState(() {
      _camReady = false;
      _camController = null;
    });

    await _camController?.dispose();

    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }

    final desc = _cameras.firstWhere(
      (c) =>
          c.lensDirection ==
          (front ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => _cameras.first,
    );

    final controller = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();

    if (!front) {
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _currentZoom = _minZoom;
    }

    if (!mounted) return;

    setState(() {
      _camController = controller;
      _isFrontCamera = front;
      _camReady = true;
    });
  }

  Future<void> _flipCamera() async {
    if (_isSwitching) return;
    _isSwitching = true;

    _isFrontCamera = !_isFrontCamera;
    await _initCamera(front: _isFrontCamera);

    _isSwitching = false;
  }

  Future<void> _toggleFlash() async {
    if (!_camReady || _camController == null) return;
    if (_isFrontCamera) {
      if (_frontFlashActive) {
        await ScreenBrightness().resetScreenBrightness();
        setState(() => _frontFlashActive = false);
      } else {
        await ScreenBrightness().setScreenBrightness(1.0);
        setState(() => _frontFlashActive = true);
      }
      return;
    }
    final next = _flashMode == FlashMode.off ? FlashMode.always : FlashMode.off;
    try {
      await _camController!.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } on CameraException catch (_) {
      _showFlashError("This device flashlight doesn't supported");
    } catch (_) {
      _showFlashError("Flash doesn't supported");
    }
  }

  void _showFilterSheet() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      showFilterBottomSheet(
        context: context,
        selectedIndex: _selectedFilterIndex,
        camController: _camController,
        onFilterSelected: (i) => setState(() => _selectedFilterIndex = i),
      );
    });
  }

  void _showFlashError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.flash_off, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: whiteColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _setZoom(double zoom) async {
    if (_isFrontCamera || !_camReady || _camController == null) return;
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    await _camController!.setZoomLevel(clamped);
    setState(() => _currentZoom = clamped);
  }

  Future<void> _onShutterTap() async {
    if (_isTakingPhoto || !_camReady || _camController == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isTakingPhoto = true);

    await _shutterController.forward();
    await _shutterController.reverse();

    try {
      final XFile file = await _camController!.takePicture();

      await _audioPlayer.play(AssetSource('assets/audio/shutter.mp3'));

      if (mounted) Navigator.of(context).pop(file.path);
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isTakingPhoto = false);
    }
  }

  @override
  void dispose() {
    ScreenBrightness().resetScreenBrightness();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _camController?.dispose();
    _shutterController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),

          if (_gridVisible) _buildGridOverlay(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 0,
            left: 0,
            right: 0,
            child: CameraBottomBar(
              isTakingPhoto: _isTakingPhoto,
              isSwitching: _isSwitching,
              shutterAnimation: _shutterAnimation,
              onShutterTap: _onShutterTap,

              onFilterTap: _showFilterSheet,
              onFlipTap: _flipCamera,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_camReady || _camController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
      );
    }

    Widget preview = ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height:
                MediaQuery.of(context).size.width *
                _camController!.value.aspectRatio,
            child: CameraPreview(_camController!),
          ),
        ),
      ),
    );
    final activeFilter = cameraFilters[_selectedFilterIndex].colorFilter;
    if (activeFilter != null) {
      preview = ColorFiltered(colorFilter: activeFilter, child: preview);
    }
    if (!_isFrontCamera) {
      preview = GestureDetector(
        onScaleStart: (_) => _baseZoom = _currentZoom,
        onScaleUpdate: (details) => _setZoom(_baseZoom * details.scale),
        child: preview,
      );
    }
    return preview;
  }

  Widget _buildGridOverlay() => CustomPaint(painter: _GridPainter());
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mounted) Navigator.of(context).maybePop();
              });
            },
            child: const Icon(Icons.close, color: whiteColor, size: 30),
          ),

          const Spacer(),

          _iconButton(
            icon:
                (_isFrontCamera
                    ? _frontFlashActive
                    : _flashMode == FlashMode.always)
                ? Icons.flash_on
                : Icons.flash_off,
            onTap: _toggleFlash,
            active: _isFrontCamera
                ? _frontFlashActive
                : _flashMode == FlashMode.always,
          ),

          const Spacer(),

          const SizedBox(width: 30),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? whiteColor.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: active ? whiteColor : whiteColor.withOpacity(0.85),
          size: 32,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = whiteColor.withOpacity(0.25)
      ..strokeWidth = 0.8;
    for (int i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
