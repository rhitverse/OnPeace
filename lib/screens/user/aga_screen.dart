import 'package:flutter/material.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:intl/intl.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/mobile_screen_layout.dart';

class AgaScreen extends StatefulWidget {
  const AgaScreen({super.key});

  @override
  State<AgaScreen> createState() => _AgaScreenState();
}

class _AgaScreenState extends State<AgaScreen> {
  DateTime? selectedDate;
  bool receiveEmails = true;
  String? errorText;

  String get formattedDate {
    if (selectedDate == null) return "";
    return DateFormat("MM/dd/yyyy").format(selectedDate!);
  }

  bool get isDobValid {
    if (selectedDate == null) return false;
    final now = DateTime.now();
    int age = now.year - selectedDate!.year;

    if (now.month < selectedDate!.month ||
        (now.month == selectedDate!.month && now.day < selectedDate!.day)) {
      age--;
    }
    return age >= 13;
  }

  void openDatePicker() async {
    final date = await DatePicker.showSimpleDatePicker(
      context,
      initialDate: DateTime(2004),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      dateFormat: "dd-MMMM_yyyy",
      locale: DateTimePickerLocale.en_us,
      titleText: "Date of Birth",
      textColor: whiteColor,
      backgroundColor: const Color(0xff2b2d31),
      itemTextStyle: const TextStyle(color: whiteColor, fontSize: 18),
      looping: false,
      confirmText: "CONFIRM",
      cancelText: "CANCEL",
    );

    if (date != null) {
      final age = DateTime.now().year - date.year;
      setState(() {
        errorText = age < 13 ? "Please enter a valid date of birth" : null;
        selectedDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff040406),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsGeometry.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: whiteColor),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "And,how old are you?",
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Date of Birth",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: openDatePicker,
                child: Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xff1e2023),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    selectedDate == null ? "DD / MM / YYYY" : formattedDate,
                    style: TextStyle(
                      color: selectedDate == null ? Colors.white38 : whiteColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 29,
                    child: Checkbox(
                      value: receiveEmails,
                      activeColor: uiColor,
                      onChanged: (value) {
                        setState(() {
                          receiveEmails = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        "Receive personalized emails with product announcements and offers designed around how you use App! (Optional)",
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'By clicking "Create Account" you agree to App\'s'
                'Terms of Service and have read the Privacy Policy',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isDobValid
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MobileScreenLayout(),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: uiColor,
                    disabledBackgroundColor: uiColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: whiteColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
