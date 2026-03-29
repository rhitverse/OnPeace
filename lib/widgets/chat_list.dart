import 'package:flutter/material.dart';
import 'package:on_peace/info.dart';
import 'package:on_peace/widgets/my_message_card.dart';
import 'package:on_peace/widgets/sender_message_card.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90, top: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        if (messages[index]['isMe'] == true) {
          return MyMessageCard(
            message: messages[index]['text'].toString(),
            date: messages[index]['time'].toString(),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SenderMessageCard(
            message: messages[index]['text'].toString(),
            date: messages[index]['time'].toString(),
          ),
        );
      },
    );
  }
}
