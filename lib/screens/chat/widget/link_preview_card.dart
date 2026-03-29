import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:on_peace/colors.dart';
import 'dart:ui' as ui;

class LinkPreviewCard extends StatefulWidget {
  final String url;
  final bool isMe;
  const LinkPreviewCard({super.key, required this.url, required this.isMe});

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  late Future<PreviewData> _dataFuture;
  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchPreviewData(widget.url);
  }

  @override
  void didUpdateWidget(LinkPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _dataFuture = _fetchPreviewData(widget.url);
    }
  }

  Future<PreviewData> _fetchPreviewData(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => http.Response('', 408),
          );
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        String title =
            document
                .querySelector('meta[property="og:title"]')
                ?.attributes['content'] ??
            '';
        String image =
            document
                .querySelector('meta[property="og:image"]')
                ?.attributes['content'] ??
            '';
        if (title.isEmpty) {
          title =
              document
                  .querySelector('meta[name="title"]')
                  ?.attributes['content'] ??
              document.querySelector('title')?.text ??
              '';
        }
        title = title.replaceAll('&quot', '"').replaceAll('&amp', '&');
        return PreviewData(
          title: title.isEmpty ? 'Shared Content' : title,
          image: image.isEmpty ? null : image,
          domain: Uri.parse(url).host.replaceFirst('www', ''),
        );
      }
      return PreviewData(
        title: 'Shared Link',
        image: null,
        domain: Uri.parse(url).host.replaceFirst('www', ''),
      );
    } catch (e) {
      return PreviewData(
        title: 'Shared Link',
        image: null,
        domain: Uri.parse(url).host.replaceFirst('www', ''),
      );
    }
  }

  String _getWebsiteName(String domain) {
    if (domain.contains('youtube') || domain.contains('youtu.be')) {
      return 'YouTube';
    }
    if (domain.contains('instagram')) return 'Instagram';
    if (domain.contains('twitter') || domain.contains('x.com')) return 'X';
    if (domain.contains('facebook')) return 'Facebook';
    if (domain.contains('github')) return 'Github';
    if (domain.contains('reddit')) return 'Reddit';
    if (domain.contains('linkedin')) return 'LinkedIn';
    if (domain.contains('tiktok')) return 'TikTok';
    if (domain.contains('map')) return 'Maps';
    return 'Link';
  }

  bool _isVideoUrl(String domain) {
    return domain.contains('youtube') ||
        domain.contains('youtu.be') ||
        domain.contains('youtube-nocookie') ||
        domain.contains('tiktok') ||
        domain.contains('instagram') ||
        domain.contains('facebook') ||
        domain.contains('vimeo') ||
        domain.contains('dailymotion');
  }

  String _formatUrl(String url) {
    if (url.length > 70) {
      final uri = Uri.parse(url);
      final domain = uri.host;
      final path = uri.path;

      if (path.isNotEmpty && path != '/') {
        final displayPath = path.length > 30
            ? '${path.substring(0, 30)}...'
            : path;
        return '$domain$displayPath';
      }
      return domain;
    }
    return url;
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && Navigator.canPop(dialogContext)) {
            Navigator.pop(dialogContext);
          }
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation(uiColor),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PreviewData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        final data = snapshot.data;
        if (data == null) {
          return _buildErrorCard();
        }
        return _buildPreviewCard(data);
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: widget.isMe ? senderMessageColor : receiverMessageColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isMe ? Colors.green[800]! : Colors.black,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.32,
              decoration: BoxDecoration(color: Colors.grey[900]!),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 160,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isMe ? senderMessageColor : receiverMessageColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[600]!, width: 0.5),
      ),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(widget.url);
          if (await canLaunchUrl(uri)) {
            _showLoadingDialog(context);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, color: whiteColor, size: 18),
            const SizedBox(height: 6),
            Text(
              'Open Link',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(PreviewData data) {
    if (data.image == null || data.image!.isEmpty) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isMe ? senderMessageColor : receiverMessageColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isMe ? Colors.green[800]! : Colors.grey[700]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse(widget.url);
                if (await canLaunchUrl(uri)) {
                  _showLoadingDialog(context);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                data.title,
                style: const TextStyle(
                  color: whiteColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _getWebsiteName(data.domain),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse(widget.url);
                if (await canLaunchUrl(uri)) {
                  _showLoadingDialog(context);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                _formatUrl(widget.url),
                style: const TextStyle(
                  color: Color(0xFF4A9EFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: widget.isMe ? senderMessageColor : receiverMessageColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isMe ? Colors.green[800]! : Colors.grey[700]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.32,
              color: Colors.grey[800],
              child: _isVideoUrl(data.domain)
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 10,
                            sigmaY: 10,
                          ),
                          child: Image.network(
                            data.image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(color: Colors.grey[800]);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildImageLoaderSkeleton();
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse(widget.url);
                            if (await canLaunchUrl(uri)) {
                              _showLoadingDialog(context);
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },

                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: whiteColor,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Image.network(
                      data.image!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildImageLoaderSkeleton();
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(widget.url);
                    if (await canLaunchUrl(uri)) {
                      _showLoadingDialog(context);
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Text(
                    data.title,
                    style: const TextStyle(
                      color: whiteColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getWebsiteName(data.domain),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(widget.url);
                    if (await canLaunchUrl(uri)) {
                      _showLoadingDialog(context);
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Text(
                    _formatUrl(widget.url),
                    style: const TextStyle(
                      color: Color(0xFF4A9EFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageLoaderSkeleton() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[800]!, Colors.grey[700]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation(uiColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[800]!, Colors.grey[900]!],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 50, color: Colors.grey[700]),
              const SizedBox(height: 8),
              Text(
                'Image Preview',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PreviewData {
  final String title;
  final String? image;
  final String domain;

  PreviewData({required this.title, required this.image, required this.domain});
}
