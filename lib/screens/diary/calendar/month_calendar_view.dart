import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:whatsapp_clone/colors.dart';

class MonthCalendarView extends StatefulWidget {
  final DateTime selectedDate;
  final List<DateTime> diaryDates;
  final void Function(DateTime) onDateSelected;

  const MonthCalendarView({
    super.key,
    required this.selectedDate,
    required this.diaryDates,
    required this.onDateSelected,
  });

  @override
  State<MonthCalendarView> createState() => _MonthCalendarViewState();
}

class _MonthCalendarViewState extends State<MonthCalendarView> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  late Set<String> _diaryDateKeys;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate;
    _selectedDay = widget.selectedDate;
    _diaryDateKeys = _buildKeys(widget.diaryDates);
  }

  @override
  void didUpdateWidget(MonthCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diaryDates != widget.diaryDates) {
      _diaryDateKeys = _buildKeys(widget.diaryDates);
    }
  }

  Set<String> _buildKeys(List<DateTime> dates) {
    return dates.map((d) => _key(d)).toSet();
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  bool _hasDiaryEntry(DateTime day) => _diaryDateKeys.contains(_key(day));

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final primaryColor = calendarLightTheme1;
    final darkColor = HSLColor.fromColor(primaryColor)
        .withLightness(
          (HSLColor.fromColor(primaryColor).lightness - 0.15).clamp(0.0, 1.0),
        )
        .toColor();

    return Container(
      color: Colors.white,
      child: TableCalendar(
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,

        selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          widget.onDateSelected(selectedDay);
        },
        onPageChanged: (focusedDay) {
          setState(() => _focusedDay = focusedDay);
        },

        startingDayOfWeek: StartingDayOfWeek.monday,

        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: ''},

        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (_hasDiaryEntry(day)) {
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: darkColor,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,

          selectedDecoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),

          todayDecoration: BoxDecoration(
            color: primaryColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),

          weekendTextStyle: TextStyle(color: primaryColor.withOpacity(0.8)),

          outsideTextStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13,
          ),

          defaultTextStyle: const TextStyle(fontSize: 14),

          markerDecoration: BoxDecoration(
            color: darkColor,
            shape: BoxShape.circle,
          ),

          markersMaxCount: 1,
        ),

        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: primaryColor,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: primaryColor,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: 12),
        ),

        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: primaryColor.withOpacity(0.7),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
