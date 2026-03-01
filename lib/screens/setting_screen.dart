import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/features/app/welcome/welcome_page.dart';
import 'package:whatsapp_clone/features/auth/repository/auth_providers.dart';
import 'package:whatsapp_clone/screens/settings/account_screen.dart';
import 'package:whatsapp_clone/screens/settings/chats_screen.dart';
import 'package:whatsapp_clone/screens/settings/help_screen.dart';
import 'package:whatsapp_clone/screens/settings/invite_screen.dart';
import 'package:whatsapp_clone/screens/settings/notifications_screen.dart';
import 'package:whatsapp_clone/screens/settings/privacy_screen.dart';
import 'package:whatsapp_clone/screens/settings/profile_screen.dart';
import 'package:whatsapp_clone/screens/settings/starrted_message_screen.dart';
import 'package:whatsapp_clone/screens/settings/storage_screen.dart';
import 'package:whatsapp_clone/screens/settings/theme_screen.dart';
import 'package:whatsapp_clone/widgets/helpful_widgets/profilepic.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff1e2023),
        title: const Text('Logout', style: TextStyle(color: whiteColor)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: whiteColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: whiteColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(firebaseAuthProvider).signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomePage()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: backgroundColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),

        title: const Text(
          "Settings",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 12),
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: searchBarColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              style: const TextStyle(color: whiteColor),
              cursorColor: Colors.green,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 6),
                  child: Icon(Icons.search_rounded, color: Colors.grey),
                ),
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 9.6),
              ),
            ),
          ),
          SizedBox(height: 18),
          _profileTile(context, ref),
          SizedBox(height: 20),

          Text(
            "Personal info",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          SizedBox(height: 2),
          _svgTile(
            svgPath: "assets/svg/account.svg",
            "Account",
            iconSize: 24,
            onTap: () => _go(context, const AccountScreen()),
          ),

          _svgTile(
            svgPath: "assets/svg/privacy1.svg",
            "Privacy",
            iconSize: 28,
            onTap: () => _go(context, const PrivacyScreen()),
          ),

          SizedBox(height: 10),
          Text('General', style: TextStyle(color: Colors.grey, fontSize: 13)),
          SizedBox(height: 5),
          _svgTile(
            icon: Icons.notifications_outlined,
            "Notifications",
            onTap: () => _go(context, const NotificationsScreen()),
          ),

          _svgTile(
            svgPath: "assets/svg/photo.svg",
            "Photos & videos",
            onTap: () => _go(context, const StorageScreen()),
          ),
          _svgTile(
            svgPath: "assets/svg/chat_icon.svg",
            "Chats",
            iconSize: 27,
            onTap: () => _go(context, const ChatsScreen()),
          ),
          _svgTile(
            icon: Icons.palette_outlined,
            "Themes",
            onTap: () => _go(context, const ThemeScreen()),
          ),
          _svgTile(
            svgPath: "assets/svg/call.svg",
            "Call",
            iconSize: 39,
            onTap: () => _go(context, const HelpScreen()),
          ),
          _svgTile(
            svgPath: "assets/svg/friends.svg",
            "Friends",
            iconSize: 26,
            onTap: () => _go(context, const StarrtedMessageScreen()),
          ),
          _svgTile(
            svgPath: "assets/svg/language.svg",
            "Language",
            iconSize: 20,
            onTap: () => _go(context, const StarrtedMessageScreen()),
          ),
          _svgTile(
            svgPath: "assets/svg/folders.svg",
            "Back up and restore",
            iconSize: 22,
            onTap: () => _go(context, const StarrtedMessageScreen()),
          ),

          _svgTile(
            svgPath: "assets/svg/invite.svg",
            "Invite a friend",
            iconSize: 24,
            onTap: () => _go(context, const InviteScreen()),
          ),
          SizedBox(height: 10),
          Text(
            "Help and feedback",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          SizedBox(height: 5),
          _svgTile(
            icon: Icons.help_outline,
            "Help center",
            iconSize: 23,
            onTap: () => _go(context, const HelpScreen()),
          ),

          _svgTile(
            icon: Icons.feedback_outlined,
            "Send feedback",
            iconSize: 23,
            onTap: () => _go(context, const HelpScreen()),
          ),
          _svgTile(
            icon: Icons.description_outlined,
            "Terms and privacy policy",
            iconSize: 23,
            onTap: () => _go(context, const StorageScreen()),
          ),
          _svgTile(
            icon: Icons.info_outline,
            "App info",
            iconSize: 23,
            onTap: () => _go(context, const StorageScreen()),
          ),

          _svgTile(
            svgPath: "assets/svg/logout.svg",
            "Logout",
            color: Colors.redAccent,
            onTap: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _profileTile(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => Row(
        children: const [
          CircleAvatar(radius: 28, backgroundColor: Colors.grey),
          SizedBox(width: 12),
          Text("Loading...", style: TextStyle(color: whiteColor)),
        ],
      ),
      error: (err, stack) => Row(
        children: const [
          CircleAvatar(radius: 28, backgroundColor: Colors.grey),
          SizedBox(width: 12),
          Text("Loading...", style: TextStyle(color: whiteColor)),
        ],
      ),
      data: (user) {
        if (user.profilePic.isEmpty) {
          return Row(
            children: const [
              CircleAvatar(radius: 34, backgroundColor: Colors.grey),
              SizedBox(width: 12),
              Text("No profile picture", style: TextStyle(color: whiteColor)),
            ],
          );
        }

        return InkWell(
          onTap: () => _go(context, const ProfileScreen()),
          child: Row(
            children: [
              profileAvatar(radius: 28, photoUrl: user.profilePic, image: null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayname,
                      style: const TextStyle(color: whiteColor, fontSize: 18),
                    ),
                    Text(
                      user.bio?.isNotEmpty == true ? user.bio! : "Hey there!",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _svgTile(
    String title, {
    String? svgPath,
    IconData? icon,
    VoidCallback? onTap,
    double iconSize = 22,
    Color? color,

    VoidCallback? onIconPressed,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 28,
        height: 30,
        child: Center(
          child: icon != null
              ? IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onIconPressed ?? onTap,
                  icon: Icon(icon, size: iconSize, color: color ?? whiteColor),
                )
              : SvgPicture.asset(
                  svgPath!,
                  width: iconSize,
                  height: iconSize,
                  color: color ?? whiteColor,
                  fit: BoxFit.contain,
                ),
        ),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
    );
  }

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
