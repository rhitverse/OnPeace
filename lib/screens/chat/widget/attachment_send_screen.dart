import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/chat/provider/chat_provider.dart';
import 'package:whatsapp_clone/screens/chat/provider/uploading_messages_provider.dart';

class AttachmentSendScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String receiverUid;
  final List<FileAttachment>? initialFiles;
  final Function? onFileUploadStart;

  const AttachmentSendScreen({
    super.key,
    required this.chatId,
    required this.receiverUid,
    this.initialFiles,
    this.onFileUploadStart,
  });

  @override
  ConsumerState<AttachmentSendScreen> createState() =>
      _AttachmentSendScreenState();
}

class _AttachmentSendScreenState extends ConsumerState<AttachmentSendScreen> {
  List<FileAttachment> selectedFiles = [];
  Set<int> sendingFileIndices = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialFiles != null && widget.initialFiles!.isNotEmpty) {
        setState(() {
          selectedFiles = widget.initialFiles!;
        });
      } else {
        _pickFiles();
      }
    });
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      for (var file in result.files) {
        if (file.path != null) {
          selectedFiles.add(
            FileAttachment(
              filePath: file.path!,
              fileName: file.name,
              fileSize: file.size,
              fileType: _getFileType(file.name),
            ),
          );
        }
      }
    });
  }

  FileType _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return FileType.image;
    } else if (['mp4', 'avi', 'mkv', 'mov', 'flv'].contains(ext)) {
      return FileType.video;
    } else if (['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'].contains(ext)) {
      return FileType.custom;
    }
    return FileType.custom;
  }

  void _removeFile(int index) {
    setState(() => selectedFiles.removeAt(index));
  }

  Future<int> _getVideoDuration(String videoPath) async {
    try {
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      final duration = controller.value.duration.inSeconds;
      await controller.dispose();
      return duration;
    } catch (e) {
      debugPrint('Error getting video duration: $e');
      return 0;
    }
  }

  String _getMediaType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return 'image';
    } else if (['mp4', 'avi', 'mkv', 'mov', 'flv'].contains(ext)) {
      return 'video';
    } else if (['pdf'].contains(ext)) {
      return 'pdf';
    } else if (['doc', 'docx'].contains(ext)) {
      return 'doc';
    } else if (['xls', 'xlsx'].contains(ext)) {
      return 'xlsx';
    } else if (['mp3', 'wav', 'aac'].contains(ext)) {
      return 'audio';
    }
    return 'file';
  }

  void _cancelFileSend(int index) {
    setState(() => sendingFileIndices.remove(index));
  }

  Future<void> _sendFiles() async {
    if (selectedFiles.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final chatController = ref.read(chatControllerProvider);
      final uploadingMessagesNotifier = ref.read(
        uploadingMessagesProvider.notifier,
      );

      for (int i = 0; i < selectedFiles.length; i++) {
        final file = selectedFiles[i];
        final fileObj = File(file.filePath);

        setState(() => sendingFileIndices.add(i));

        final mediaType = _getMediaType(file.fileName);

        try {
          String? messageId;

          if (mediaType == 'image') {
            messageId = await chatController.sendImageAndGetId(
              chatId: widget.chatId,
              senderId: currentUserId,
              imageFile: fileObj,
              receiverId: widget.receiverUid,
            );
          } else if (mediaType == 'video') {
            final duration = await _getVideoDuration(file.filePath);
            messageId = await chatController.sendVideoAndGetId(
              chatId: widget.chatId,
              senderId: currentUserId,
              videoFile: fileObj,
              receiverId: widget.receiverUid,
              duration: duration,
            );
          } else {
            messageId = await chatController.sendFileAndGetId(
              chatId: widget.chatId,
              senderId: currentUserId,
              file: fileObj,
              receiverId: widget.receiverUid,
              fileType: mediaType,
            );
          }

          // ✅ Use actual Firestore message ID for tracking
          if (messageId != null) {
            uploadingMessagesNotifier.removeUploading(messageId);
          }

          setState(() => sendingFileIndices.remove(i));
          debugPrint('File ${file.fileName} sent successfully!');
        } catch (e) {
          setState(() => sendingFileIndices.remove(i));
          debugPrint('Error sending file ${file.fileName}: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error sending ${file.fileName}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      if (mounted && sendingFileIndices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedFiles.length} file${selectedFiles.length > 1 ? 's' : ''} sent successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildFilesList()),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[900]!, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.folder_open),
              label: const Text('Add More'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: whiteColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: selectedFiles.isEmpty || sendingFileIndices.isNotEmpty
                  ? null
                  : _sendFiles,
              icon: const Icon(Icons.send),
              label: const Text('Send'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: selectedFiles.length,
      itemBuilder: (context, index) {
        return _buildFileCard(selectedFiles[index], index);
      },
    );
  }

  Widget _buildFileCard(FileAttachment file, int index) {
    final isSending = sendingFileIndices.contains(index);

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[800],
              ),
              child: _buildFilePreview(file),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: whiteColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatFileSize(file.fileSize),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  if (isSending)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Sending...',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: isSending ? Colors.orange : Colors.red,
              ),
              onPressed: isSending
                  ? () => _cancelFileSend(index)
                  : () => _removeFile(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(FileAttachment file) {
    if (file.fileType == FileType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(file.filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[800],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.red, size: 32),
              ),
            );
          },
        ),
      );
    } else if (file.fileType == FileType.video) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(color: Colors.grey[800]),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.4),
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
          ),
        ],
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[800],
        ),
        child: Center(
          child: Icon(
            _getFileIcon(file.fileName),
            color: const Color(0xff25D366),
            size: 32,
          ),
        ),
      );
    }
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf,
      'doc' || 'docx' => Icons.description,
      'xls' || 'xlsx' => Icons.table_chart,
      'ppt' || 'pptx' => Icons.slideshow,
      'zip' || 'rar' => Icons.folder_zip,
      _ => Icons.insert_drive_file,
    };
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

class FileAttachment {
  String filePath;
  String fileName;
  int fileSize;
  FileType fileType;

  FileAttachment({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
  });
}
