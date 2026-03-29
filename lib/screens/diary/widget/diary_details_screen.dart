import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/models/diary_model.dart';
import 'package:on_peace/screens/chat/widget/full_screen_image.dart';
import 'package:on_peace/screens/chat/widget/video_player_screen.dart';
import 'package:video_player/video_player.dart';

class DiaryDetailScreen extends StatefulWidget {
  final DiaryModel entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddPhoto;
  const DiaryDetailScreen({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onAddPhoto,
  });
  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  static const _weatherData = [
    ('assets/svg/sunny.svg', 'sunny'),
    ('assets/svg/cloud.svg', 'cloudy'),
    ('assets/svg/wind.svg', 'windy'),
    ('assets/svg/rain.svg', 'rainy'),
    ('assets/svg/snow.svg', 'snowy'),
    ('assets/svg/fog.svg', 'foggy'),
  ];

  Future<VideoPlayerController> _initializeVideo(String url) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    return controller;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<String> get _imageUrls {
    final e = widget.entry;
    if (e.mediaUrls.isEmpty) return [];
    final images = <String>[];
    for (int i = 0; i < e.mediaUrls.length; i++) {
      final type = i < e.mediaTypes.length ? e.mediaTypes[i] : '';
      if (type.startsWith('image')) images.add(e.mediaUrls[i]);
    }
    return images;
  }

  List<String> get _videoUrls {
    final e = widget.entry;
    if (e.mediaUrls.isEmpty) return [];
    final videos = <String>[];
    for (int i = 0; i < e.mediaUrls.length; i++) {
      final type = i < e.mediaTypes.length ? e.mediaTypes[i] : '';

      if (type.startsWith('video')) {
        videos.add(e.mediaUrls[i]);
      }
    }
    return videos;
  }

  void _openFullScreenImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullScreenImage(imageUrl: url)),
    );
  }

  void _openVideoPlayer(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoUrl: url)),
    );
  }

  Future<Uint8List?> _getVideoThumbnail(String url) async {
    return await VideoThumbnail.thumbnailData(
      video: url,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 720,
      quality: 100,
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final imageUrls = _imageUrls;
    final weatherIdx = e.weatherIndex.clamp(0, _weatherData.length - 1);
    final weatherIcon = _weatherData[weatherIdx].$1;
    final weatherLabel = _weatherData[weatherIdx].$2;
    final String displayTitle;
    final String displayBody;
    if (e.title.trim().isNotEmpty) {
      displayTitle = e.title.trim();
      displayBody = e.text;
    } else {
      final lines = e.text.trim().split('\n');
      if (lines.length > 1) {
        displayTitle = lines.first.trim();
        displayBody = lines.skip(1).join('\n').trim();
      } else {
        displayTitle = 'Title';
        displayBody = e.text;
      }
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 5, 12, 8),
                        color: calendarLightTheme1,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 5,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: whiteColor.withOpacity(0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: whiteColor,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  e.month,
                                  style: const TextStyle(
                                    color: whiteColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  e.day,
                                  style: const TextStyle(
                                    color: whiteColor,
                                    fontSize: 54,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${e.weekday} ${e.time}',
                                  style: TextStyle(
                                    color: whiteColor.withOpacity(0.95),
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      weatherIcon,
                                      width: 15,
                                      height: 15,
                                      colorFilter: const ColorFilter.mode(
                                        whiteColor,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      weatherLabel,
                                      style: TextStyle(
                                        color: whiteColor.withOpacity(0.9),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              displayTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                                color: calendarLightTheme1,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              displayBody,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: Colors.black,
                                height: 1.65,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (imageUrls.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              ...imageUrls.map(
                                (url) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GestureDetector(
                                    onTap: () => _openFullScreenImage(url),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        url,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            if (_videoUrls.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              ..._videoUrls.map(
                                (url) => FutureBuilder(
                                  future: Future.wait([
                                    _getVideoThumbnail(url),
                                    _initializeVideo(url),
                                  ]),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Container(
                                        height: 200,
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: Colors.black12,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: calendarLightTheme1,
                                          ),
                                        ),
                                      );
                                    }

                                    final thumbnail =
                                        snapshot.data![0] as Uint8List;
                                    final controller =
                                        snapshot.data![1]
                                            as VideoPlayerController;
                                    final aspectRatio =
                                        controller.value.aspectRatio;

                                    return GestureDetector(
                                      onTap: () => _openVideoPlayer(url),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: AspectRatio(
                                                aspectRatio: aspectRatio,
                                                child: Image.memory(
                                                  thumbnail,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  filterQuality:
                                                      FilterQuality.high,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black45,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              child: const Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 40,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
