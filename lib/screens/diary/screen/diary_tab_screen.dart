import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whatsapp_clone/screens/diary/controller/diary_controller.dart';

class DiaryTabScreen extends StatefulWidget {
  const DiaryTabScreen({super.key});

  @override
  State<DiaryTabScreen> createState() => _DiaryTabScreenState();
}

class _DiaryTabScreenState extends State<DiaryTabScreen> {
  static const _skyBlue = Color(0xFF7EC8E3);
  static const _headerBlue = Color(0xFF82C8DE);

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  int _weatherIndex = 0;
  int _moodIndex = 0;
  static const _weatherIcons = [
    Icons.wb_sunny_outlined,
    Icons.cloud_outlined,
    Icons.umbrella_outlined,
    Icons.ac_unit_outlined,
  ];
  static const _moodIcons = [
    Icons.sentiment_satisfied_alt_outlined,
    Icons.sentiment_neutral_outlined,
    Icons.sentiment_dissatisfied_outlined,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
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

  void _pickWeather() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_weatherIcons.length, (i) {
            return GestureDetector(
              onTap: () {
                setState(() => _weatherIndex = i);
                Navigator.pop(context);
              },
              child: Icon(
                _weatherIcons[i],
                size: 36,
                color: _weatherIndex == i ? _skyBlue : Colors.grey.shade400,
              ),
            );
          }),
        ),
      ),
    );
  }

  void _pickMood() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_moodIcons.length, (i) {
            return GestureDetector(
              onTap: () {
                setState(() => _moodIndex = i);
                Navigator.pop(context);
              },
              child: Icon(
                _moodIcons[i],
                size: 36,
                color: _moodIndex == i ? _skyBlue : Colors.grey.shade400,
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _save(DiaryController controller) async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final combined = [
      if (title.isNotEmpty) title,
      if (body.isNotEmpty) body,
    ].join('\n');
    if (combined.isEmpty) return;
    await controller.addEntry(combined);
    _titleController.clear();
    _bodyController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final controller = context.read<DiaryController>();

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: _headerBlue.withOpacity(0.85),
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
              const SizedBox(height: 2),
              Row(
                children: const [
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.white60,
                    size: 13,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'No Location',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: Colors.white,
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
                          decoration: InputDecoration(
                            hintText: 'Diary title',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickWeather,
                        child: Icon(
                          _weatherIcons[_weatherIndex],
                          color: _skyBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _pickMood,
                        child: Icon(
                          _moodIcons[_moodIndex],
                          color: _skyBlue,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: Colors.grey.shade200),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _bodyController,
                      maxLines: null,
                      expands: true,
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
                ),
              ],
            ),
          ),
        ),

        Container(
          height: 56,
          color: _skyBlue,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ToolbarBtn(icon: Icons.camera_alt_outlined, onTap: () {}),
              _ToolbarBtn(icon: Icons.image_outlined, onTap: () {}),
              _ToolbarBtn(
                icon: Icons.close,
                onTap: () {
                  _titleController.clear();
                  _bodyController.clear();
                  setState(() {});
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
