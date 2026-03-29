import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:on_peace/colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int chatCount;
  final int notificationCount;
  final int meetCount;
  final int callCount;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.chatCount = 0,
    this.notificationCount = 0,
    this.meetCount = 0,
    this.callCount = 0,
  });

  Widget navIcon({
    required String unselectedAsset,
    required String selectedAsset,
    required int index,
    double size = 24,
    int badgeCount = 0,
  }) {
    final bool isSelected = currentIndex == index;

    final icon = SvgPicture.asset(
      isSelected ? selectedAsset : unselectedAsset,
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(whiteColor, BlendMode.srcIn),
    );
    if (badgeCount == 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            padding: const EdgeInsets.all(3),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              badgeCount > 99 ? '99+' : '$badgeCount',
              style: const TextStyle(
                color: whiteColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: backgroundColor,
        selectedItemColor: whiteColor,
        unselectedItemColor: whiteColor,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(
            icon: navIcon(
              unselectedAsset: 'assets/svg/chat2.svg',
              selectedAsset: 'assets/svg/chats2.svg',
              index: 0,
              size: 28,
              badgeCount: chatCount,
            ),
            label: "Chats",
          ),

          BottomNavigationBarItem(
            icon: navIcon(
              unselectedAsset: 'assets/svg/notifications.svg',
              selectedAsset: 'assets/svg/notification.svg',
              index: 1,
              size: 23,
              badgeCount: notificationCount,
            ),
            label: "Notifications",
          ),
          BottomNavigationBarItem(
            icon: navIcon(
              unselectedAsset: 'assets/svg/meet.svg',
              selectedAsset: 'assets/svg/groups2.svg',
              index: 2,
              size: 26,
              badgeCount: meetCount,
            ),
            label: "Meet",
          ),
          BottomNavigationBarItem(
            icon: navIcon(
              unselectedAsset: 'assets/svg/call.svg',
              selectedAsset: 'assets/svg/call1.svg',
              index: 3,
              size: 26,
              badgeCount: callCount,
            ),
            label: "Calls",
          ),
        ],
      ),
    );
  }
}
