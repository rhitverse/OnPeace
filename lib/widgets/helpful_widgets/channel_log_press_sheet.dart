import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';

class ChannelLongPressSheet {
  static void show(BuildContext context, String channelName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                channelName,
                style: const TextStyle(
                  color: whiteColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.grey),

              ListTile(
                leading: const Icon(Icons.edit, color: whiteColor),
                title: const Text(
                  "Edit Channel",
                  style: TextStyle(color: whiteColor),
                ),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "Delete Channel",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}
