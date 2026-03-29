import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';

class CreateServerScreen extends StatefulWidget {
  const CreateServerScreen({super.key});
  @override
  State<CreateServerScreen> createState() => _CreateServerScreenState();
}

class _CreateServerScreenState extends State<CreateServerScreen> {
  final TextEditingController _serverNameController = TextEditingController(
    text: "mobbin's server",
  );

  @override
  void dispose() {
    _serverNameController.dispose();
    super.dispose();
  }

  void _showCreateServerDialog(BuildContext context) {
    TextEditingController dialogController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: const Text(
          'Create Server',
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: dialogController,
          style: const TextStyle(color: whiteColor),
          decoration: InputDecoration(
            hintText: 'Enter server name',
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: tabColor),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (dialogController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server "${dialogController.text}" created!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter server name'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(color: tabColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                  color: Colors.white60,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2D31),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: TextField(
                  controller: _serverNameController,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () => _serverNameController.clear(),
                      icon: const Icon(
                        Icons.cancel,
                        color: Colors.white38,
                        size: 26,
                      ),
                    ),
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
                      text: "By creating a server, you agree to MineChat",
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
                  onPressed: () => _showCreateServerDialog(context),

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
