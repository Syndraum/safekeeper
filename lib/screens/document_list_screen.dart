import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../services/document_service.dart';
import '../services/encryption_service.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final DocumentService _documentService = DocumentService();
  final _encryptionService = EncryptionService();
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final documents = await _documentService.getDocuments();
    setState(() {
      _documents = documents;
    });
  }

  Future<void> _deleteDocument(int id) async {
    await _documentService.deleteDocument(id);
    _loadDocuments(); // Reload the list after deletion
  }

  Future<void> _openDocument(
    int documentId,
    String encryptedPath,
    String name,
  ) async {
    try {
      // Get document metadata from database
      final doc = await _documentService.getDocument(documentId);
      if (doc == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document not found in database')),
          );
        }
        return;
      }

      // Get encrypted key, IV, and HMAC from database
      String encryptedKeyBase64 = doc['encrypted_key'];
      String ivBase64 = doc['iv'];
      String? hmacBase64 = doc['hmac'];

      // Convert from base64
      Uint8List encryptedKey = base64.decode(encryptedKeyBase64);
      Uint8List iv = base64.decode(ivBase64);
      Uint8List? hmac = hmacBase64 != null ? base64.decode(hmacBase64) : null;

      // Read encrypted file
      File encryptedFile = File(encryptedPath);
      Uint8List encryptedData = await encryptedFile.readAsBytes();

      // Decrypt using hybrid decryption
      Uint8List decryptedBytes = await _encryptionService.decryptFile(
        encryptedData,
        encryptedKey,
        iv,
        hmac,
      );

      // Extract file extension, handle files without extension
      String extension = '';
      if (name.contains('.')) {
        extension = name.toLowerCase().split('.').last;
      }

      // Save the decrypted file temporarily for viewing
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/$name';
      File tempFile = File(tempPath);
      await tempFile.writeAsBytes(decryptedBytes);

      // Navigate to a viewer screen
      if (mounted) {
        // Check file extension to determine viewer type
        if (extension == 'pdf') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PDFViewerScreen(filePath: tempPath, fileName: name),
            ),
          );
        } else if (_isImageExtension(extension)) {
          // For image files, show image viewer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ImageViewerScreen(filePath: tempPath, fileName: name),
            ),
          );
        } else {
          // For other files, show a generic viewer or download option
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GenericFileViewerScreen(filePath: tempPath, fileName: name),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Document List')),
      body: _documents.isEmpty
          ? Center(child: Text('No documents uploaded yet.'))
          : ListView.builder(
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return ListTile(
                  title: Text(doc['name']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(doc['id']),
                  ),
                  onTap: () =>
                      _openDocument(doc['id'], doc['path'], doc['name']),
                );
              },
            ),
    );
  }

  bool _isImageExtension(String extension) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(extension.toLowerCase());
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteDocument(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// PDF Viewer Screen with proper Scaffold wrapper
class PDFViewerScreen extends StatelessWidget {
  final String filePath;
  final String fileName;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Document Info'),
                  content: Text('File: $fileName\nType: PDF'),
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
        filePath: filePath,
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

/// Image Viewer Screen for image files
class ImageViewerScreen extends StatelessWidget {
  final String filePath;
  final String fileName;

  const ImageViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Image Info'),
                  content: Text('File: $fileName\nType: Image'),
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
            File(filePath),
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

/// Generic File Viewer for non-PDF files
class GenericFileViewerScreen extends StatelessWidget {
  final String filePath;
  final String fileName;

  const GenericFileViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    // Extract file extension, handle files without extension
    String extension = '';
    if (fileName.contains('.')) {
      extension = fileName.toLowerCase().split('.').last;
    }
    
    print('file path: $filePath');
    print('File name: $fileName');
    print('File extension: $extension');

    return Scaffold(
      appBar: AppBar(title: Text(fileName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFileIcon(extension),
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                fileName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                extension.isNotEmpty 
                    ? 'File Type: ${extension.toUpperCase()}'
                    : 'File Type: Unknown',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
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
                      content: SelectableText(filePath),
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

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}
