import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:on_peace/colors.dart';

class WebChatBox extends StatefulWidget {
  const WebChatBox({super.key});

  @override
  State<WebChatBox> createState() => _WebChatBoxState();
}

class _WebChatBoxState extends State<WebChatBox> {
  final TextEditingController _controller = TextEditingController();
  bool isTyping = false;
  bool _isMicHover = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.059,
      width: MediaQuery.of(context).size.width * 0.68,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: chatBarMessage,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add, color: whiteColor, size: 24),
          ),
          SizedBox(width: 12),
          SvgPicture.asset(
            'assets/svg/Sticker.svg',
            color: whiteColor,
            width: 26,
            height: 26,
          ),

          Expanded(
            child: TextField(
              controller: _controller,
              cursorColor: Colors.green,
              style: const TextStyle(fontSize: 15, color: whiteColor),
              onChanged: (value) {
                setState(() {
                  isTyping = value.trim().isNotEmpty;
                });
              },
              decoration: InputDecoration(
                hintText: 'Type a message',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    width: 0,
                    style: BorderStyle.none,
                  ),
                ),
              ),
            ),
          ),
          isTyping
              ? CircleAvatar(
                  radius: 20,
                  backgroundColor: uiColor,
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.black,
                      size: 21,
                    ),
                    onPressed: () {
                      print("Send: ${_controller.text}");
                    },
                  ),
                )
              : MouseRegion(
                  onEnter: (_) {
                    setState(() => _isMicHover = true);
                  },
                  onExit: (_) {
                    setState(() => _isMicHover = false);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _isMicHover ? uiColor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMicHover ? Icons.mic : Icons.mic_none_outlined,
                      color: _isMicHover ? Colors.black : whiteColor,
                      size: 24,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
