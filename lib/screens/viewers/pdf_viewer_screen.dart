import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../services/cache_service.dart';

/// PDF Viewer Screen with proper Scaffold wrapper
class PDFViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String? mimeType;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    this.mimeType,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
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
                  title: const Text('Document Info'),
                  content: Text(
                    'File: ${widget.fileName}\n'
                    'Type: PDF\n'
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
      body: PDFView(
        filePath: widget.filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading PDF: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onPageError: (page, error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error on page $page: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }
}
