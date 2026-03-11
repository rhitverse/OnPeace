import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade800,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () {
            Navigator.pop(context);
          },
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

      body: Column(
        children: [
          const SizedBox(height: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                DiaryCard(
                  month: "SEP",
                  day: "13",
                  text:
                      "The little beautiful baby succulent! Can't take the eyes off them.",
                ),
                DiaryCard(
                  month: "SEP",
                  day: "13",
                  text:
                      "The best and most expensive iPhone you have ever created.",
                ),
                DiaryCard(
                  month: "AUG",
                  day: "10",
                  text: "Today I started the 'Start a business today' course.",
                ),
                DiaryCard(
                  month: "JUL",
                  day: "30",
                  text:
                      "Whaaaaaaa?? John Snow! You can't do this to your aunt!",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    bool selected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
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

class DiaryCard extends StatelessWidget {
  final String month;
  final String day;
  final String text;

  const DiaryCard({
    super.key,
    required this.month,
    required this.day,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                month,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              Text(
                day,
                style: const TextStyle(
                  fontSize: 33,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
