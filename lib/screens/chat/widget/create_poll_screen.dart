import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';

class CreatePollScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const CreatePollScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  bool _allowMultiple = false;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    // Initialize with 2 default option fields
    _optionControllers.addAll([
      TextEditingController(),
      TextEditingController(),
    ]);
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  void _createPoll() {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      _showError('Please enter a question');
      return;
    }

    final options = _optionControllers
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) => c.text.trim())
        .toList();

    if (options.length < 2) {
      _showError('Please add at least 2 options');
      return;
    }

    // Return poll data
    final pollData = {
      'question': question,
      'options': options,
      'allowMultiple': _allowMultiple,
      'isAnonymous': _isAnonymous,
    };

    Navigator.pop(context, pollData);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Poll'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question field
            const Text(
              'Question',
              style: TextStyle(
                color: whiteColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              style: const TextStyle(color: whiteColor),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'What do you want to ask?',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: uiColor),
                ),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Options header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Options',
                  style: TextStyle(
                    color: whiteColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_optionControllers.length}/10',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Option fields
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _optionControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[index],
                          style: const TextStyle(color: whiteColor),
                          decoration: InputDecoration(
                            hintText: 'Option ${index + 1}',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[800]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: uiColor),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          maxLines: 1,
                        ),
                      ),
                      if (_optionControllers.length > 2)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removeOption(index),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Add option button
            if (_optionControllers.length < 10)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: whiteColor,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Settings
            const Text(
              'Settings',
              style: TextStyle(
                color: whiteColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingTile(
              title: 'Allow Multiple Votes',
              subtitle: 'Users can select more than one option',
              value: _allowMultiple,
              onChanged: (value) {
                setState(() => _allowMultiple = value);
              },
            ),
            const SizedBox(height: 12),
            _buildSettingTile(
              title: 'Anonymous Poll',
              subtitle: 'Hide voter identities (for privacy)',
              value: _isAnonymous,
              onChanged: (value) {
                setState(() => _isAnonymous = value);
              },
            ),
            const SizedBox(height: 32),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createPoll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff25D366),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create Poll',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: whiteColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xff25D366),
          ),
        ],
      ),
    );
  }
}
