import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/diary/screen/calendar_screen.dart';
import 'package:whatsapp_clone/screens/diary/screen/diary_tab_screen.dart';
import 'package:whatsapp_clone/screens/diary/screen/entry_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  int selectedTab = 0;

  final List<Widget> _screens = const [
    EntryScreen(),
    CalenderScreen(),
    DiaryTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade800,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 39,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue, width: 1.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tabButton("Entry", 0),
              _tabButton("Calendar", 1),
              _tabButton("Diary", 2),
            ],
          ),
        ),
        centerTitle: true,
      ),

      body: _screens[selectedTab],
    );
  }

  Widget _tabButton(String text, int index) {
    bool selected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? Colors.blue : whiteColor),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? whiteColor : Colors.blue,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
