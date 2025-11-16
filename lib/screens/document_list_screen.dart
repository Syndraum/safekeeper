import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../services/document_service.dart';
import '../services/encryption_service.dart';
import '../services/file_type_detector.dart';
import '../widgets/audio_player_widget.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final DocumentService _documentService = DocumentService();
  final _encryptionService = EncryptionService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _filteredDocuments = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterDocuments();
    });
  }

  void _filterDocuments() {
    if (_searchQuery.isEmpty) {
      _filteredDocuments = List.from(_documents);
    } else {
      _filteredDocuments = _documents.where((doc) {
        final name = doc['name'].toString().toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadDocuments() async {
    final documents = await _documentService.getDocuments();
    setState(() {
      _documents = documents;
      _filterDocuments();
    });
  }

  Future<void> _showRenameDialog(int id, String currentName) async {
    final TextEditingController controller = TextEditingController(text: currentName);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Document Name',
            hintText: 'Enter new name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName != currentName) {
      await _documentService.updateDocumentName(id, newName);
      _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document renamed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
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

      // Get stored file type from database, or detect from content if not available
      String? fileTypeStr = doc['file_type'];
      String? mimeType = doc['mime_type'];
      
      FileTypeCategory fileType;
      if (fileTypeStr != null && fileTypeStr.isNotEmpty) {
        // Use stored file type
        try {
          fileType = FileTypeCategory.values.firstWhere(
            (e) => e.name == fileTypeStr,
            orElse: () => FileTypeCategory.unknown,
          );
        } catch (e) {
          fileType = FileTypeCategory.unknown;
        }
      } else {
        // Fallback: detect from decrypted content for old documents
        final detectedInfo = FileTypeDetector.detectFromBytes(
          decryptedBytes,
          fileName: name,
        );
        fileType = detectedInfo.category;
        mimeType = detectedInfo.mimeType;
        print('File type not in database, detected: ${fileType.name}, MIME: $mimeType');
      }

      // Save the decrypted file temporarily for viewing
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/$name';
      File tempFile = File(tempPath);
      await tempFile.writeAsBytes(decryptedBytes);

      // Navigate to a viewer screen based on detected file type
      if (mounted) {
        switch (fileType) {
          case FileTypeCategory.pdf:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewerScreen(
                  filePath: tempPath,
                  fileName: name,
                  mimeType: mimeType,
                ),
              ),
            );
            break;
          case FileTypeCategory.image:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewerScreen(
                  filePath: tempPath,
                  fileName: name,
                  mimeType: mimeType,
                ),
              ),
            );
            break;
          case FileTypeCategory.audio:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AudioViewerScreen(
                  encryptedPath: encryptedPath,
                  encryptedKey: encryptedKeyBase64,
                  iv: ivBase64,
                  hmac: hmacBase64,
                  fileName: name,
                  mimeType: mimeType,
                ),
              ),
            );
            break;
          default:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GenericFileViewerScreen(
                  filePath: tempPath,
                  fileName: name,
                  fileType: fileType,
                  mimeType: mimeType,
                ),
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
      appBar: AppBar(
        title: const Text('Document List'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _documents.isEmpty
          ? const Center(child: Text('No documents uploaded yet.'))
          : _filteredDocuments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No documents found for "$_searchQuery"',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredDocuments.length,
                  itemBuilder: (context, index) {
                    final doc = _filteredDocuments[index];
                    final uploadDate = doc['upload_date'] != null
                        ? DateTime.parse(doc['upload_date'])
                        : null;
                    final fileType = doc['file_type'];
                    
                    return ListTile(
                      leading: Icon(
                        _getFileTypeIcon(fileType),
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(doc['name']),
                      subtitle: uploadDate != null
                          ? Text(
                              _formatDate(uploadDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showRenameDialog(
                              doc['id'],
                              doc['name'],
                            ),
                            tooltip: 'Rename',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteDialog(doc['id']),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                      onTap: () =>
                          _openDocument(doc['id'], doc['path'], doc['name']),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      // Format as date for older files
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  IconData _getFileTypeIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file;
    
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'text':
        return Icons.text_snippet;
      case 'document':
        return Icons.description;
      case 'archive':
        return Icons.folder_zip;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
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
  final String? mimeType;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    this.mimeType,
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
                  content: Text(
                    'File: $fileName\n'
                    'Type: PDF\n'
                    '${mimeType != null ? 'MIME: $mimeType' : ''}',
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
  final String? mimeType;

  const ImageViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    this.mimeType,
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
                  content: Text(
                    'File: $fileName\n'
                    'Type: Image\n'
                    '${mimeType != null ? 'MIME: $mimeType' : ''}',
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
  Widget build(BuildContext context) {
    print('file path: $filePath');
    print('File name: $fileName');
    print('File type: ${fileType.name}');
    print('MIME type: $mimeType');

    return Scaffold(
      appBar: AppBar(title: Text(fileName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFileIcon(fileType),
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
                'File Type: ${_getFileTypeLabel(fileType)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (mimeType != null) ...[
                const SizedBox(height: 5),
                Text(
                  'MIME: $mimeType',
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

/// Audio Viewer Screen for audio files
class AudioViewerScreen extends StatelessWidget {
  final String encryptedPath;
  final String encryptedKey;
  final String iv;
  final String? hmac;
  final String fileName;
  final String? mimeType;

  const AudioViewerScreen({
    super.key,
    required this.encryptedPath,
    required this.encryptedKey,
    required this.iv,
    this.hmac,
    required this.fileName,
    this.mimeType,
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
                  title: const Text('Audio Info'),
                  content: Text(
                    'File: $fileName\n'
                    'Type: Audio\n'
                    '${mimeType != null ? 'MIME: $mimeType' : ''}',
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Audio icon
              Icon(
                Icons.audiotrack,
                size: 100,
                color: Colors.red[700],
              ),
              const SizedBox(height: 40),

              // Audio player widget
              AudioPlayerWidget(
                encryptedPath: encryptedPath,
                encryptedKey: encryptedKey,
                iv: iv,
                hmac: hmac,
                fileName: fileName,
              ),
              const SizedBox(height: 40),

              // Info text
              Text(
                'Tap play to listen to your vocal memo',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
