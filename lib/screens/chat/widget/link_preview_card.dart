import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:whatsapp_clone/colors.dart';

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
    if (domain.contains('youtube')) return 'Youtube';
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
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isMe ? senderMessageColor : receiverMessageColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[600]!, width: 0.5),
      ),
      child: const Center(
        child: SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.cyan),
          ),
        ),
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
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(widget.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
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
            if (data.image != null && data.image!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.grey[800],
                  child: Image.network(
                    data.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation(Colors.cyan),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: _buildImagePlaceholder(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  _getWebsiteName(data.domain),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: whiteColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Text(
                      widget.url.length > 40
                          ? '${widget.url.substring(0, 37)}...'
                          : widget.url,
                      style: const TextStyle(
                        color: senderMessageColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
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
