import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/meet/widget/server_options_sheet.dart';
import 'package:on_peace/widgets/helpful_widgets/channel_log_press_sheet.dart';

class ServerListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> servers;
  final VoidCallback? onServerDeleted;

  const ServerListScreen({
    super.key,
    required this.servers,
    this.onServerDeleted,
  });

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  bool isExpanded = false;
  bool textExpanded = true;
  bool voiceExpanded = true;
  int selectedServerIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _createNewServer() {
    ServerOptionsSheet.show(context, widget.servers);
  }

  @override
  Widget build(BuildContext context) {
    if (selectedServerIndex >= widget.servers.length) {
      selectedServerIndex = 0;
    }

    final selectedServer = widget.servers.isNotEmpty
        ? widget.servers[selectedServerIndex]
        : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: CircleAvatar(
              backgroundColor: tabColor,
              child: Text(
                selectedServer?['name']?[0]?.toUpperCase() ?? 'S',
                style: const TextStyle(
                  color: whiteColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              selectedServer?['name'] ?? 'Server',
              style: const TextStyle(
                color: whiteColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right, color: whiteColor, size: 20),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  print("click");
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    "assets/svg/inviteF.svg",
                    width: 27,
                    height: 27,
                    color: whiteColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: isExpanded ? 70 : 0,
            color: backgroundColor,
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: isExpanded ? 1 : 0,
                child: SizedBox(
                  width: 70,
                  child: Column(
                    children: [
                      const SizedBox(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: widget.servers.length + 1,
                          itemBuilder: (context, index) {
                            if (index == widget.servers.length) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 20,
                                  left: 7.0,
                                  right: 7.0,
                                ),
                                child: InkWell(
                                  onTap: _createNewServer,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: whiteColor,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (index == selectedServerIndex) {
                              return const SizedBox.shrink();
                            }

                            final server = widget.servers[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                                horizontal: 7.0,
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedServerIndex = index;
                                  });
                                },
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey.shade700,
                                  child: Text(
                                    server['name']?[0]?.toUpperCase() ?? '?',
                                    style: const TextStyle(
                                      color: whiteColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: backgroundColor,
              child: ListView(
                children: [
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: searchBarColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: whiteColor),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: whiteColor),
                          hintText: "Search",
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          textExpanded = !textExpanded;
                        });
                      },
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          const Text(
                            "Text Channels",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            textExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_right,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  if (textExpanded)
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      minLeadingWidth: 0,
                      horizontalTitleGap: 8,
                      leading: SvgPicture.asset(
                        "assets/svg/hashtag.svg",
                        width: 22,
                        height: 22,
                        color: Colors.grey,
                      ),

                      title: const Text(
                        "general",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onLongPress: () {
                        ChannelLongPressSheet.show(context, "general");
                      },
                    ),

                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          voiceExpanded = !voiceExpanded;
                        });
                      },
                      child: Row(
                        children: [
                          Text(
                            "Voice Channels",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            voiceExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_right,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (voiceExpanded)
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      minLeadingWidth: 0,
                      horizontalTitleGap: 8,
                      leading: SvgPicture.asset(
                        "assets/svg/speaker.svg",
                        width: 22,
                        height: 22,
                        color: Colors.grey,
                      ),

                      title: const Text(
                        "General",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {},
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
