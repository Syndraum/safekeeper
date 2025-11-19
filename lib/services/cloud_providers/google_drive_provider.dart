import '../../core/logger_service.dart';

import 'dart:typed_data';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../settings_service.dart';
import 'cloud_provider_interface.dart';

/// Google Drive cloud storage provider implementation
class GoogleDriveProvider implements CloudProviderInterface {
  static final GoogleDriveProvider _instance = GoogleDriveProvider._internal();
  factory GoogleDriveProvider() => _instance;
  GoogleDriveProvider._internal();

  final _settingsService = SettingsService();
  drive.DriveApi? _driveApi;
  AutoRefreshingAuthClient? _authClient;

  // Google OAuth credentials - REPLACE WITH YOUR OWN
  static const String _clientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
  static const String _clientSecret = 'YOUR_CLIENT_SECRET';
  static const List<String> _scopes = [drive.DriveApi.driveFileScope];
  
  // Folder name for SafeKeeper backups
  static const String _backupFolderName = 'SafeKeeper_Backups';
  String? _backupFolderId;

  @override
  String get providerName => 'Google Drive';

  @override
  Future<bool> isAuthenticated() async {
    final token = _settingsService.getGoogleDriveToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<bool> authenticate() async {
    try {
      // Create client ID
      final clientId = ClientId(_clientId, _clientSecret);

      // Prompt user for consent
      final authClient = await clientViaUserConsent(
        clientId,
        _scopes,
        _promptUserForConsent,
      );

      _authClient = autoRefreshingClient(
        clientId,
        authClient.credentials,
        http.Client(),
      );

      // Save tokens
      await _settingsService.setGoogleDriveToken(
        authClient.credentials.accessToken.data,
      );
      if (authClient.credentials.refreshToken != null) {
        await _settingsService.setGoogleDriveRefreshToken(
          authClient.credentials.refreshToken,
        );
      }

      // Initialize Drive API
      _driveApi = drive.DriveApi(_authClient!);

      // Create or get backup folder
      await _ensureBackupFolder();

      return true;
    } catch (e) {
      AppLogger.error('Google Drive authentication error', e);
      return false;
    }
  }

  /// Prompt user for OAuth consent
  Future<void> _promptUserForConsent(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw CloudProviderException(
        'Could not launch authentication URL',
        providerName: providerName,
      );
    }
  }

  @override
  Future<void> signOut() async {
    _driveApi = null;
    _authClient?.close();
    _authClient = null;
    _backupFolderId = null;
    await _settingsService.clearGoogleDriveAuth();
  }

  @override
  Future<bool> refreshToken() async {
    try {
      final refreshToken = _settingsService.getGoogleDriveRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final clientId = ClientId(_clientId, _clientSecret);
      final credentials = AccessCredentials(
        AccessToken('Bearer', '', DateTime.now().toUtc()),
        refreshToken,
        _scopes,
      );

      _authClient = autoRefreshingClient(clientId, credentials, http.Client());
      _driveApi = drive.DriveApi(_authClient!);

      // Save new access token
      await _settingsService.setGoogleDriveToken(
        credentials.accessToken.data,
      );

      return true;
    } catch (e) {
      AppLogger.error('Token refresh error', e);
      return false;
    }
  }

  /// Ensure Drive API is initialized
  Future<void> _ensureDriveApi() async {
    if (_driveApi == null) {
      final token = _settingsService.getGoogleDriveToken();
      if (token == null) {
        throw CloudProviderException(
          'Not authenticated',
          providerName: providerName,
        );
      }

      // Try to refresh token
      final refreshed = await refreshToken();
      if (!refreshed) {
        throw CloudProviderException(
          'Failed to refresh authentication',
          providerName: providerName,
        );
      }
    }
  }

  /// Ensure backup folder exists, create if not
  Future<void> _ensureBackupFolder() async {
    await _ensureDriveApi();

    try {
      // Search for existing folder
      final query = "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final fileList = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        _backupFolderId = fileList.files!.first.id;
      } else {
        // Create folder
        final folder = drive.File()
          ..name = _backupFolderName
          ..mimeType = 'application/vnd.google-apps.folder';

        final createdFolder = await _driveApi!.files.create(folder);
        _backupFolderId = createdFolder.id;
      }
    } catch (e) {
      throw CloudProviderException(
        'Failed to create backup folder: $e',
        providerName: providerName,
        originalError: e,
      );
    }
  }

  @override
  Future<UploadResult> uploadFile({
    required String fileName,
    required Uint8List fileData,
    Map<String, String>? metadata,
  }) async {
    try {
      await _ensureDriveApi();
      await _ensureBackupFolder();

      // Create file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [_backupFolderId!];

      // Add custom properties if metadata provided
      if (metadata != null) {
        driveFile.properties = metadata;
      }

      // Upload file
      final media = drive.Media(
        Stream.value(fileData),
        fileData.length,
      );

      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, name, size',
      );

      return UploadResult.success(uploadedFile.id!);
    } catch (e) {
      AppLogger.error('Google Drive upload error', e);
      return UploadResult.failure('Upload failed: $e');
    }
  }

  @override
  Future<DownloadResult> downloadFile(String fileId) async {
    try {
      await _ensureDriveApi();

      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dataBytes = <int>[];
      await for (var chunk in media.stream) {
        dataBytes.addAll(chunk);
      }

      return DownloadResult.success(Uint8List.fromList(dataBytes));
    } catch (e) {
      AppLogger.error('Google Drive download error', e);
      return DownloadResult.failure('Download failed: $e');
    }
  }

  @override
  Future<bool> deleteFile(String fileId) async {
    try {
      await _ensureDriveApi();
      await _driveApi!.files.delete(fileId);
      return true;
    } catch (e) {
      AppLogger.error('Google Drive delete error', e);
      return false;
    }
  }

  @override
  Future<List<CloudFileMetadata>> listFiles() async {
    try {
      await _ensureDriveApi();
      await _ensureBackupFolder();

      final query = "'$_backupFolderId' in parents and trashed=false";
      final fileList = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name, size, modifiedTime)',
      );

      if (fileList.files == null) {
        return [];
      }

      return fileList.files!.map((file) {
        return CloudFileMetadata(
          id: file.id!,
          name: file.name!,
          size: int.tryParse(file.size ?? '0') ?? 0,
          modifiedTime: file.modifiedTime,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Google Drive list error', e);
      return [];
    }
  }

  @override
  Future<bool> fileExists(String fileId) async {
    try {
      await _ensureDriveApi();
      final file = await _driveApi!.files.get(fileId, $fields: 'id') as drive.File;
      return file.id != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int?> getAvailableSpace() async {
    try {
      await _ensureDriveApi();
      final about = await _driveApi!.about.get($fields: 'storageQuota');
      
      if (about.storageQuota != null) {
        final limit = int.tryParse(about.storageQuota!.limit ?? '0') ?? 0;
        final usage = int.tryParse(about.storageQuota!.usage ?? '0') ?? 0;
        return limit - usage;
      }
      return null;
    } catch (e) {
      AppLogger.error('Google Drive storage check error', e);
      return null;
    }
  }
}
