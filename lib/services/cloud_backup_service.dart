import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/backup_status.dart';
import 'cloud_providers/cloud_provider_interface.dart';
import 'cloud_providers/google_drive_provider.dart';
import 'cloud_providers/dropbox_provider.dart';
import 'settings_service.dart';
import 'document_service.dart';

/// Service for managing cloud backups across multiple providers
class CloudBackupService {
  static final CloudBackupService _instance = CloudBackupService._internal();
  factory CloudBackupService() => _instance;
  CloudBackupService._internal();

  final _settingsService = SettingsService();
  final _documentService = DocumentService();
  final _googleDriveProvider = GoogleDriveProvider();
  final _dropboxProvider = DropboxProvider();

  // Upload queue and progress tracking
  final Map<int, DocumentBackupStatus> _backupStatuses = {};
  final StreamController<DocumentBackupStatus> _statusController =
      StreamController<DocumentBackupStatus>.broadcast();

  /// Stream of backup status updates
  Stream<DocumentBackupStatus> get statusStream => _statusController.stream;

  /// Get provider instance by name
  CloudProviderInterface? _getProvider(String providerName) {
    switch (providerName) {
      case 'google_drive':
        return _googleDriveProvider;
      case 'dropbox':
        return _dropboxProvider;
      default:
        return null;
    }
  }

  /// Initialize the backup service
  Future<void> initialize() async {
    // Load existing backup statuses from database
    await _loadBackupStatuses();
  }

  /// Load backup statuses from database
  Future<void> _loadBackupStatuses() async {
    try {
      final documents = await _documentService.getDocuments();
      for (final doc in documents) {
        final status = _createStatusFromDocument(doc);
        _backupStatuses[doc['id']] = status;
      }
    } catch (e) {
      print('Error loading backup statuses: $e');
    }
  }

  /// Create backup status from document data
  DocumentBackupStatus _createStatusFromDocument(Map<String, dynamic> doc) {
    final providers = <String, ProviderBackupStatus>{};

    // Google Drive status
    if (doc['google_drive_backup_status'] != null) {
      providers['google_drive'] = ProviderBackupStatus(
        provider: 'google_drive',
        state: _parseBackupState(doc['google_drive_backup_status']),
        fileId: doc['google_drive_file_id'],
        lastBackupDate: doc['last_backup_date'] != null
            ? DateTime.parse(doc['last_backup_date'])
            : null,
      );
    }

    // Dropbox status
    if (doc['dropbox_backup_status'] != null) {
      providers['dropbox'] = ProviderBackupStatus(
        provider: 'dropbox',
        state: _parseBackupState(doc['dropbox_backup_status']),
        fileId: doc['dropbox_file_path'],
        lastBackupDate: doc['last_backup_date'] != null
            ? DateTime.parse(doc['last_backup_date'])
            : null,
      );
    }

    return DocumentBackupStatus(
      documentId: doc['id'],
      providers: providers,
    );
  }

  /// Parse backup state from string
  BackupState _parseBackupState(String? state) {
    if (state == null) return BackupState.none;
    return BackupState.values.firstWhere(
      (e) => e.name == state,
      orElse: () => BackupState.none,
    );
  }

  /// Backup a document to all enabled providers
  Future<void> backupDocument(int documentId, String encryptedFilePath) async {
    if (!_settingsService.isBackupEnabled()) {
      print('Backup is disabled');
      return;
    }

    final enabledProviders = _settingsService.getEnabledProviders();
    if (enabledProviders.isEmpty) {
      print('No providers enabled');
      return;
    }

    // Get document info
    final doc = await _documentService.getDocument(documentId);
    if (doc == null) {
      print('Document not found: $documentId');
      return;
    }

    // Read encrypted file
    final file = File(encryptedFilePath);
    if (!await file.exists()) {
      print('File not found: $encryptedFilePath');
      return;
    }

    final fileData = await file.readAsBytes();
    final fileName = doc['name'] as String;

    // Initialize status
    final status = DocumentBackupStatus(
      documentId: documentId,
      providers: {},
    );

    // Backup to each enabled provider
    for (final providerName in enabledProviders) {
      await _backupToProvider(
        documentId,
        providerName,
        fileName,
        fileData,
        status,
        doc,
      );
    }

    // Save final status
    _backupStatuses[documentId] = status;
    _statusController.add(status);
  }

