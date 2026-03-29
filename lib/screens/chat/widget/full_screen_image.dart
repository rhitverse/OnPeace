import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String? fileName;
  const FullScreenImage({super.key, required this.imageUrl, this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
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
      ),
    );
  }
}
