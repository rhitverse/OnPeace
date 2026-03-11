import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/models/diary_model.dart';
import 'package:whatsapp_clone/screens/diary/controller/diary_controller.dart';
import 'diary_data.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DiaryController>().listenToEntries());
  }

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
                    "entries not exists",
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
        _BottomBar(
          count: diaryEntries.length,
          onAdd: () => _showAddDialog(context, controller),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, DiaryController controller) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Entry", style: TextStyle(color: Colors.blue)),
        content: TextField(
          controller: textController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "What happend today...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              await controller.addEntry(textController.text);
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: whiteColor)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    DiaryController ctrl,
    DiaryModel e,
  ) {
    final textControlller = TextEditingController(text: e.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Entry", style: TextStyle(color: Colors.blue)),
        content: TextField(
          controller: textControlller,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              await ctrl.updateEntry(e.id, textControlller.text);
              Navigator.pop(context);
            },
            child: const Text("Update", style: TextStyle(color: whiteColor)),
          ),
        ],
      ),
    );
  }
}

class DiaryCard extends StatelessWidget {
  final DiaryModel entry;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const DiaryCard({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete, color: whiteColor),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, "Cancel"),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete,
      child: GestureDetector(
        onLongPress: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 62,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      entry.month,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      entry.day,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      entry.weekday,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 60, color: Colors.blue.shade100),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.time,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade300,
                          ),
                        ),
                        const Icon(
                          Icons.cloud_done_outlined,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;
  const _BottomBar({required this.count, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      color: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onAdd,
            child: const Icon(Icons.edit, color: whiteColor, size: 24),
          ),
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
