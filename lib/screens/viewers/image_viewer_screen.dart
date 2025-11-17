import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/cache_service.dart';

/// Image Viewer Screen for image files
class ImageViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String? mimeType;

  const ImageViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    this.mimeType,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  final CacheService _cacheService = CacheService();

  @override
  void dispose() {
    // Clean up the temporary file when viewer is closed
    _cacheService.deleteTrackedFile(widget.filePath);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Image Info'),
                  content: Text(
                    'File: ${widget.fileName}\n'
                    'Type: Image\n'
                    '${widget.mimeType != null ? 'MIME: ${widget.mimeType}' : ''}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(widget.filePath),
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading image',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
