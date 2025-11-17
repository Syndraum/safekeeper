import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../core/base_view_model.dart';
import '../services/encryption_service.dart';
import '../services/document_service.dart';
import '../services/file_type_detector.dart';
import '../services/cloud_backup_service.dart';
import '../services/settings_service.dart';

class UploadViewModel extends BaseViewModel {
  final EncryptionService _encryptionService;
  final DocumentService _documentService;
  final CloudBackupService _backupService;
  final SettingsService _settingsService;
  final ImagePicker _imagePicker;

  UploadViewModel({
    required EncryptionService encryptionService,
    required DocumentService documentService,
    required CloudBackupService backupService,
    required SettingsService settingsService,
    ImagePicker? imagePicker,
  })  : _encryptionService = encryptionService,
        _documentService = documentService,
        _backupService = backupService,
        _settingsService = settingsService,
        _imagePicker = imagePicker ?? ImagePicker();

  /// Pick a file and upload it
  Future<UploadResult?> pickAndUploadFile(String fileName) async {
    return await runBusyFuture<UploadResult?>(
      () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result == null) {
          return null;
        }

        File file = File(result.files.single.path!);
        return await _encryptAndSaveFile(file, fileName);
      },
      errorMessage: 'Failed to pick and upload file',
    );
  }

  /// Take a picture and upload it
  Future<UploadResult?> takePictureAndUpload(String fileName) async {
    return await runBusyFuture<UploadResult?>(
      () async {
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );

        if (photo == null) {
          return null;
        }

        File file = File(photo.path);
        return await _encryptAndSaveFile(file, fileName);
      },
      errorMessage: 'Failed to take picture',
    );
  }

  /// Upload a vocal memo
  Future<UploadResult?> uploadVocalMemo(String filePath, String fileName) async {
    return await runBusyFuture(
      () async {
        File file = File(filePath);
        return await _encryptAndSaveFile(file, fileName);
      },
      errorMessage: 'Failed to upload vocal memo',
    );
  }

  /// Common method to encrypt and save a file using hybrid encryption
  Future<UploadResult> _encryptAndSaveFile(File file, String fileName) async {
    // Read file bytes
    Uint8List fileBytes = await file.readAsBytes();

    // Detect file type from content (not extension)
    final fileTypeInfo = FileTypeDetector.detectFromBytes(
      fileBytes,
      fileName: fileName,
    );

    // Encrypt file using hybrid encryption (AES + RSA)
    final encryptionResult = await _encryptionService.encryptFile(fileBytes);

    // Save the encrypted file locally
    Directory appDir = await getApplicationDocumentsDirectory();
    String encryptedPath = '${appDir.path}/$fileName.enc';
    File encryptedFile = File(encryptedPath);
    await encryptedFile.writeAsBytes(encryptionResult.encryptedData);

    // Convert encrypted key, IV, and HMAC to base64 for storage
    final base64Map = encryptionResult.toBase64Map();

    // Save document metadata to database with detected file type
    await _documentService.addDocument(
      fileName,
      encryptedPath,
      base64Map['encryptedKey']!,
      base64Map['iv']!,
      hmac: base64Map['hmac'],
      mimeType: fileTypeInfo.mimeType,
      fileType: fileTypeInfo.category.name,
    );

    // Get the document ID of the newly added document
    final documents = await _documentService.getDocuments();
    final newDocument = documents.lastWhere(
      (doc) => doc['name'] == fileName && doc['path'] == encryptedPath,
    );
    final documentId = newDocument['id'] as int;

    // Trigger cloud backup if enabled and auto-backup is on
    bool backupStarted = false;
    if (_settingsService.isBackupEnabled() &&
        _settingsService.isAutoBackupEnabled()) {
      backupStarted = true;
      // Start backup in background (don't await)
      _backupService.backupDocument(documentId, encryptedPath).catchError((e) {
        // Backup error will be handled by the service
        return null;
      });
    }

    return UploadResult(
      success: true,
      fileName: fileName,
      fileType: fileTypeInfo.category.name,
      documentId: documentId,
      backupStarted: backupStarted,
    );
  }

  /// Generate default file name for photos
  String generatePhotoName() {
    return 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  /// Generate default file name for vocal memos
  String generateVocalMemoName() {
    return 'vocal_memo_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  /// Rename a document after upload
  Future<bool> renameDocument(int documentId, String newName) async {
    final result = await runBusyFuture<bool>(
      () async {
        await _documentService.updateDocumentName(documentId, newName);
        return true;
      },
      errorMessage: 'Failed to rename document',
    );
    return result ?? false;
  }
}

/// Result of an upload operation
class UploadResult {
  final bool success;
  final String fileName;
  final String fileType;
  final int documentId;
  final bool backupStarted;

  UploadResult({
    required this.success,
    required this.fileName,
    required this.fileType,
    required this.documentId,
    required this.backupStarted,
  });
}
