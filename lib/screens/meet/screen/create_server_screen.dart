import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/meet/screen/server_list_screen.dart';
import 'package:on_peace/widgets/helpful_widgets/info_popup.dart';

class CreateServerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> servers;
  const CreateServerScreen({super.key, required this.servers});
  @override
  State<CreateServerScreen> createState() => _CreateServerScreenState();
}

class _CreateServerScreenState extends State<CreateServerScreen> {
  final TextEditingController _serverNameController = TextEditingController();
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _serverNameController.addListener(() {
      setState(() {
        _showClear = _serverNameController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _serverNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                ],
              ),
              const SizedBox(height: 0),
              const Center(
                child: Text(
                  'Create Your Server',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: whiteColor,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Center(
                child: Text(
                  'Your server is where you and your friends hang out. \nMake yours and start talking',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white54,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 28,
                            color: whiteColor,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'UPLOAD',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: whiteColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -3,
                      top: 1,
                      child: Container(
                        width: 37,
                        height: 37,
                        decoration: const BoxDecoration(
                          color: uiColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: whiteColor,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Server name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: whiteColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: TextField(
                  controller: _serverNameController,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: whiteColor,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter Server's name",
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 15,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    suffixIcon: _showClear
                        ? IconButton(
                            onPressed: () => _serverNameController.clear(),
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.white38,
                              size: 22,
                            ),
                          )
                        : null,
                  ),
                  cursorColor: uiColor,
                ),
              ),
              const SizedBox(height: 18),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.white54),
                  children: [
                    TextSpan(
                      text: "By creating a server, you agree to OnPeace",
                    ),
                    TextSpan(
                      text: ' Community Guidelines.',
                      style: TextStyle(color: uiColor),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 55,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_serverNameController.text.isNotEmpty) {
                      widget.servers.add({
                        'name': _serverNameController.text,
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'channels': [
                          {'name': 'general', 'type': 'text'},
                          {'name': 'General', 'type': 'voice'},
                        ],
                      });

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ServerListScreen(servers: widget.servers),
                        ),
                      );
                    } else {
                      InfoPopup.show(context, 'Please Enter Server Name');
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: uiColor,
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
                      color: whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
