import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/chat/widget/full_screen_image.dart';
import 'package:on_peace/screens/chat/widget/video_player_screen.dart';

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
  final bool isUploading;
  final String? localFilePath;
  final VoidCallback? onCancelUpload;

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
    this.isUploading = false,
    this.localFilePath,
    this.onCancelUpload,
  });

  @override
  State<MediaMessageBubble> createState() => _MediaMessageBubbleState();
}

class _MediaMessageBubbleState extends State<MediaMessageBubble> {
  Uint8List? _thumbnailData;
  bool _isLoadingThumbnail = true;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  bool _isDownloaded = false;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video' && !widget.isUploading) {
      _generateThumbnail();
    } else {
      _isLoadingThumbnail = false;
    }
    if (!widget.isUploading) _checkIfDownloaded();
  }

  String _safeName(String? name) => (name ?? 'document').replaceAll(' ', '_');

  Future<String> _getDownloadPath() async {
    if (Platform.isAndroid) {
      const path = '/storage/emulated/0/Download';
      if (await Directory(path).exists()) return path;
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> _checkIfDownloaded() async {
    final dirPath = await _getDownloadPath();
    final path = '$dirPath/${_safeName(widget.fileName)}';
    if (File(path).existsSync()) {
      if (mounted) {
        setState(() {
          _localFilePath = path;
          _isDownloaded = true;
        });
      }
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      final data = await VideoThumbnail.thumbnailData(
        video: widget.mediaUrl,
        imageFormat: ImageFormat.PNG,
        maxHeight: 300,
        quality: 75,
      );
      if (mounted) {
        setState(() {
          _thumbnailData = data;
          _isLoadingThumbnail = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingThumbnail = false);
    }
  }

  Future<int> _getAndroidSdkInt() async {
    try {
      if (Platform.isAndroid) {
        final result = await Process.run('getprop', ['ro.build.version.sdk']);
        return int.tryParse(result.stdout.toString().trim()) ?? 30;
      }
    } catch (_) {}
    return 30;
  }

  Future<void> _downloadFile() async {
    if (_isDownloading) return;

    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkInt();
      if (sdkInt < 30) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission required'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });
    try {
      final dirPath = await _getDownloadPath();
      final filePath = '$dirPath/${_safeName(widget.fileName)}';

      final existingFile = File(filePath);
      if (existingFile.existsSync()) existingFile.deleteSync();

      final dio = Dio();
      dio.options = BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
        headers: {'Accept': '*/*', 'User-Agent': 'Mozilla/5.0'},
      );

      final isPdfOrDoc = [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
      ].any((ext) => (widget.fileName ?? '').toLowerCase().endsWith(ext));

      String downloadUrl = widget.mediaUrl;
      if (isPdfOrDoc && downloadUrl.contains('/image/upload/')) {
        downloadUrl = downloadUrl.replaceFirst(
          '/image/upload/',
          '/image/upload/fl_attachment/',
        );
        debugPrint('fl_attachment URL: $downloadUrl');
      }

      await dio.download(
        downloadUrl,
        filePath,
        deleteOnError: true,
        onReceiveProgress: (r, t) {
          if (t != -1 && mounted) setState(() => _downloadProgress = r / t);
        },
      );

      final downloadedFile = File(filePath);
      if (!downloadedFile.existsSync() || downloadedFile.lengthSync() == 0) {
        throw Exception('Downloaded file is empty or missing');
      }

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
          _localFilePath = filePath;
        });
      }
      await OpenFile.open(filePath);
    } catch (e) {
      debugPrint('Download error: $e');
      try {
        final dirPath = await _getDownloadPath();
        final f = File('$dirPath/${_safeName(widget.fileName)}');
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Download failed: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _openFullScreenImage() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          FullScreenImage(imageUrl: widget.mediaUrl, fileName: widget.fileName),
    ),
  );

  void _openVideoPlayer() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VideoPlayerScreen(
        videoUrl: widget.mediaUrl,
        fileName: widget.fileName,
      ),
    ),
  );

  String _formatFileSize(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDuration(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: widget.isGrouped ? 3 : 8,
        horizontal: 1,
      ),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
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
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.65 - 16;
    if (widget.isUploading && widget.localFilePath != null) {
      return _buildUploadingOverlay(context, maxWidth);
    }
    switch (widget.mediaType) {
      case 'image':
        return _buildImageContent(context, maxWidth);
      case 'gif':
        return _buildGifContent(maxWidth);
      case 'video':
        return _buildVideoContent(context, maxWidth);
      case 'audio':
      case 'mp3':
        return _buildAudioContent(maxWidth);
      default:
        return _buildFileContent(maxWidth);
    }
  }

  Widget _buildUploadingOverlay(BuildContext context, double maxWidth) {
    final height = MediaQuery.of(context).size.height * 0.42;
    final isVideo = widget.mediaType == 'video';
    final isFile = !['image', 'video', 'gif'].contains(widget.mediaType);

    if (isFile) return _buildFileUploadingContent(maxWidth);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          isVideo
              ? Container(
                  width: maxWidth,
                  height: height,
                  color: Colors.grey[850],
                  child: const Center(
                    child: Icon(
                      Icons.videocam,
                      color: Colors.white24,
                      size: 52,
                    ),
                  ),
                )
              : Image.file(
                  File(widget.localFilePath!),
                  width: maxWidth,
                  height: height,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: maxWidth,
                    height: height,
                    color: Colors.grey[850],
                  ),
                ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.42)),
          ),
          GestureDetector(
            onTap: widget.onCancelUpload,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.8,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.fileSize != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formatFileSize(widget.fileSize!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadingContent(double maxWidth) {
    return Container(
      width: maxWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(_getFileIcon(widget.mediaType), color: uiColor, size: 34),
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    uiColor.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileName ?? 'File',
                  style: const TextStyle(
                    color: whiteColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  widget.fileSize != null
                      ? '${_formatFileSize(widget.fileSize!)} • Sending...'
                      : 'Sending...',
                  style: TextStyle(color: uiColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifContent(double maxWidth) {
    return GestureDetector(
      onTap: _openFullScreenImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Image.network(
            widget.mediaUrl,
            fit: BoxFit.fitWidth,
            loadingBuilder: (_, child, p) => p == null
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
                  ),
            errorBuilder: (_, _, _) => Container(
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, double maxWidth) {
    return GestureDetector(
      onTap: _openFullScreenImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.mediaUrl,
          fit: BoxFit.cover,
          width: maxWidth,
          height: MediaQuery.of(context).size.height * 0.42,
          loadingBuilder: (_, child, p) => p == null
              ? child
              : Container(
                  width: maxWidth,
                  height: MediaQuery.of(context).size.height * 0.42,
                  color: Colors.grey[800],
                  child: const Center(
                    child: CircularProgressIndicator(color: uiColor),
                  ),
                ),
          errorBuilder: (_, _, _) => Container(
            width: maxWidth,
            height: MediaQuery.of(context).size.height * 0.42,
            color: Colors.grey[800],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 50),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context, double maxWidth) {
    return GestureDetector(
      onTap: _openVideoPlayer,
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

  Widget _buildAudioContent(double maxWidth) {
    if (widget.isLoading) {
      return Container(
        width: maxWidth,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: widget.isMe ? senderMessageColor : receiverMessageColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(uiColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sending...',
              style: TextStyle(
                color: whiteColor.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return AudioPlayerBubble(
      mediaUrl: widget.mediaUrl,
      duration: widget.duration,
      isMe: widget.isMe,
      maxWidth: maxWidth,
    );
  }

  Widget _buildFileContent(double maxWidth) {
    return GestureDetector(
      onTap: _isDownloaded
          ? () => OpenFile.open(_localFilePath!)
          : (!_isDownloading ? _downloadFile : null),
      child: Container(
        width: maxWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: fileContentDark,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _getFileIcon(widget.mediaType),
                      color: uiColor,
                      size: 34,
                    ),
                    if (widget.isLoading)
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            uiColor.withOpacity(0.7),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fileName ?? 'File',
                        style: const TextStyle(
                          color: whiteColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.isLoading
                            ? 'Sending...'
                            : _isDownloading
                            ? 'Downloading ${(_downloadProgress * 100).toInt()}%'
                            : widget.fileSize != null
                            ? _formatFileSize(widget.fileSize!)
                            : '',
                        style: TextStyle(
                          color: _isDownloading ? uiColor : Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.isLoading && !widget.isMe)
                  _isDownloading
                      ? SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: _downloadProgress > 0
                                ? _downloadProgress
                                : null,
                            strokeWidth: 2.5,
                            color: uiColor,
                          ),
                        )
                      : _isDownloaded
                      ? const SizedBox.shrink()
                      : Container(
                          decoration: BoxDecoration(
                            color: uiColor,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.download,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
              ],
            ),
            if (_isDownloading && _downloadProgress > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(uiColor),
                  minHeight: 3,
                ),
              ),
            ],
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

const List<double> _kBarHeights = [
  6,
  10,
  16,
  22,
  28,
  20,
  14,
  9,
  18,
  26,
  12,
  24,
  30,
  16,
  10,
  20,
  28,
  14,
  8,
  22,
  28,
  12,
  18,
  24,
  16,
  10,
  26,
  20,
  14,
  28,
  8,
  22,
  18,
  12,
  24,
  16,
  20,
  10,
  26,
  14,
];

class AudioPlayerBubble extends StatefulWidget {
  final String mediaUrl;
  final int? duration;
  final bool isMe;
  final double maxWidth;

  const AudioPlayerBubble({
    super.key,
    required this.mediaUrl,
    required this.duration,
    required this.isMe,
    required this.maxWidth,
  });

  @override
  State<AudioPlayerBubble> createState() => _AudioPlayerBubbleState();
}

class _AudioPlayerBubbleState extends State<AudioPlayerBubble> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _current = Duration.zero;
  Duration _total = Duration.zero;
  bool _isLoadingDuration = false;
  bool _durationLoaded = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    final rawDuration = widget.duration;
    if (rawDuration != null && rawDuration > 0) {
      _total = Duration(seconds: rawDuration);
    }

    _player.durationStream.listen((d) {
      if (d != null && d.inMilliseconds > 0 && mounted) {
        setState(() {
          _total = d;
          _durationLoaded = true;
        });
      }
    });

    _player.positionStream.listen((p) {
      if (mounted) setState(() => _current = p);
    });

    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      if (s.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _current = Duration.zero;
        });
        _player.seek(Duration.zero);
        _player.pause();
      } else {
        final nowPlaying =
            s.playing &&
            s.processingState != ProcessingState.loading &&
            s.processingState != ProcessingState.buffering;
        if (_isPlaying != nowPlaying) {
          setState(() => _isPlaying = nowPlaying);
        }
      }
    });

    if (_total.inSeconds == 0) {
      _fetchDurationSilently();
    }
  }

  Future<void> _fetchDurationSilently() async {
    if (_isLoadingDuration) return;
    _isLoadingDuration = true;
    try {
      await _player.setUrl(widget.mediaUrl);
    } catch (e) {
    } finally {
      _isLoadingDuration = false;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.idle) {
          await _player.setUrl(widget.mediaUrl);
        }
        await _player.play();
      }
    } catch (e) {
      debugPrint('Audio toggle error: $e');
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _total.inMilliseconds > 0
        ? (_current.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final Duration displayDuration = _isPlaying ? _current : _total;
    final int playedBars = (progress * _kBarHeights.length).round();

    return Container(
      width: widget.maxWidth,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: widget.isMe ? senderMessageColor : receiverMessageColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                key: ValueKey(_isPlaying),
                color: whiteColor,
                size: 30,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: SizedBox(
              height: 34,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_kBarHeights.length, (i) {
                  final bool played = i < playedBars;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: 3,
                    height: _kBarHeights[i],
                    decoration: BoxDecoration(
                      color: played ? uiColor : whiteColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(width: 8),
          _durationLoaded
              ? Text(
                  _fmt(displayDuration),
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                  ),
                ),
        ],
      ),
    );
  }
}
