import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whatsapp_clone/screens/diary/controller/diary_controller.dart';
import 'package:whatsapp_clone/screens/diary/screen/calendar_screen.dart';
import 'package:whatsapp_clone/screens/diary/screen/entry_screen.dart';
import 'package:whatsapp_clone/screens/diary/screen/diary_tab_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiaryController()..listenToEntries(),
      child: Scaffold(
        backgroundColor: Colors.blue.shade800,
        appBar: AppBar(
          backgroundColor: Colors.white,
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
        // ✅ 3 screens, 3 children — index kabhi out of range nahi hoga
        body: IndexedStack(
          index: selectedTab,
          children: const [
            EntryScreen(), // index 0
            CalenderScreen(), // index 1
            DiaryTabScreen(), // index 2
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    bool selected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? Colors.blue : Colors.white),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.blue,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
