import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/diary/screen/diary_data.dart';

class CalenderScreen extends StatefulWidget {
  const CalenderScreen({super.key});

  @override
  State<CalenderScreen> createState() => _CalenderScreenState();
}

class _CalenderScreenState extends State<CalenderScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  Set<String> get _entryDates {
    return diaryEntries.map((e) {
      final monthMap = {
        "JAN": 1,
        "FEB": 2,
        "MAR": 3,
        "APR": 4,
        "MAY": 5,
        "JUN": 6,
        "JUL": 7,
        "AUG": 8,
        "SEP": 9,
        "OCT": 10,
        "NOV": 11,
        "DEC": 12,
      };
      final m = monthMap[e["month"]] ?? 1;
      final d = int.tryParse(e["day"] ?? "0") ?? 0;
      return "$m-$d";
    }).toSet();
  }

  bool _hasEntry(DateTime day) =>
      _entryDates.contains("${day.month}-${day.day}");

  List<Map<String, String>> get _selectedEntries {
    if (_selectedDay == null) return [];
    final monthMap = {
      1: "JAN",
      2: "FEB",
      3: "MAR",
      4: "APR",
      5: "MAY",
      6: "JUN",
      7: "JUL",
      8: "AUG",
      9: "SEP",
      10: "OCT",
      11: "NOV",
      12: "DEC",
    };
    final selectedMonth = monthMap[_selectedDay!.month];
    final selectedDay = _selectedDay!.day.toString();
    return diaryEntries
        .where((e) => e["month"] == selectedMonth && e["day"] == selectedDay)
        .toList();
  }

  void _prevMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
  });

  void _nextMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
  });

  static const _monthNames = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  void _showDatePicker() {
    final int startYear = 2000;
    final int endYear = 2050;

    int tempDay = _focusedMonth.day;
    int tempMonth = _focusedMonth.month;
    int tempYear = _focusedMonth.year;

    int daysInMonth(int m, int y) => DateTime(y, m + 1, 0).day;

    final dayController = FixedExtentScrollController(initialItem: tempDay - 1);
    final monthController = FixedExtentScrollController(
      initialItem: tempMonth - 1,
    );
    final yearController = FixedExtentScrollController(
      initialItem: tempYear - startYear,
    );

    const double itemH = 46.0;

    Widget column({
      required FixedExtentScrollController ctrl,
      required int itemCount,
      required String Function(int) label,
      required bool Function(int) isSel,
      required void Function(int) onChanged,
    }) {
      return Expanded(
        child: ListWheelScrollView.useDelegate(
          controller: ctrl,
          itemExtent: itemH,
          perspective: 0.004,
          diameterRatio: 2.2,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (ctx, i) {
              final selected = isSel(i);
              return Center(
                child: Text(
                  label(i),
                  style: TextStyle(
                    fontSize: selected ? 20 : 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? Colors.black87 : Colors.grey.shade400,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 230,
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            height: itemH,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            column(
                              ctrl: dayController,
                              itemCount: daysInMonth(tempMonth, tempYear),
                              label: (i) => "${i + 1}",
                              isSel: (i) => i + 1 == tempDay,
                              onChanged: (i) => setS(() => tempDay = i + 1),
                            ),
                            Expanded(
                              flex: 2,
                              child: ListWheelScrollView.useDelegate(
                                controller: monthController,
                                itemExtent: itemH,
                                perspective: 0.004,
                                diameterRatio: 2.2,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (i) {
                                  setS(() {
                                    tempMonth = i + 1;
                                    final maxD = daysInMonth(
                                      tempMonth,
                                      tempYear,
                                    );
                                    if (tempDay > maxD) tempDay = maxD;
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 12,
                                  builder: (ctx, i) {
                                    final selected = i + 1 == tempMonth;
                                    return Center(
                                      child: Text(
                                        _monthNames[i],
                                        style: TextStyle(
                                          fontSize: selected ? 20 : 15,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: selected
                                              ? Colors.black87
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            column(
                              ctrl: yearController,
                              itemCount: endYear - startYear + 1,
                              label: (i) => "${startYear + i}",
                              isSel: (i) => startYear + i == tempYear,
                              onChanged: (i) {
                                setS(() {
                                  tempYear = startYear + i;
                                  final maxD = daysInMonth(tempMonth, tempYear);
                                  if (tempDay > maxD) tempDay = maxD;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _focusedMonth = DateTime(tempYear, tempMonth, 1);
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Apply",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildCalendarWidget(),
                if (_selectedDay != null && _selectedEntries.isNotEmpty)
                  _buildSelectedEntries()
                else
                  _buildAllEntries(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        _BottomBar(count: diaryEntries.length),
      ],
    );
  }

  Widget _buildCalendarWidget() {
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final int startWeekday = firstDayOfMonth.weekday % 7;

    final List<DateTime?> cells = List<DateTime?>.filled(
      startWeekday,
      null,
      growable: true,
    );
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }
    while (cells.length % 7 != 0) cells.add(null);

    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _prevMonth,
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                GestureDetector(
                  onTap: _showDatePicker,
                  child: Row(
                    children: [
                      Text(
                        "${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.blue,
                        size: 22,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _nextMonth,
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
                  .map(
                    (d) => SizedBox(
                      width: 38,
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: List.generate((cells.length / 7).ceil(), (row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (col) {
                      final cell = cells[row * 7 + col];
                      if (cell == null)
                        return const SizedBox(width: 38, height: 38);

                      final isToday =
                          cell.year == today.year &&
                          cell.month == today.month &&
                          cell.day == today.day;
                      final isSelected =
                          _selectedDay != null &&
                          cell.year == _selectedDay!.year &&
                          cell.month == _selectedDay!.month &&
                          cell.day == _selectedDay!.day;
                      final hasEntry = _hasEntry(cell);

                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedDay = isSelected ? null : cell;
                        }),
                        child: SizedBox(
                          width: 38,
                          height: 38,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isToday || isSelected)
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected && !isToday
                                        ? Colors.blue.shade200
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(
                                "${cell.day}",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: (isToday || isSelected)
                                      ? whiteColor
                                      : Colors.blue.shade800,
                                ),
                              ),
                              if (hasEntry && !isToday && !isSelected)
                                Positioned(
                                  bottom: 3,
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSelectedEntries() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "${_selectedDay!.day} ${_monthName(_selectedDay!.month)} ki entries",
              style: const TextStyle(
                color: whiteColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ..._selectedEntries.map(
            (e) => _CalendarEntryTile(text: e["text"]!, daysAgo: e["time"]!),
          ),
        ],
      ),
    );
  }

  Widget _buildAllEntries() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: diaryEntries.length,
      itemBuilder: (context, index) {
        final e = diaryEntries[index];
        return _CalendarEntryTile(
          text: e["text"]!,
          daysAgo: "${(index + 1) * 3} days ago",
        );
      },
    );
  }

  String _monthName(int month) {
    const names = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return names[month];
  }
}

class _CalendarEntryTile extends StatelessWidget {
  final String text, daysAgo;
  const _CalendarEntryTile({required this.text, required this.daysAgo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "· $daysAgo",
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade200),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.cloud_upload_outlined, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int count;
  const _BottomBar({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      color: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.format_list_bulleted, color: whiteColor, size: 24),
          Icon(Icons.edit, color: whiteColor, size: 24),
        ],
      ),
    );
  }
}
