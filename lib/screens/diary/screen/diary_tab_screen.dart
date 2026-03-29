import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/chat/widget/video_player_screen.dart';
import 'package:on_peace/screens/diary/controller/diary_controller.dart';
import 'package:on_peace/screens/diary/widget/diary_attachment_sheet.dart';
import 'package:on_peace/widgets/helpful_widgets/info_popup.dart';

class DiaryTabScreen extends StatefulWidget {
  const DiaryTabScreen({super.key});

  @override
  State<DiaryTabScreen> createState() => _DiaryTabScreenState();
}

class _DiaryTabScreenState extends State<DiaryTabScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isUploading = false;
  int _weatherIndex = 0;
  int _moodIndex = 0;
  List<File> _attachedFiles = [];
  List<String> _attachedTypes = [];

  static const _weatherIcons = [
    'assets/svg/sunny.svg',
    'assets/svg/cloud.svg',
    'assets/svg/wind.svg',
    'assets/svg/rain.svg',
    'assets/svg/snow.svg',
    'assets/svg/fog.svg',
  ];
  static const _moodIcons = [
    'assets/svg/smile.svg',
    'assets/svg/unsmile.svg',
    'assets/svg/bad.svg',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<VideoPlayerController> _initializeVideo(String path) async {
    final controller = VideoPlayerController.file(File(path));
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

  String _monthName(int m) => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][m];

  String _dayName(int d) => const [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][d];

  String _padded(int n) => n.toString().padLeft(2, '0');

  void _pickWeather(BuildContext btnContext) {
    final box = btnContext.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => Stack(
        children: [
          Positioned(
            top: pos.dy + box.size.height * -1.7,
            right:
                MediaQuery.of(context).size.width -
                pos.dx -
                box.size.width * 1.3,
            child: Material(
              color: Colors.white,
              elevation: 6,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_weatherIcons.length, (i) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _weatherIndex = i);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: 10,
                        ),
                        child: SvgPicture.asset(
                          _weatherIcons[i],
                          width: 32,
                          height: 32,
                          colorFilter: ColorFilter.mode(
                            _weatherIndex == i
                                ? calendarLightTheme1
                                : Colors.grey.shade400,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickMood(BuildContext btnContext) {
    final box = btnContext.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => Stack(
        children: [
          Positioned(
            top: pos.dy + box.size.height * -1.7,
            right:
                MediaQuery.of(context).size.width -
                pos.dx -
                box.size.width * 1.2,
            child: Material(
              color: Colors.white,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_moodIcons.length, (i) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _moodIndex = i);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: 10,
                        ),
                        child: SvgPicture.asset(
                          _moodIcons[i],
                          width: 32,
                          height: 32,
                          colorFilter: ColorFilter.mode(
                            _moodIndex == i
                                ? calendarLightTheme1
                                : Colors.grey.shade400,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAttachment() async {
    final files = await showDiaryAttachmentSheet(context);
    if (files.isNotEmpty) {
      setState(() {
        for (final f in files) {
          _attachedFiles.add(f);
          final ext = f.path.split('.').last.toLowerCase();
          _attachedTypes.add(
            ['mp4', 'mov', 'avi', 'mkv'].contains(ext) ? 'video' : 'image',
          );
        }
      });
    }
  }

  Future<void> _save(DiaryController controller) async {
    final titleText = _titleController.text.trim();
    final bodyText = _bodyController.text.trim();

    if (titleText.isEmpty && bodyText.isEmpty) {
      InfoPopup.show(context, "Please enter a title or write something!");
      return;
    }

    setState(() {
      _isUploading = true;
    });

    await controller.addEntry(
      title: titleText,
      body: bodyText,
      weatherIndex: _weatherIndex,
      moodIndex: _moodIndex,
      mediaFiles: _attachedFiles,
      mediaTypes: _attachedTypes,
    );

    if (!mounted) return;

    _titleController.clear();
    _bodyController.clear();
    setState(() {
      _attachedFiles = [];
      _attachedTypes = [];
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final controller = context.read<DiaryController>();

    return Stack(
      children: [
        Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _monthName(now.month),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${now.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_dayName(now.weekday)} · ${_padded(now.hour)}:${_padded(now.minute)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                color: whiteColor,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              cursorColor: Colors.grey,
                              decoration: InputDecoration(
                                hintText: 'Diary title',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: calendarLightTheme1.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: calendarLightTheme1,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Builder(
                            builder: (ctx) => GestureDetector(
                              onTap: () => _pickWeather(ctx),
                              child: SvgPicture.asset(
                                _weatherIcons[_weatherIndex],
                                width: 32,
                                height: 32,
                                colorFilter: const ColorFilter.mode(
                                  calendarLightTheme1,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),
                          Builder(
                            builder: (ctx) => GestureDetector(
                              onTap: () => _pickMood(ctx),
                              child: SvgPicture.asset(
                                _moodIcons[_moodIndex],
                                width: 32,
                                height: 32,
                                colorFilter: const ColorFilter.mode(
                                  calendarLightTheme1,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _bodyController,
                                    maxLines: null,
                                    minLines: 2,
                                    textAlignVertical: TextAlignVertical.top,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Write something...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade300,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _openAttachment,
                                  child: const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Icon(
                                      Icons.attach_file,
                                      color: calendarLightTheme1,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (_attachedFiles.isNotEmpty)
                              ...List.generate(_attachedFiles.length, (i) {
                                final isVideo = _attachedTypes[i] == 'video';
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey.shade200,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: isVideo
                                            ? FutureBuilder(
                                                future: Future.wait([
                                                  _getVideoThumbnail(
                                                    _attachedFiles[i].path,
                                                  ),
                                                  _initializeVideo(
                                                    _attachedFiles[i].path,
                                                  ),
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
                                                  final aspectRatio = controller
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
                                                                    _attachedFiles[i]
                                                                        .path,
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
                                                            width:
                                                                double.infinity,
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
                                                            color: Colors.white,
                                                            size: 40,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              )
                                            : Image.file(
                                                _attachedFiles[i],
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _attachedFiles.removeAt(i);
                                            _attachedTypes.removeAt(i);
                                          });
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(5),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              height: 56,
              color: calendarLightTheme1,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ToolbarBtn(
                    icon: Icons.close,
                    onTap: () {
                      _titleController.clear();
                      _bodyController.clear();
                      setState(() {
                        _attachedFiles = [];
                        _attachedTypes = [];
                      });
                    },
                  ),
                  _ToolbarBtn(
                    icon: Icons.save_outlined,
                    onTap: () => _save(controller),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (_isUploading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(color: whiteColor),
            ),
          ),
      ],
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
