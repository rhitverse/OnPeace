import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/chat/Screens/chats_control.dart';
import 'package:on_peace/widgets/chat_filter_items.dart';
import 'package:on_peace/widgets/chat_list.dart';
import 'package:on_peace/widgets/web_chat_appbar.dart';
import 'package:on_peace/widgets/web_chat_box.dart';
import 'package:on_peace/widgets/web_profile_bar.dart';
import 'package:on_peace/widgets/web_search_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebScreenLayout extends StatefulWidget {
  const WebScreenLayout({super.key});

  @override
  State<WebScreenLayout> createState() => _WebScreenLayoutState();
}

class _WebScreenLayoutState extends State<WebScreenLayout> {
  int? selectedChatIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: webBackgroundColor,
      body: Row(
        children: [
          Container(
            width: 70,
            color: const Color(0xFF1d1f1f),
            child: Column(
              children: [
                SizedBox(height: 20),
                SvgPicture.asset(
                  'assets/svg/chat.svg',
                  color: Colors.grey,
                  height: 16,
                  width: 16,
                ),
                SizedBox(height: 25),
                SvgPicture.asset(
                  'assets/svg/update.svg',
                  color: Colors.grey,
                  height: 20,
                  width: 20,
                ),
                SizedBox(height: 22),
                SvgPicture.asset(
                  'assets/svg/tab.svg',
                  color: Colors.grey,
                  height: 23,
                  width: 23,
                ),
                SizedBox(height: 16),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.groups_rounded,
                    color: Colors.grey,
                    size: 30,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10,
                    top: 10,
                    right: 14,
                    left: 14,
                  ),
                  child: Divider(),
                ),
                SvgPicture.asset(
                  'assets/svg/metaAi.svg',
                  width: 20,
                  height: 20,
                ),
                Spacer(),
                SvgPicture.asset(
                  'assets/svg/image.svg',
                  color: Colors.grey,
                  width: 24,
                  height: 24,
                ),
                SizedBox(height: 10),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.settings_outlined, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundImage: NetworkImage(
                      'https://upload.wikimedia.org/wikipedia/commons/2/22/Joe_Keery_by_Gage_Skidmore.jpg',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 520,
            color: webBackgroundColor,
            child: Column(
              children: [
                const WebProfileBar(),
                const WebSearchBar(),
                const ChatFilterItems(isWeb: true),
                SizedBox(height: 17),
                Expanded(
                  child: ChatControl(
                    userId: FirebaseAuth.instance.currentUser!.uid,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/backgroundImage.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  WebChatAppbar(),
                  SizedBox(height: 26),
                  Expanded(child: ChatList()),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: WebChatBox(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
