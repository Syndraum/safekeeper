import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../core/base_view_model.dart';
import '../services/document_service.dart';
import '../services/encryption_service.dart';
import '../services/cloud_backup_service.dart';
import '../services/cache_service.dart';
import '../services/file_type_detector.dart';
import '../models/backup_status.dart' show DocumentBackupStatus;

class DocumentListViewModel extends BaseViewModel {
  final DocumentService _documentService;
  final EncryptionService _encryptionService;
  final CloudBackupService _backupService;
  final CacheService _cacheService;

  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _filteredDocuments = [];
  String _searchQuery = '';

  DocumentListViewModel({
    required DocumentService documentService,
    required EncryptionService encryptionService,
    required CloudBackupService backupService,
    required CacheService cacheService,
  })  : _documentService = documentService,
        _encryptionService = encryptionService,
        _backupService = backupService,
        _cacheService = cacheService;

  // Getters
  List<Map<String, dynamic>> get documents => _filteredDocuments;
  String get searchQuery => _searchQuery;
  bool get hasDocuments => _documents.isNotEmpty;
  bool get hasFilteredDocuments => _filteredDocuments.isNotEmpty;

  /// Initialize and load documents
  Future<void> initialize() async {
    await loadDocuments();
  }

  /// Load all documents from database
  Future<void> loadDocuments() async {
    await runBusyFuture(
      () async {
        _documents = await _documentService.getDocuments();
        _filterDocuments();
      },
      errorMessage: 'Failed to load documents',
    );
  }

  /// Update search query and filter documents
  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _filterDocuments();
    notifyListeners();
  }

  /// Clear search query
  void clearSearch() {
    _searchQuery = '';
    _filterDocuments();
    notifyListeners();
  }

  /// Filter documents based on search query
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

  /// Rename a document
  Future<bool> renameDocument(int id, String newName) async {
    final result = await runBusyFutureWithSuccess(
      () async {
        await _documentService.updateDocumentName(id, newName);
        await loadDocuments();
      },
      successMessage: 'Document renamed successfully',
      errorMessage: 'Failed to rename document',
    );
    return result != null;
  }

  /// Delete a document
  Future<bool> deleteDocument(int id) async {
    final result = await runBusyFutureWithSuccess(
      () async {
        await _documentService.deleteDocument(id);
        await loadDocuments();
      },
      successMessage: 'Document deleted successfully',
      errorMessage: 'Failed to delete document',
    );
    return result != null;
  }

  /// Open and decrypt a document
  Future<DecryptedDocumentResult?> openDocument(
    int documentId,
    String encryptedPath,
    String name,
  ) async {
    return await runBusyFuture(
      () async {
        // Get document metadata from database
        final doc = await _documentService.getDocument(documentId);
        if (doc == null) {
          throw Exception('Document not found in database');
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
          try {
            fileType = FileTypeCategory.values.firstWhere(
              (e) => e.name == fileTypeStr,
              orElse: () => FileTypeCategory.unknown,
            );
          } catch (e) {
            fileType = FileTypeCategory.unknown;
          }
        } else {
          final detectedInfo = FileTypeDetector.detectFromBytes(
            decryptedBytes,
            fileName: name,
          );
          fileType = detectedInfo.category;
          mimeType = detectedInfo.mimeType;
        }

        // Save the decrypted file temporarily for viewing
        Directory tempDir = await getTemporaryDirectory();
        String tempPath = '${tempDir.path}/$name';
        File tempFile = File(tempPath);
        await tempFile.writeAsBytes(decryptedBytes);

        // Track the temporary file for cleanup
        _cacheService.trackFile(tempPath);

        return DecryptedDocumentResult(
          tempPath: tempPath,
          fileName: name,
          fileType: fileType,
          mimeType: mimeType,
          encryptedPath: encryptedPath,
          encryptedKey: encryptedKeyBase64,
          iv: ivBase64,
          hmac: hmacBase64,
        );
      },
      errorMessage: 'Failed to open document',
    );
  }

  /// Sync all documents to cloud
  Future<bool> syncAllDocuments() async {
    final result = await runBusyFutureWithSuccess(
      () async {
        await _backupService.syncAllDocuments();
      },
      successMessage: 'All documents synced successfully!',
      errorMessage: 'Sync failed',
    );
    return result != null;
  }

  /// Get backup status for a document
  DocumentBackupStatus? getBackupStatus(int documentId) {
    return _backupService.getBackupStatus(documentId);
  }

  /// Format date for display
  String formatDate(DateTime date) {
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
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Result of decrypting a document
class DecryptedDocumentResult {
  final String tempPath;
  final String fileName;
  final FileTypeCategory fileType;
  final String? mimeType;
  final String encryptedPath;
  final String encryptedKey;
  final String iv;
  final String? hmac;

  DecryptedDocumentResult({
    required this.tempPath,
    required this.fileName,
    required this.fileType,
    this.mimeType,
    required this.encryptedPath,
    required this.encryptedKey,
    required this.iv,
    this.hmac,
  });
}
