import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';

class SenderMessageCard extends StatelessWidget {
  final String message;
  final String date;
  const SenderMessageCard({
    super.key,
    required this.message,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isWeb ? 62 : 10, vertical: 1),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * (isWeb ? 0.78 : 0.85),
          ),
          decoration: BoxDecoration(
            color: senderMessageColor,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14, 8, isWeb ? 62 : 62, 10),
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
                child: Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
