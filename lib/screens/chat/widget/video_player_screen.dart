import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:on_peace/colors.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? fileName;

  const VideoPlayerScreen({super.key, required this.videoUrl, this.fileName});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  bool _showControls = true;
  late AnimationController _controlsAnimationController;
  double playbackSpeed = 1.0;
  bool showSpeedMenu = false;

  final List<double> speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideo();
  }

  bool get _isControllerReady {
    return _controller != null && _controller!.value.isInitialized;
  }

  void _initializeAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.videoUrl.trim();
    if (videoUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Video URL is empty';
      });
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _controller = controller;

      await controller.initialize().timeout(const Duration(seconds: 20));
      if (!mounted) return;

      controller.addListener(_videoListener);
      await controller.setPlaybackSpeed(playbackSpeed);

      setState(() {
        isLoading = false;
        hasError = false;
      });

      await controller.play();
      _startControlsTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage =
            'Failed to load video. Check your connection and try again.';
      });
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _retryVideoLoad() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controller = null;

    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
      _showControls = true;
      showSpeedMenu = false;
    });

    _initializeVideo();
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isControllerReady && _controller!.value.isPlaying) {
        _hideControls();
      }
    });
  }

  void _showOrHideControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _controlsAnimationController.forward();
        _startControlsTimer();
      } else {
        _controlsAnimationController.reverse();
      }
    });
  }

  void _hideControls() {
    if (_showControls) {
      setState(() {
        _showControls = false;
        _controlsAnimationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controlsAnimationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours == 0) {
      return '$minutes:$seconds';
    }
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: _isControllerReady
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller!),

                          if (isLoading)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: uiColor.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      uiColor,
                                    ),
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),

                          if (hasError) _buildErrorView(),

                          if (!isLoading && !hasError)
                            AnimatedOpacity(
                              opacity: _controller!.value.isPlaying ? 0 : 1,
                              duration: const Duration(milliseconds: 300),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_controller!.value.isPlaying) {
                                      _controller!.pause();
                                    } else {
                                      _controller!.play();
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: backgroundColor.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    _controller!.value.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          if (!isLoading && !hasError)
                            GestureDetector(
                              onTap: _showOrHideControls,
                              child: Container(color: Colors.transparent),
                            ),

                          if (!isLoading && !hasError)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: _buildBottomControlsBar(),
                            ),

                          if (showSpeedMenu && !isLoading && !hasError)
                            Positioned(
                              bottom: 60,
                              right: 12,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: speedOptions.map((speed) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          playbackSpeed = speed;
                                          _controller!.setPlaybackSpeed(speed);
                                          showSpeedMenu = false;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        color: playbackSpeed == speed
                                            ? uiColor.withOpacity(0.2)
                                            : Colors.transparent,
                                        child: Text(
                                          '${speed}x',
                                          style: TextStyle(
                                            color: playbackSpeed == speed
                                                ? uiColor
                                                : Colors.white70,
                                            fontSize: 12,
                                            fontWeight: playbackSpeed == speed
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : hasError
                  ? _buildErrorView()
                  : Container(
                      color: Colors.black,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: uiColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                uiColor,
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),

            if (!isLoading && !hasError)
              Positioned(
                top: 40,
                left: 16,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControlsBar() {
    return AnimatedOpacity(
      opacity: _showControls ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black54],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: uiColor,
                    bufferedColor: Colors.grey[400]!,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (!_isControllerReady) return;
                    setState(() {
                      _controller!.value.isPlaying
                          ? _controller!.pause()
                          : _controller!.play();
                      _startControlsTimer();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _controller!.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Text(
                  _formatDuration(_controller!.value.position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 4),

                const Text(
                  ' / ',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),

                const SizedBox(width: 4),

                Text(
                  _formatDuration(_controller!.value.duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),

                const Spacer(),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      showSpeedMenu = !showSpeedMenu;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      '${playbackSpeed}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retryVideoLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: uiColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
