import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/meet/screen/create_server_screen.dart';

class EmptyServerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> servers;
  final VoidCallback? onServerCreated;
  const EmptyServerScreen({
    super.key,
    required this.servers,
    this.onServerCreated,
  });

  @override
  State<EmptyServerScreen> createState() => _EmptyServerScreenState();
}

class _EmptyServerScreenState extends State<EmptyServerScreen> {
  void _createServer(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateServerScreen(servers: widget.servers),
      ),
    );
    if (widget.onServerCreated != null) {
      widget.onServerCreated!();
    }
  }

  void _joinServer(BuildContext context) {
    if (widget.servers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No servers available to join'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      if (widget.onServerCreated != null) {
        widget.onServerCreated!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,

        title: const Text(
          "Server",
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 27,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.10),
                Image.asset(
                  "assets/server.png",
                  height: 240,
                  width: 240,
                  fit: BoxFit.contain,
                  color: whiteColor,
                ),
                const SizedBox(height: 10),
                const Text(
                  "No server yet",
                  style: TextStyle(
                    fontSize: 22,
                    color: whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Join a Server or Create your own Server",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 19,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                SizedBox(
                  height: 55,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _createServer(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: whiteColor,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.grey, width: 0.5),
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
                  height: 55,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _joinServer(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: uiColor,
                      foregroundColor: whiteColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.grey, width: 0.5),
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
          ),
        ),
      ),
    );
  }
}
