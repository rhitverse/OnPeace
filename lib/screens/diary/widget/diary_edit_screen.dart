import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/models/diary_model.dart';
import 'package:on_peace/screens/chat/widget/video_player_screen.dart';
import 'package:on_peace/screens/diary/controller/diary_controller.dart';
import 'package:on_peace/screens/diary/widget/diary_attachment_sheet.dart';
import 'package:on_peace/widgets/helpful_widgets/custom_messenger.dart';

class DiaryEditScreen extends StatefulWidget {
  final DiaryModel entry;
  final DiaryController controller;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddPhoto;

  const DiaryEditScreen({
    super.key,
    required this.entry,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
    required this.onAddPhoto,
  });

  @override
  State<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends State<DiaryEditScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  List<File> _newImages = [];
  List<String> _imagesToDelete = [];
  bool _isSaving = false;

  static const _weatherData = [
    ('assets/svg/sunny.svg', 'sunny'),
    ('assets/svg/cloud.svg', 'cloudy'),
    ('assets/svg/wind.svg', 'windy'),
    ('assets/svg/rain.svg', 'rainy'),
    ('assets/svg/snow.svg', 'snowy'),
    ('assets/svg/fog.svg', 'foggy'),
  ];

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

    final e = widget.entry;
    if (e.title.trim().isNotEmpty) {
      _titleController = TextEditingController(text: e.title.trim());
      _bodyController = TextEditingController(text: e.text);
    } else {
      final lines = e.text.trim().split('\n');
      if (lines.length > 1) {
        _titleController = TextEditingController(text: lines.first.trim());
        _bodyController = TextEditingController(
          text: lines.skip(1).join('\n').trim(),
        );
      } else {
        _titleController = TextEditingController(text: '');
        _bodyController = TextEditingController(text: e.text);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  List<String> get _imageUrls {
    final e = widget.entry;
    if (e.mediaUrls.isEmpty) return [];
    final images = <String>[];
    for (int i = 0; i < e.mediaUrls.length; i++) {
      final type = i < e.mediaTypes.length ? e.mediaTypes[i] : '';
      if (type.startsWith('image') &&
          !_imagesToDelete.contains(e.mediaUrls[i])) {
        images.add(e.mediaUrls[i]);
      }
    }
    return images;
  }

  List<String> get _videoUrls {
    final e = widget.entry;
    if (e.mediaUrls.isEmpty) return [];
    final videos = <String>[];
    for (int i = 0; i < e.mediaUrls.length; i++) {
      final type = i < e.mediaTypes.length ? e.mediaTypes[i] : '';
      if (type.startsWith('video') &&
          !_imagesToDelete.contains(e.mediaUrls[i])) {
        videos.add(e.mediaUrls[i]);
      }
    }
    return videos;
  }

  Future<VideoPlayerController> _initializeVideo(String path) async {
    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    return controller;
  }

  Future<VideoPlayerController> _initializeVideoFromUrl(String url) async {
    final controller = VideoPlayerController.network(url);
    await controller.initialize();
    return controller;
  }

  Future<Uint8List?> _getVideoThumbnail(String path) async {
    return await VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 720,
      quality: 100,
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text(
          "Do you really want to delete this diary?",
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: whiteColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onDelete();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openAttachment() async {
    final files = await showDiaryAttachmentSheet(context);

    if (files.isNotEmpty) {
      setState(() {
        _newImages.addAll(files);
      });
    }
  }

  Future<void> _saveEntry() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (!mounted) return;

    setState(() => _isSaving = true);

    try {
      final newTypes = _newImages.map((file) {
        final ext = file.path.split('.').last.toLowerCase();
        if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return 'video';
        return 'image';
      }).toList();
      await widget.controller.updateEntryWithMedia(
        entryId: widget.entry.id,
        newTitle: title,
        newText: body,
        existingUrls: widget.entry.mediaUrls,
        urlsToDelete: _imagesToDelete,
        existingTypes: widget.entry.mediaTypes,
        newFiles: _newImages,
        newTypes: newTypes,
      );

      if (!mounted) return;

      setState(() => _isSaving = false);
      Navigator.pop(context);
      CustomMessenger.show(context, "Entry updated successfully!");
    } catch (e) {
      setState(() => _isSaving = false);
      CustomMessenger.show(context, "Failed to update entry");
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final imageUrls = _imageUrls;
    final videoUrls = _videoUrls;
    final weatherIdx = e.weatherIndex.clamp(0, _weatherData.length - 1);
    final weatherIcon = _weatherData[weatherIdx].$1;
    final weatherLabel = _weatherData[weatherIdx].$2;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                                '${e.weekday}  ${e.time}',
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
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _titleController,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                color: calendarLightTheme1,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Diary title',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 24,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                            TextField(
                              controller: _bodyController,
                              maxLines: null,
                              minLines: 3,
                              textAlignVertical: TextAlignVertical.top,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.65,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Write something...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),

                                suffixIcon: GestureDetector(
                                  onTap: _openAttachment,
                                  child: const Icon(
                                    Icons.attach_file,
                                    color: calendarLightTheme1,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            if (imageUrls.isNotEmpty ||
                                _newImages.isNotEmpty ||
                                videoUrls.isNotEmpty) ...[
                              ...videoUrls.map((url) {
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade200,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: FutureBuilder(
                                          future: Future.wait([
                                            _getVideoThumbnail(url),
                                            _initializeVideoFromUrl(url),
                                          ]),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return Container(
                                                height: 180,
                                                color: Colors.black12,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color:
                                                            calendarLightTheme1,
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
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        VideoPlayerScreen(
                                                          videoUrl: url,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  AspectRatio(
                                                    aspectRatio: aspectRatio,
                                                    child: Image.memory(
                                                      thumbnail,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      filterQuality:
                                                          FilterQuality.high,
                                                    ),
                                                  ),
                                                  Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.black45,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    child: const Icon(
                                                      Icons.play_arrow,
                                                      color: Colors.white,
                                                      size: 40,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _imagesToDelete.add(url);
                                          });
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: const Icon(
                                            Icons.delete,
                                            color: whiteColor,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),

                              ...imageUrls.map((url) {
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),

                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(7),
                                        child: Image.network(
                                          url,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (_, child, progress) {
                                            if (progress == null) return child;
                                            return Container(
                                              height: 200,
                                              color: Colors.grey.shade100,
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color:
                                                          calendarLightTheme1,
                                                    ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _imagesToDelete.add(url);
                                          });
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: const Icon(
                                            Icons.delete,
                                            color: whiteColor,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),

                              if (_newImages.isNotEmpty) ...[
                                ..._newImages.map((file) {
                                  final isVideo = ['mp4', 'mov', 'avi', 'mkv']
                                      .contains(
                                        file.path.split('.').last.toLowerCase(),
                                      );

                                  return Stack(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                          child: isVideo
                                              ? FutureBuilder(
                                                  future: Future.wait([
                                                    _getVideoThumbnail(
                                                      file.path,
                                                    ),
                                                    _initializeVideo(file.path),
                                                  ]),
                                                  builder: (context, snapshot) {
                                                    if (!snapshot.hasData) {
                                                      return Container(
                                                        height: 180,
                                                        color: Colors.black12,
                                                        child: const Center(
                                                          child: CircularProgressIndicator(
                                                            color:
                                                                calendarLightTheme1,
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    final thumbnail =
                                                        snapshot.data![0]
                                                            as Uint8List;
                                                    final controller =
                                                        snapshot.data![1]
                                                            as VideoPlayerController;
                                                    final aspectRatio =
                                                        controller
                                                            .value
                                                            .aspectRatio;

                                                    return GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                VideoPlayerScreen(
                                                                  videoUrl:
                                                                      file.path,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          AspectRatio(
                                                            aspectRatio:
                                                                aspectRatio,
                                                            child: Image.memory(
                                                              thumbnail,
                                                              fit: BoxFit.cover,
                                                              width: double
                                                                  .infinity,
                                                              filterQuality:
                                                                  FilterQuality
                                                                      .high,
                                                            ),
                                                          ),
                                                          Container(
                                                            decoration:
                                                                const BoxDecoration(
                                                                  color: Colors
                                                                      .black45,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  12,
                                                                ),
                                                            child: const Icon(
                                                              Icons.play_arrow,
                                                              color:
                                                                  Colors.white,
                                                              size: 40,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Image.file(
                                                  file,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _newImages.remove(file);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            child: const Icon(
                                              Icons.delete,
                                              color: whiteColor,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: calendarLightTheme1,
                        border: Border(
                          top: BorderSide(
                            color: calendarLightTheme1.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionBtn(
                            icon: Icons.delete,
                            lable: 'Delete',
                            onTap: _showDeleteConfirmation,
                            isLoading: false,
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: whiteColor.withOpacity(0.3),
                          ),
                          _ActionBtn(
                            icon: Icons.save,
                            lable: 'Save',
                            onTap: _saveEntry,
                            isLoading: _isSaving,
                          ),
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
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String lable;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionBtn({
    required this.icon,
    required this.lable,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                    ),
                  )
                : Icon(icon, color: whiteColor, size: 25),
          ),
        ),
      ),
    );
  }
}
