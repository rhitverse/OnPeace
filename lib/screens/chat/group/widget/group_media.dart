import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/common/encryption/encryption_service.dart';
import 'package:on_peace/screens/chat/widget/full_screen_image.dart';
import 'package:on_peace/screens/chat/widget/message_helper.dart';
import 'package:on_peace/screens/chat/widget/video_player_screen.dart';
import 'package:on_peace/widgets/helpful_widgets/right_popUp.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class GroupMediaSection extends StatefulWidget {
  final String groupId;

  const GroupMediaSection({super.key, required this.groupId});

  @override
  State<GroupMediaSection> createState() => _GroupMediaSectionState();
}

class _GroupMediaSectionState extends State<GroupMediaSection> {
  int _mediaTabIndex = 0;
  final PageController _mediaPageController = PageController();
  final EncryptionService _encryption = EncryptionService();
  late final Future<List<Map<String, dynamic>>> _mediaFuture;
  late final Future<List<Map<String, dynamic>>> _documentsFuture;
  late final Future<List<String>> _linksFuture;

  @override
  void initState() {
    super.initState();
    _mediaFuture = _fetchGroupMedia();
    _documentsFuture = _fetchGroupDocuments();
    _linksFuture = _fetchGroupLinks();
  }

  @override
  void dispose() {
    _mediaPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMediaTabs(),
        const SizedBox(height: 12),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: PageView(
            controller: _mediaPageController,
            onPageChanged: (index) {
              setState(() => _mediaTabIndex = index);
            },
            children: [
              _buildMediaGallery(),
              _buildDocumentsList(),
              _buildLinksList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaTabs() {
    return Row(
      children: [
        _buildMediaTab(iconAsset: 'assets/svg/imagevideo.svg', index: 0),
        const Spacer(),
        _buildMediaTab(iconAsset: 'assets/svg/documents.svg', index: 1),
        const Spacer(),
        _buildMediaTab(iconAsset: 'assets/svg/link.svg', index: 2),
      ],
    );
  }

  Widget _buildMediaTab({required String iconAsset, required int index}) {
    final isActive = _mediaTabIndex == index;
    return GestureDetector(
      onTap: () {
        _mediaPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      },
      child: Column(
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 26,
            height: 26,
            colorFilter: const ColorFilter.mode(whiteColor, BlendMode.srcIn),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 2,
            width: 96,
            decoration: BoxDecoration(
              color: isActive ? whiteColor : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGallery() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _mediaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final media = snapshot.data ?? [];

        if (media.isEmpty) {
          return _buildEmptySection('No media shared yet');
        }

        final imageUrls = <String>[];
        final imageIndexByMediaIndex = <int?>[];
        for (final item in media) {
          final mediaUrl = item['mediaUrl'] as String?;
          final mediaType = item['mediaType'] as String?;
          if (mediaType == 'video' || mediaUrl == null || mediaUrl.isEmpty) {
            imageIndexByMediaIndex.add(null);
          } else {
            imageIndexByMediaIndex.add(imageUrls.length);
            imageUrls.add(mediaUrl);
          }
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: media.length,
          itemBuilder: (context, index) {
            final item = media[index];
            final mediaUrl = item['mediaUrl'] as String?;
            final mediaType = item['mediaType'] as String?;
            if (mediaUrl == null || mediaUrl.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[900],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: mediaType == 'video'
                        ? _buildVideoThumbnail(mediaUrl)
                        : Image.network(
                            mediaUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              );
                            },
                          ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (mediaType == 'video') {
                          _openMediaItem(mediaUrl, mediaType);
                          return;
                        }
                        final imageIndex = imageIndexByMediaIndex[index] ?? 0;
                        _openImageGallery(imageUrls, imageIndex);
                      },
                      child: mediaType == 'video'
                          ? const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: whiteColor,
                                size: 32,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _documentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data ?? [];

        if (documents.isEmpty) {
          return _buildEmptySection('No documents shared yet');
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: documents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final doc = documents[index];
            final fileName = (doc['fileName'] as String?) ?? 'Document';
            final mediaUrl = (doc['mediaUrl'] as String?) ?? '';
            final fileSize = (doc['fileSize'] as num?)?.toInt();
            final subtitle = fileSize != null
                ? '${doc['mediaType']?.toString().toUpperCase() ?? ''} • ${_formatFileSize(fileSize)}'
                : (doc['mediaType']?.toString().toUpperCase() ?? '');

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: receiverMessageColor,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => _openDocument(mediaUrl, fileName),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    visualDensity: const VisualDensity(vertical: -2),
                    leading: SvgPicture.asset(
                      'assets/svg/documents.svg',
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(
                        uiColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: Text(
                      fileName,
                      style: const TextStyle(color: whiteColor, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLinksList() {
    return FutureBuilder<List<String>>(
      future: _linksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final links = snapshot.data ?? [];

        if (links.isEmpty) {
          return _buildEmptySection('No links shared yet');
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: links.length,
          separatorBuilder: (_, __) => SizedBox(height: 2),
          itemBuilder: (context, index) {
            final link = links[index];
            return Container(
              margin: EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: receiverMessageColor,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => _openLink(link),
                  onLongPress: () => _copyLink(link),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    visualDensity: const VisualDensity(vertical: -2),
                    leading: SvgPicture.asset(
                      'assets/svg/link.svg',
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        whiteColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: Text(
                      link,
                      style: const TextStyle(color: whiteColor, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchGroupMedia() async {
    try {
      final msgDocs = await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .collection('messages')
          .where('mediaType', whereIn: ['image', 'video'])
          .orderBy('time', descending: true)
          .limit(30)
          .get();

      final items = <Map<String, dynamic>>[];
      for (final doc in msgDocs.docs) {
        final data = doc.data();
        final mediaUrl = data['mediaUrl'];
        final decryptedUrl = await _decryptMediaUrl(mediaUrl);
        items.add({'mediaUrl': decryptedUrl, 'mediaType': data['mediaType']});
      }
      return items;
    } catch (e) {
      debugPrint('Error fetching group media: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchGroupDocuments() async {
    try {
      final docTypes = [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
      ];

      final msgDocs = await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .collection('messages')
          .where('mediaType', whereIn: docTypes)
          .orderBy('time', descending: true)
          .limit(30)
          .get();

      final items = <Map<String, dynamic>>[];
      for (final doc in msgDocs.docs) {
        final data = doc.data();
        final mediaUrl = data['mediaUrl'];
        final decryptedUrl = await _decryptMediaUrl(mediaUrl);
        items.add({
          'mediaUrl': decryptedUrl,
          'mediaType': data['mediaType'],
          'fileName': data['fileName'],
          'fileSize': data['fileSize'],
        });
      }
      return items;
    } catch (e) {
      debugPrint('Error fetching group documents: $e');
      return [];
    }
  }

  Future<List<String>> _fetchGroupLinks() async {
    try {
      final msgDocs = await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .collection('messages')
          .orderBy('time', descending: true)
          .limit(60)
          .get();

      final links = <String>[];
      for (final doc in msgDocs.docs) {
        final data = doc.data();
        final text = await _decryptText(data);
        if (text.trim().isEmpty) continue;
        if (!isUri(text)) continue;
        final url = extractUrl(text);
        if (url != null && url.isNotEmpty) {
          links.add(url);
        }
      }

      return links.toSet().toList();
    } catch (e) {
      debugPrint('Error fetching group links: $e');
      return [];
    }
  }

  Future<String?> _decryptMediaUrl(dynamic encrypted) async {
    if (encrypted is! String || encrypted.isEmpty) return null;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) return encrypted;
    try {
      return await _encryption.decryptMessage(encrypted, currentUid);
    } catch (_) {
      return encrypted;
    }
  }

  Future<String> _decryptText(Map<String, dynamic> data) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (data.containsKey('encryptedText')) {
      try {
        return await _encryption.decryptMessage(
          data['encryptedText'] ?? '',
          currentUid,
        );
      } catch (_) {
        return data['plainText'] ?? '';
      }
    }
    return data['plainText'] ?? '';
  }

  void _openMediaItem(String url, String? mediaType) {
    if (mediaType == 'video') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoUrl: url)),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullScreenImage(imageUrl: url)),
    );
  }

  void _openImageGallery(List<String> urls, int initialIndex) {
    if (urls.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImage(
          imageUrl: urls[initialIndex],
          imageUrls: urls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(String mediaUrl) {
    return FutureBuilder<Uint8List?>(
      future: VideoThumbnail.thumbnailData(
        video: mediaUrl,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 70,
      ),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Icon(Icons.videocam, color: Colors.grey));
        }
        return Image.memory(data, fit: BoxFit.cover);
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openDocument(String url, String fileName) async {
    try {
      if (url.isEmpty) return;
      final filePath = await _downloadToTemp(url, fileName);
      if (filePath == null) return;
      await OpenFile.open(filePath);
    } catch (e) {
      debugPrint('Error opening file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to open file')));
    }
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyLink(String url) async {
    if (url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    RightPopup.show(context, 'Link Copied');
  }

  Future<String?> _downloadToTemp(String url, String fileName) async {
    try {
      final dir = await getTemporaryDirectory();
      final safeName = _safeFileName(fileName, url);
      final filePath = '${dir.path}/$safeName';
      final downloadUrl = _normalizeDownloadUrl(url, fileName);
      await Dio().download(downloadUrl, filePath);
      return filePath;
    } catch (e) {
      debugPrint('Download failed: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download failed')));
      return null;
    }
  }

  String _safeFileName(String fileName, String url) {
    final trimmed = fileName.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.replaceAll(' ', '_');
    }
    final uri = Uri.tryParse(url);
    final last = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : 'document';
    return last.replaceAll(' ', '_');
  }

  String _normalizeDownloadUrl(String url, String fileName) {
    final lower = fileName.toLowerCase();
    final isDoc = [
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'txt',
    ].any((ext) => lower.endsWith(ext));

    if (isDoc && url.contains('/image/upload/')) {
      return url.replaceFirst('/image/upload/', '/image/upload/fl_attachment/');
    }
    return url;
  }

  Widget _buildEmptySection(String message) {
    return Center(
      child: Text(message, style: TextStyle(color: Colors.grey[600])),
    );
  }
}
