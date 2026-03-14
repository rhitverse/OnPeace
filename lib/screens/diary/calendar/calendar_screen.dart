import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/diary/calendar/month_calendar_view.dart';
import 'package:whatsapp_clone/screens/diary/calendar/page_flip_calendar.dart';

class CalendarScreen extends StatefulWidget {
  final List<DateTime> diaryDates;
  final void Function(DateTime date, int diaryIndex)? onDiaryDateSelected;

  const CalendarScreen({
    super.key,
    this.diaryDates = const [],
    this.onDiaryDateSelected,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  static const int _modeDay = 1;
  static const int _modeMonth = 2;

  int _currentMode = _modeDay;
  DateTime _selectedDate = DateTime.now();

  late AnimationController _fabAnimController;
  late Animation<double> _fabRotation;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _currentMode = _currentMode == _modeDay ? _modeMonth : _modeDay;
    });
    if (_currentMode == _modeMonth) {
      _fabAnimController.forward();
    } else {
      _fabAnimController.reverse();
    }
  }

  void _handleDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    final normalized = DateTime(date.year, date.month, date.day);
    final sortedDates = [...widget.diaryDates]..sort((a, b) => a.compareTo(b));
    final index = _binarySearch(sortedDates, normalized);
    if (index >= 0) {
      widget.onDiaryDateSelected?.call(date, index);
    }
  }

  int _binarySearch(List<DateTime> list, DateTime target) {
    int lo = 0, hi = list.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      final d = DateTime(list[mid].year, list[mid].month, list[mid].day);
      final cmp = d.compareTo(target);
      if (cmp == 0) return mid;
      if (cmp < 0) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const skyFraction = 0.28;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 67,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: whiteColor,
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(
                        color: backgroundColor.withOpacity(0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _currentMode == _modeDay
                          ? PageFlipCalendar(
                              key: const ValueKey('day'),
                              initialDate: _selectedDate,
                              onDateChanged: _handleDateSelected,
                            )
                          : MonthCalendarView(
                              key: const ValueKey('month'),
                              selectedDate: _selectedDate,
                              diaryDates: widget.diaryDates,
                              onDateSelected: _handleDateSelected,
                            ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 28,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: size.height * skyFraction - 104,
            child: Center(
              child: _AnimatedToggleFab(
                rotation: _fabRotation,
                isMonthMode: _currentMode == _modeMonth,
                onTap: _toggleMode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedToggleFab extends StatelessWidget {
  final Animation<double> rotation;
  final bool isMonthMode;
  final VoidCallback onTap;

  static const _skyBlue = Color(0xFF7EC8E3);

  const _AnimatedToggleFab({
    required this.rotation,
    required this.isMonthMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _skyBlue.withOpacity(0.30),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: rotation,
          builder: (_, __) => Transform.rotate(
            angle: rotation.value * 3.14159,
            child: Icon(
              isMonthMode
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: _skyBlue,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
