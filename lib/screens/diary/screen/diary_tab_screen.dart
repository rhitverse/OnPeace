import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/diary/controller/diary_controller.dart';
import 'package:whatsapp_clone/screens/diary/screen/entry_screen.dart';

class DiaryTabScreen extends StatelessWidget {
  const DiaryTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DiaryController>();
    return Column(
      children: [
        Expanded(
          child: controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: whiteColor),
                )
              : controller.entries.isEmpty
              ? const Center(
                  child: Text(
                    "entry not exists",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.entries.length,
                  itemBuilder: (context, index) {
                    final e = controller.entries[index];
                    return DiaryCard(
                      entry: e,
                      onDelete: () => controller.deleteEntry(e.id),
                      onEdit: () => _showEditDialog(context, controller, e),
                    );
                  },
                ),
        ),
        _BottomBar(count: controller.entries.length),
      ],
    );
  }

  void _showEditDialog(BuildContext context, DiaryController ctrl, e) {
    final textController = TextEditingController(text: e.text);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Entry", style: TextStyle(color: Colors.blue)),
        content: TextField(
          controller: textController,
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await ctrl.updateEntry(e.id, textController.text);
              Navigator.pop(context);
            },
            child: const Text("Update", style: TextStyle(color: whiteColor)),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int count;
  const _BottomBar({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      color: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.edit, color: whiteColor, size: 24),
          Text(
            "$count diary",
            style: const TextStyle(
              color: whiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
