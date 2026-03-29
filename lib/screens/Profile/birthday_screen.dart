import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';

class BirthdayScreen extends StatefulWidget {
  final DateTime birthday;
  final bool showBirthday;
  final bool showBirthYear;

  final Function(DateTime dob) onBirthdayChanged;
  final Function(bool)? onShowBirthdayChanged;
  final Function(bool)? onShowBirthYearChanged;

  const BirthdayScreen({
    super.key,
    required this.onBirthdayChanged,
    required this.birthday,
    this.showBirthYear = true,
    this.showBirthday = true,
    this.onShowBirthdayChanged,
    this.onShowBirthYearChanged,
  });

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen> {
  late bool _showBirthday;
  late bool _showBirthYear;
  DateTime? _birthday;
  String? errorText;

  @override
  void initState() {
    super.initState();

    if (widget.birthday.year == DateTime.now().year &&
        widget.birthday.month == DateTime.now().month &&
        widget.birthday.day == DateTime.now().day) {
      _birthday = null;
    } else {
      _birthday = widget.birthday;
    }

    _showBirthYear = widget.showBirthYear;
    _showBirthday = widget.showBirthday;
  }

  Future<void> openDatePicker() async {
    final date = await DatePicker.showSimpleDatePicker(
      context,
      initialDate: _birthday ?? DateTime(2004, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      dateFormat: "dd-MMMM_yyyy",
      locale: DateTimePickerLocale.en_us,
      titleText: "Date of Birth",
      textColor: Colors.black,
      backgroundColor: whiteColor,
      itemTextStyle: const TextStyle(color: Colors.black, fontSize: 18),
      looping: false,
      confirmText: "CONFIRM",
      cancelText: "CANCEL",
    );

    if (date != null) {
      final now = DateTime.now();
      int age = now.year - date.year;

      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }

      setState(() {
        errorText = age < 13 ? "Please enter a valid date of birth" : null;
        _birthday = date;
      });

      if (age >= 13) {
        widget.onBirthdayChanged(date);
      }
    }
  }

  String get formattedDate => _birthday == null
      ? "DD / MM / YYYY"
      : DateFormat("d MMMM yyyy").format(_birthday!);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: const Text(
          "Birthday",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          InkWell(
            onTap: openDatePicker,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Divider(height: 1, thickness: 0.6, color: Colors.grey),
          ),

          if (errorText != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          waToggle(
            title: "Show my birthday",
            value: _showBirthday,
            onChanged: (value) {
              setState(() {
                _showBirthday = value;

                if (!_showBirthday) {
                  _showBirthYear = false;
                  widget.onShowBirthYearChanged?.call(false);
                }
              });

              widget.onShowBirthdayChanged?.call(value);
            },
          ),

          /// 🔥 SHOW YEAR TOGGLE
          if (_showBirthday)
            waToggle(
              title: "Show my birth year",
              value: _showBirthYear,
              onChanged: (value) {
                setState(() => _showBirthYear = value);
                widget.onShowBirthYearChanged?.call(value);
              },
            ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "if you choose to show your birthday, your friends will be able to see the date from your profile, the Home and Chat tabs, and more.",
              style: TextStyle(
                fontSize: 12.6,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget waToggle({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: whiteColor,
              activeTrackColor: uiColor,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
