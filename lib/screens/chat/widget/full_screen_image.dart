import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';

class FullScreenImage extends StatefulWidget {
  final String imageUrl;
  final List<String>? imageUrls;
  final int initialIndex;
  final String? fileName;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    this.imageUrls,
    this.initialIndex = 0,
    this.fileName,
  });

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  late final List<String> _urls;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _urls = (widget.imageUrls != null && widget.imageUrls!.isNotEmpty)
        ? widget.imageUrls!
        : [widget.imageUrl];
    final initial = widget.initialIndex.clamp(0, _urls.length - 1);
    _pageController = PageController(initialPage: initial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: PageView.builder(
        controller: _pageController,
        itemCount: _urls.length,
        itemBuilder: (context, index) {
          final imageUrl = _urls[index];
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  return progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: uiColor),
                        );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
