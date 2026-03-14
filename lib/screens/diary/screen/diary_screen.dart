import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/diary/controller/diary_controller.dart';
import 'package:whatsapp_clone/screens/diary/calendar/calendar_screen.dart';
import 'package:whatsapp_clone/screens/diary/screen/entry_screen.dart';
import 'package:whatsapp_clone/screens/diary/screen/diary_tab_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  static const _skyBlue = Color(0xFF5BB5C8);
  static const _tabLabels = ['Entries', 'Calendar', 'Diary'];

  final _pageController = PageController();
  int _selectedTab = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    setState(() => _selectedTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiaryController()..listenToEntries(),
      child: Scaffold(
        backgroundColor: whiteColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Container(
            color: whiteColor,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: _skyBlue,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _TabBar(
                            labels: _tabLabels,
                            selectedIndex: _selectedTab,
                            activeColor: _skyBlue,
                            onTap: _goToTab,
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      'DIARY',
                      style: TextStyle(
                        fontSize: 17,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500,
                        color: _skyBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/sky_background.jpeg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Consumer<DiaryController>(
            builder: (_, controller, __) {
              return PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _selectedTab = i),
                children: [
                  const EntryScreen(),
                  CalendarScreen(
                    diaryDates: controller.entries
                        .map((e) => e.createdAt)
                        .toList(),
                  ),
                  const DiaryTabScreen(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final Color activeColor;
  final void Function(int) onTap;

  const _TabBar({
    required this.labels,
    required this.selectedIndex,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: activeColor.withOpacity(0.45), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: List.generate(labels.length, (i) {
            final selected = selectedIndex == i;
            final isFirst = i == 0;
            final isLast = i == labels.length - 1;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? activeColor : Colors.white,
                    borderRadius: BorderRadius.horizontal(
                      left: isFirst ? const Radius.circular(8) : Radius.zero,
                      right: isLast ? const Radius.circular(8) : Radius.zero,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : activeColor,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
