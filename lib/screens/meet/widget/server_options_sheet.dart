import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/meet/screen/create_server_screen.dart';

class ServerOptionsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> servers;

  const ServerOptionsSheet({super.key, required this.servers});

  static void show(BuildContext context, List<Map<String, dynamic>> servers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.95,
        child: ServerOptionsSheet(servers: servers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: whiteColor, size: 26),
            ),
          ),

          Expanded(
            child: Center(
              child: Align(
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  "assets/svg/friendempty.svg",
                  height: 320,
                  width: 320,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateServerScreen(servers: servers),
                  ),
                ).then((_) {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: whiteColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Create Server",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: uiColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Join Server",
                style: TextStyle(
                  fontSize: 16,
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
