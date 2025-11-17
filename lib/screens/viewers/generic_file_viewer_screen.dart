import 'package:flutter/material.dart';
import '../../services/file_type_detector.dart';
import '../../services/cache_service.dart';

/// Generic File Viewer for non-PDF files
class GenericFileViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final FileTypeCategory fileType;
  final String? mimeType;

  const GenericFileViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    this.mimeType,
  });

  @override
  State<GenericFileViewerScreen> createState() => _GenericFileViewerScreenState();
}

class _GenericFileViewerScreenState extends State<GenericFileViewerScreen> {
  final CacheService _cacheService = CacheService();

  @override
  void dispose() {
    // Clean up the temporary file when viewer is closed
    _cacheService.deleteTrackedFile(widget.filePath);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('file path: ${widget.filePath}');
    print('File name: ${widget.fileName}');
    print('File type: ${widget.fileType.name}');
    print('MIME type: ${widget.mimeType}');

    return Scaffold(
      appBar: AppBar(title: Text(widget.fileName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFileIcon(widget.fileType),
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                widget.fileName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'File Type: ${_getFileTypeLabel(widget.fileType)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (widget.mimeType != null) ...[
                const SizedBox(height: 5),
                Text(
                  'MIME: ${widget.mimeType}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 30),
              const Text(
                'This file type cannot be previewed in the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Show file location
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('File Location'),
                      content: SelectableText(widget.filePath),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Show File Location'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(FileTypeCategory type) {
    switch (type) {
      case FileTypeCategory.pdf:
        return Icons.picture_as_pdf;
      case FileTypeCategory.image:
        return Icons.image;
      case FileTypeCategory.text:
        return Icons.text_snippet;
      case FileTypeCategory.document:
        return Icons.description;
      case FileTypeCategory.archive:
        return Icons.folder_zip;
      case FileTypeCategory.video:
        return Icons.video_file;
      case FileTypeCategory.audio:
        return Icons.audio_file;
      case FileTypeCategory.unknown:
        return Icons.insert_drive_file;
    }
  }

  String _getFileTypeLabel(FileTypeCategory type) {
    switch (type) {
      case FileTypeCategory.pdf:
        return 'PDF Document';
      case FileTypeCategory.image:
        return 'Image';
      case FileTypeCategory.text:
        return 'Text File';
      case FileTypeCategory.document:
        return 'Document';
      case FileTypeCategory.archive:
        return 'Archive';
      case FileTypeCategory.video:
        return 'Video';
      case FileTypeCategory.audio:
        return 'Audio';
      case FileTypeCategory.unknown:
        return 'Unknown';
    }
  }
}
