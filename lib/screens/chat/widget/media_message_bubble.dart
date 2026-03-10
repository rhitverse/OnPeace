import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/chat/widget/full_screen_image.dart';
import 'package:whatsapp_clone/screens/chat/widget/video_player_screen.dart';

class MediaMessageBubble extends StatefulWidget {
  final String mediaUrl;
  final String mediaType;
  final String? fileName;
  final int? fileSize;
  final int? duration;
  final String time;
  final bool isMe;
  final bool showTail;
  final bool isGrouped;
  final bool showTime;
  final bool isLoading;

  const MediaMessageBubble({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    this.fileName,
    this.fileSize,
    this.duration,
    required this.time,
    required this.isMe,
    this.showTail = true,
    this.isGrouped = false,
    this.showTime = true,
    this.isLoading = false,
  });

  @override
  State<MediaMessageBubble> createState() => _MediaMessageBubbleState();
}

class _MediaMessageBubbleState extends State<MediaMessageBubble> {
  Uint8List? _thumbnailData;
  bool _isLoadingThumbnail = true;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video') {
      _generateThumbnail();
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: widget.mediaUrl,
        imageFormat: ImageFormat.PNG,
        maxHeight: 300,
        quality: 75,
      );
      if (mounted) {
        setState(() {
          _thumbnailData = uint8list;
          _isLoadingThumbnail = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
      }
    }
  }

  Future<void> _openFile(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  void _openFullScreenImage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(
          imageUrl: widget.mediaUrl,
          fileName: widget.fileName,
        ),
      ),
    );
  }

  void _openVideoPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoUrl: widget.mediaUrl,
          fileName: widget.fileName,
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: widget.isGrouped ? 3 : 8,
        horizontal: 1,
      ),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: widget.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildMediaContent(context),

                  if (widget.showTime)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                      child: Text(
                        widget.time,
                        style: const TextStyle(color: whiteColor, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.65 - 16;

    switch (widget.mediaType) {
      case 'image':
        return _buildImageContent(context, maxWidth);

      case 'gif':
        return _buildGifContent(maxWidth);

      case 'video':
        return _buildVideoContent(context, maxWidth);

      default:
        return _buildFileContent(maxWidth);
    }
  }

  Widget _buildGifContent(double maxWidth) {
    return GestureDetector(
      onTap: () => _openFullScreenImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Image.network(
            widget.mediaUrl,
            fit: BoxFit.fitWidth,
            loadingBuilder: (context, child, progress) {
              return progress == null
                  ? child
                  : Container(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                        minHeight: 200,
                      ),
                      color: Colors.grey[800],
                      child: const Center(
                        child: CircularProgressIndicator(color: uiColor),
                      ),
                    );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                color: Colors.grey[800],
                padding: const EdgeInsets.all(20),
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 50,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, double maxWidth) {
    return GestureDetector(
      onTap: () => _openFullScreenImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.mediaUrl,
          fit: BoxFit.cover,
          width: maxWidth,
          height: MediaQuery.of(context).size.height * 0.42,
          loadingBuilder: (context, child, progress) {
            return progress == null
                ? child
                : Container(
                    width: maxWidth,
                    height: MediaQuery.of(context).size.height * 0.42,
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(color: uiColor),
                    ),
                  );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: maxWidth,
              height: MediaQuery.of(context).size.height * 0.42,
              color: Colors.grey[800],
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 50,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context, double maxWidth) {
    return GestureDetector(
      onTap: () => _openVideoPlayer(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isLoadingThumbnail
                ? Container(
                    width: maxWidth,
                    height: MediaQuery.of(context).size.height * 0.42,
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(color: uiColor),
                    ),
                  )
                : _thumbnailData != null
                ? Image.memory(
                    _thumbnailData!,
                    width: maxWidth,
                    height: MediaQuery.of(context).size.height * 0.42,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: maxWidth,
                    height: MediaQuery.of(context).size.height * 0.42,
                    color: Colors.grey[800],
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.4),
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
          ),

          if (widget.duration != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(widget.duration!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileContent(double maxWidth) {
    return GestureDetector(
      onTap: () => _openFile(widget.mediaUrl),
      child: Container(
        width: maxWidth,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _getFileIcon(widget.mediaType),
                    color: uiColor,
                    size: 32,
                  ),
                  if (widget.isLoading)
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          uiColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.fileName ?? 'File',
                    style: const TextStyle(
                      color: whiteColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (widget.fileSize != null)
                    Text(
                      _formatFileSize(widget.fileSize!),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  if (widget.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Sending...',
                        style: TextStyle(color: uiColor, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.isLoading) Icon(Icons.close, color: uiColor, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String? type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'audio':
      case 'mp3':
        return Icons.audio_file;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      default:
        return Icons.file_present;
    }
  }
}