  /// Backup to a specific provider
  Future<void> _backupToProvider(
    int documentId,
    String providerName,
    String fileName,
    Uint8List fileData,
    DocumentBackupStatus status,
    Map<String, dynamic> doc,
  ) async {
    final provider = _getProvider(providerName);
    if (provider == null) {
      print('Unknown provider: $providerName');
      return;
    }

    // Update status to uploading
    status.providers[providerName] = ProviderBackupStatus(
      provider: providerName,
      state: BackupState.uploading,
    );
    _statusController.add(status);

    try {
      // Check authentication
      if (!await provider.isAuthenticated()) {
        throw Exception('Provider not authenticated');
      }

      // Prepare metadata
      final metadata = <String, String>{
        'original_name': fileName,
        'document_id': documentId.toString(),
        'mime_type': doc['mime_type']?.toString() ?? '',
        'file_type': doc['file_type']?.toString() ?? '',
        'upload_date': doc['upload_date']?.toString() ?? '',
      };

      // Upload file
      final result = await provider.uploadFile(
        fileName: '$fileName.enc',
        fileData: fileData,
        metadata: metadata,
      );

      if (result.success) {
        // Update status to completed
        status.providers[providerName] = ProviderBackupStatus(
          provider: providerName,
          state: BackupState.completed,
          fileId: result.fileId,
          lastBackupDate: DateTime.now(),
        );

        // Update database
        await _updateDatabaseBackupStatus(
          documentId,
          providerName,
          BackupState.completed,
          result.fileId,
        );

        print('Successfully backed up to $providerName: ${result.fileId}');
      } else {
        throw Exception(result.errorMessage ?? 'Upload failed');
      }
    } catch (e) {
      print('Backup to $providerName failed: $e');
      
      // Update status to failed
      status.providers[providerName] = ProviderBackupStatus(
        provider: providerName,
        state: BackupState.failed,
        errorMessage: e.toString(),
      );

      // Update database
      await _updateDatabaseBackupStatus(
        documentId,
        providerName,
        BackupState.failed,
        null,
      );
    }

    _statusController.add(status);
  }

  /// Update backup status in database
  Future<void> _updateDatabaseBackupStatus(
    int documentId,
    String providerName,
    BackupState state,
    String? fileId,
  ) async {
    final db = await _documentService.database;
    
    final updates = <String, dynamic>{
      'last_backup_date': DateTime.now().toIso8601String(),
    };

    if (providerName == 'google_drive') {
      updates['google_drive_backup_status'] = state.name;
      if (fileId != null) {
        updates['google_drive_file_id'] = fileId;
      }
    } else if (providerName == 'dropbox') {
      updates['dropbox_backup_status'] = state.name;
      if (fileId != null) {
        updates['dropbox_file_path'] = fileId;
      }
    }

    await db.update(
      'documents',
      updates,
      where: 'id = ?',
      whereArgs: [documentId],
    );
  }

  /// Sync all documents that need backup
  Future<void> syncAllDocuments() async {
    if (!_settingsService.isBackupEnabled()) {
      print('Backup is disabled');
      return;
    }

    final documents = await _documentService.getDocuments();
    
    for (final doc in documents) {
      final documentId = doc['id'] as int;
      final filePath = doc['path'] as String;
      
      // Check if document needs backup
      if (await _needsBackup(documentId)) {
        await backupDocument(documentId, filePath);
      }
    }
  }

  /// Check if a document needs backup
  Future<bool> _needsBackup(int documentId) async {
    final status = _backupStatuses[documentId];
    if (status == null) return true;

    final enabledProviders = _settingsService.getEnabledProviders();
    
    for (final provider in enabledProviders) {
      final providerStatus = status.getProviderStatus(provider);
      if (providerStatus == null || 
          providerStatus.state == BackupState.none ||
          providerStatus.state == BackupState.failed) {
        return true;
      }
    }

    return false;
  }

  /// Restore a document from cloud
  Future<Uint8List?> restoreDocument(int documentId, String providerName) async {
    final provider = _getProvider(providerName);
    if (provider == null) {
      print('Unknown provider: $providerName');
      return null;
    }

    final status = _backupStatuses[documentId];
    if (status == null) {
      print('No backup status for document: $documentId');
      return null;
    }

    final providerStatus = status.getProviderStatus(providerName);
    if (providerStatus == null || providerStatus.fileId == null) {
      print('No backup found for provider: $providerName');
      return null;
    }

    try {
      final result = await provider.downloadFile(providerStatus.fileId!);
      if (result.success) {
        return result.data;
      } else {
        print('Download failed: ${result.errorMessage}');
        return null;
      }
    } catch (e) {
      print('Restore error: $e');
      return null;
    }
  }

  /// Get backup status for a document
  DocumentBackupStatus? getBackupStatus(int documentId) {
    return _backupStatuses[documentId];
  }

  /// Delete backup from cloud
  Future<bool> deleteBackup(int documentId, String providerName) async {
    final provider = _getProvider(providerName);
    if (provider == null) return false;

    final status = _backupStatuses[documentId];
    if (status == null) return false;

    final providerStatus = status.getProviderStatus(providerName);
    if (providerStatus == null || providerStatus.fileId == null) {
      return false;
    }

    try {
      final success = await provider.deleteFile(providerStatus.fileId!);
      if (success) {
        // Update status
        status.providers.remove(providerName);
        _backupStatuses[documentId] = status;
        _statusController.add(status);

        // Update database
        await _updateDatabaseBackupStatus(
          documentId,
          providerName,
          BackupState.none,
          null,
        );
      }
      return success;
    } catch (e) {
      print('Delete backup error: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
  }
}
