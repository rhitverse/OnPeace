import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/core/providers/unread_count_provider.dart';
import 'package:whatsapp_clone/screens/Notifications/notification_screen.dart';
import 'package:whatsapp_clone/screens/chat/Screens/chats_control.dart';
import 'package:whatsapp_clone/screens/diary/screen/diary_screen.dart';
import 'package:whatsapp_clone/screens/friends/friends_newchat.dart';
import 'package:whatsapp_clone/screens/friends/qr_scanner.dart';
import 'package:whatsapp_clone/screens/friends/user_search.dart';
import 'package:whatsapp_clone/screens/meet/server_screen.dart';
import 'package:whatsapp_clone/screens/setting_screen.dart';
import 'package:whatsapp_clone/screens/settings/calls/calls_screen.dart';
import 'package:whatsapp_clone/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MobileScreenLayout extends ConsumerStatefulWidget {
  const MobileScreenLayout({super.key});

  @override
  ConsumerState<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

class _MobileScreenLayoutState extends ConsumerState<MobileScreenLayout> {
  int _currentIndex = 0;
  OverlayEntry? _menuOverlay;
  bool _isMenuOpen = false;

  List<Map<String, dynamic>> servers = [];

  void _toggleMenu(BuildContext context) {
    if (_isMenuOpen) {
      _menuOverlay?.remove();
      _menuOverlay = null;
      setState(() => _isMenuOpen = false);
      return;
    }
    final overlay = Overlay.of(context);
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);

    _menuOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _toggleMenu(context),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: position.dy + 95,
            right: 10,
            child: Material(
              color: searchBarColor,
              elevation: 8,
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: 180,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_add, color: whiteColor),
                      title: const Text(
                        "Add Friend",
                        style: TextStyle(color: whiteColor),
                      ),
                      onTap: () {
                        _toggleMenu(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UserSearch()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.bookmark_add,
                        color: whiteColor,
                      ),
                      title: const Text(
                        "Dear Diary",
                        style: TextStyle(
                          color: whiteColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        _toggleMenu(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DiaryScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings, color: whiteColor),
                      title: const Text(
                        "Settings",
                        style: TextStyle(color: whiteColor),
                      ),
                      onTap: () {
                        _toggleMenu(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_menuOverlay!);
    setState(() => _isMenuOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _currentIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: backgroundColor,
              scrolledUnderElevation: 0,
              elevation: 0,
              title: Row(
                children: [
                  Text(
                    'Messages',
                    style: TextStyle(
                      color: whiteColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: Icon(
                    _isMenuOpen ? Icons.close : Icons.add,
                    color: whiteColor,
                    size: 32,
                  ),

                  onPressed: () => _toggleMenu(context),
                ),
              ],

              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(42),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    width * 0.03,
                    0,
                    width * 0.03,
                    1,
                  ),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: searchBarColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      style: const TextStyle(color: whiteColor),
                      cursorColor: Colors.green,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(right: 15, left: 17),
                          child: SvgPicture.asset(
                            "assets/svg/search_icon.svg",
                            width: 20,
                          ),
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const QrScanner(),
                                ),
                              );
                            },
                            icon: SvgPicture.asset(
                              "assets/svg/scan.svg",
                              width: 20,
                              color: whiteColor,
                            ),
                          ),
                        ),
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 9.6),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ChatControl(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
          const NotificaionScreen(),
          const ServerScreen(),
          const CallsScreen(),
        ],
      ),

      floatingActionButton: _currentIndex == 0
          ? GestureDetector(
              onTap: () {
                print("clicked $GestureDetector");
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FriendsNewchat()),
                );
              },
              child: Container(
                height: 58,
                width: 57,
                decoration: BoxDecoration(
                  color: uiColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SvgPicture.asset(
                    "assets/svg/newchat.svg",
                    width: 36,
                    color: whiteColor,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: Builder(
        builder: (context) {
          final chatCount = ref.watch(unreadChatsCountProvider).value ?? 0;
          final notifCount =
              ref.watch(unreadNotificationsCountProvider).value ?? 0;

          return CustomBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            chatCount: chatCount,
            notificationCount: notifCount,
          );
        },
      ),
    );
  }
}
