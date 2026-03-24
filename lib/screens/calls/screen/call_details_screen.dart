import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/info.dart';

class CallDetailsScreen extends StatelessWidget {
  const CallDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Calls",
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert_outlined, size: 27, color: whiteColor),
          ),
        ],
      ),
      body: Transform.translate(
        offset: Offset(0, -2),
        child: ListView(
          children: [
            const SizedBox(height: 8),

            Transform.translate(
              offset: Offset(0, -6),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: info.length,
                itemBuilder: (context, index) {
                  final user = info[index];
                  final bool isMissed = index % 3 == 1;

                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 16, right: 6),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(
                        user['profilePic']?.toString() ?? '',
                      ),
                    ),
                    title: Text(
                      user['name']?.toString() ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14.5,
                        color: isMissed ? Colors.red : whiteColor,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        SvgPicture.asset(
                          isMissed
                              ? "assets/svg/missed.svg"
                              : "assets/svg/outgoing.svg",
                          width: 16,
                          height: 16,
                          color: isMissed ? Colors.grey : Colors.grey,
                        ),
                        SizedBox(width: 6),
                        Text(
                          isMissed ? "Missed" : "Outgoing",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user['time']?.toString() ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
