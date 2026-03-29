import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:on_peace/colors.dart';

class MyMessageCard extends StatelessWidget {
  final String message;
  final String date;
  const MyMessageCard({super.key, required this.message, required this.date});

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isWeb ? 62 : 10, vertical: 1),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * (isWeb ? 0.78 : 0.85),
          ),
          decoration: BoxDecoration(
            color: messageColor,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14, 8, isWeb ? 81 : 81, 10),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xffF7F8FA),
                    height: 1.25,
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 6,
                child: Row(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SvgPicture.asset(
                      'assets/svg/Check_mark.svg',
                      color: Color(0xff02C0EB),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
