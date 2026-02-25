import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/friends/user_search.dart';

class FriendsNewchat extends StatefulWidget {
  const FriendsNewchat({super.key});

  @override
  State<FriendsNewchat> createState() => _FriendsNewchatState();
}

class _FriendsNewchatState extends State<FriendsNewchat> {
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: searchBarColor, height: 1),
        ),
        leading: isSearching
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios),
              ),
        title: isSearching
            ? Container(
                height: 45,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: searchBarColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: searchController,
                  cursorColor: uiColor,
                  autofocus: true,
                  style: TextStyle(color: whiteColor),
                  decoration: InputDecoration(
                    hintText: "Search",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close, color: whiteColor),
                      onPressed: () {
                        setState(() {
                          searchController.clear();
                          isSearching = false;
                        });
                      },
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              )
            : Text(
                "New Chat",
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: isSearching
            ? []
            : [
                IconButton(
                  icon: Icon(Icons.search, color: whiteColor, size: 27),
                  onPressed: () {
                    setState(() {
                      isSearching = true;
                    });
                  },
                ),
                Icon(Icons.more_vert, color: whiteColor, size: 27),
                SizedBox(width: 10),
              ],
      ),
      body: ListView(
        children: [
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserSearch()),
              );
            },
            leading: SvgPicture.asset(
              "assets/svg/addfriends.svg",
              width: 30,
              height: 30,
              color: whiteColor,
            ),
            title: Text(
              "Add Friends",
              style: TextStyle(
                color: whiteColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            onTap: () {},
            leading: SvgPicture.asset(
              "assets/svg/addgroup.svg",
              width: 34,
              height: 34,
              color: whiteColor,
            ),
            title: Text(
              "New Group",
              style: TextStyle(
                color: whiteColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const UserTile(
            name: "Aakash Frnd",
            bio: "Hey there! I am using WhatsApp.",
          ),
          UserTile(name: "Aaryan B1", bio: "Available"),
          UserTile(name: "Aman Clg", bio: "Busy right now"),
          UserTile(name: "Aaryan B1", bio: "Available"),
          UserTile(name: "Aaryan B1", bio: "Available"),
          UserTile(name: "Aaryan B1", bio: "Available"),
          UserTile(name: "Aaryan B1", bio: "Available"),
          UserTile(name: "Aaryan B1", bio: "Available"),
          UserTile(name: "Aaryan B1", bio: "Available"),
          UserTile(name: "Aaryan B1", bio: "Available"),
          UserTile(name: "Aaryan B1", bio: "Available"),
          UserTile(name: "Aaryan B1", bio: "Available"),
          UserTile(name: "Aaryan B1", bio: "Available"),
          UserTile(name: "Aaryan B1", bio: "Available"),
        ],
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  final String name;
  final String bio;
  const UserTile({super.key, required this.name, required this.bio});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey.shade700,
        child: Text(
          name[0],
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        bio,
        style: TextStyle(color: Colors.grey, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
