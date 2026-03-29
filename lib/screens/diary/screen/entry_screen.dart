import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/models/diary_model.dart';
import 'package:on_peace/screens/diary/controller/diary_controller.dart';
import 'package:on_peace/screens/diary/widget/diary_details_screen.dart';
import 'package:on_peace/screens/diary/widget/diary_edit_screen.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DiaryController>().listenToEntries());
  }

  void _openEditScreen(
    BuildContext context,
    DiaryController controller,
    DiaryModel e,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => DiaryEditScreen(
          entry: e,
          controller: controller,
          onEdit: () {},
          onDelete: () => controller.deleteEntry(e.id),
          onAddPhoto: () {},
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DiaryController>();
    return Column(
      children: [
        Expanded(
          child: controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: whiteColor),
                )
              : controller.entries.isEmpty
              ? const Center(
                  child: Text(
                    "entries not exists",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.entries.length,
                  itemBuilder: (context, index) {
                    final e = controller.entries[index];
                    return DiaryCard(
                      entry: e,
                      onDelete: () => controller.deleteEntry(e.id),
                      onEdit: () => _openEditScreen(context, controller, e),
                      onTap: () => _openDetail(context, controller, e),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openDetail(
    BuildContext context,
    DiaryController controller,
    DiaryModel e,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => DiaryDetailScreen(
          entry: e,
          onEdit: () => _openEditScreen(context, controller, e),
          onDelete: () => controller.deleteEntry(e.id),
          onAddPhoto: () {},
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }
}

class DiaryCard extends StatelessWidget {
  final DiaryModel entry;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const DiaryCard({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

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
  Widget build(BuildContext context) {
    String title = entry.title.trim();
    String body = entry.text.trim();

    if (title.isEmpty && body.contains('\n')) {
      final parts = body.split('\n');
      title = parts.first.trim();
      body = parts.skip(1).join('\n').trim();
    }
    return GestureDetector(
      onTap: onTap,
      onLongPress: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 62,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    entry.month,
                    style: TextStyle(
                      fontSize: 12,
                      color: calendarLightTheme1.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    entry.day,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      color: calendarLightTheme1,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    entry.weekday,
                    style: TextStyle(
                      fontSize: 11,
                      color: calendarLightTheme1.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.time,
                        style: TextStyle(
                          fontSize: 11,
                          color: calendarLightTheme1,
                        ),
                      ),
                      Row(
                        children: [
                          SvgPicture.asset(
                            _weatherIcons[entry.weatherIndex.clamp(
                              0,
                              _weatherIcons.length - 1,
                            )],
                            width: 16,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                              calendarLightTheme1.withOpacity(0.7),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SvgPicture.asset(
                            _moodIcons[entry.moodIndex.clamp(
                              0,
                              _moodIcons.length - 1,
                            )],
                            width: 16,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                              calendarLightTheme1.withOpacity(0.7),
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: calendarLightTheme1,
                          ),
                        ),
                      if (body.isNotEmpty)
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: calendarLightTheme1.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
