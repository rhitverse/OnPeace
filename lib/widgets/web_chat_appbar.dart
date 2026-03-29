import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/info.dart';

class WebChatAppbar extends StatelessWidget {
  const WebChatAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.072,
      width: MediaQuery.of(context).size.width * 0.70,
      padding: const EdgeInsets.all(10),
      color: webAppBarColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundImage: NetworkImage(
                  "https://upload.wikimedia.org/wikipedia/en/8/8b/ST3_Steve_Harrington_portrait.jpg?20191213000350",
                ),
                radius: 20,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.01),
              Text(
                info[0]['name'].toString(),
                style: const TextStyle(fontSize: 18, color: whiteColor),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search_outlined, color: whiteColor),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert_outlined, color: whiteColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
