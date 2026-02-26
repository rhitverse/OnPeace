import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';

class NotificaionScreen extends StatelessWidget {
  const NotificaionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,

        title: Text(
          "Notifications",
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
