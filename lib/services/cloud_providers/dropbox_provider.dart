import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../settings_service.dart';
import 'cloud_provider_interface.dart';

/// Dropbox cloud storage provider implementation
class DropboxProvider implements CloudProviderInterface {
  static final DropboxProvider _instance = DropboxProvider._internal();
  factory DropboxProvider() => _instance;
  DropboxProvider._internal();

  final _settingsService = SettingsService();

  // Dropbox OAuth credentials - REPLACE WITH YOUR OWN
  static const String _appKey = 'YOUR_DROPBOX_APP_KEY';
  static const String _appSecret = 'YOUR_DROPBOX_APP_SECRET';
  static const String _redirectUri = 'safekeeper://oauth-callback';
  
  // API endpoints
  static const String _authUrl = 'https://www.dropbox.com/oauth2/authorize';
  static const String _tokenUrl = 'https://api.dropbox.com/oauth2/token';
  static const String _apiUrl = 'https://api.dropboxapi.com/2';
  static const String _contentUrl = 'https://content.dropboxapi.com/2';
  
  // Folder path for SafeKeeper backups
  static const String _backupFolderPath = '/SafeKeeper_Backups';

  @override
  String get providerName => 'Dropbox';

  @override
  Future<bool> isAuthenticated() async {
    final token = _settingsService.getDropboxToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<bool> authenticate() async {
    try {
      // Build authorization URL
      final authUri = Uri.parse(_authUrl).replace(queryParameters: {
        'client_id': _appKey,
        'response_type': 'code',
        'redirect_uri': _redirectUri,
        'token_access_type': 'offline', // Request refresh token
      });

      // Launch browser for OAuth
      if (await canLaunchUrl(authUri)) {
        await launchUrl(authUri, mode: LaunchMode.externalApplication);
        
        // Note: In a real implementation, you would need to handle the callback
        // and extract the authorization code. This is a simplified version.
        // You might need to implement a custom URL scheme handler or use
        // a package like flutter_web_auth for proper OAuth flow.
        
        return true;
      } else {
        throw CloudProviderException(
          'Could not launch authentication URL',
          providerName: providerName,
        );
      }
    } catch (e) {
      print('Dropbox authentication error: $e');
      return false;
    }
  }

  /// Exchange authorization code for access token
  Future<bool> exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'code': code,
          'grant_type': 'authorization_code',
          'client_id': _appKey,
          'client_secret': _appSecret,
          'redirect_uri': _redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _settingsService.setDropboxToken(data['access_token']);
        if (data['refresh_token'] != null) {
          await _settingsService.setDropboxRefreshToken(data['refresh_token']);
        }
        
        // Create backup folder
        await _ensureBackupFolder();
        
        return true;
      } else {
        print('Token exchange failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Token exchange error: $e');
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    await _settingsService.clearDropboxAuth();
  }

  @override
  Future<bool> refreshToken() async {
    try {
      final refreshToken = _settingsService.getDropboxRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': _appKey,
          'client_secret': _appSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _settingsService.setDropboxToken(data['access_token']);
        return true;
      } else {
        print('Token refresh failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }

  /// Get authorization headers
  Map<String, String> _getHeaders() {
    final token = _settingsService.getDropboxToken();
    if (token == null) {
      throw CloudProviderException(
        'Not authenticated',
        providerName: providerName,
      );
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Ensure backup folder exists
  Future<void> _ensureBackupFolder() async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/files/create_folder_v2'),
        headers: _getHeaders(),
        body: json.encode({
          'path': _backupFolderPath,
          'autorename': false,
        }),
      );

      // 200 = created, 409 = already exists (which is fine)
      if (response.statusCode != 200 && response.statusCode != 409) {
        print('Create folder response: ${response.body}');
      }
    } catch (e) {
      print('Ensure folder error: $e');
      // Don't throw - folder might already exist
    }
  }

  @override
  Future<UploadResult> uploadFile({
    required String fileName,
    required Uint8List fileData,
    Map<String, String>? metadata,
  }) async {
    try {
      final filePath = '$_backupFolderPath/$fileName';
      
      final headers = {
        'Authorization': 'Bearer ${_settingsService.getDropboxToken()}',
        'Content-Type': 'application/octet-stream',
        'Dropbox-API-Arg': json.encode({
          'path': filePath,
          'mode': 'overwrite',
          'autorename': false,
          'mute': false,
        }),
      };

      final response = await http.post(
        Uri.parse('$_contentUrl/files/upload'),
        headers: headers,
        body: fileData,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UploadResult.success(data['path_display']);
      } else {
        print('Dropbox upload error: ${response.body}');
        
        // Try to refresh token and retry once
        if (response.statusCode == 401) {
          final refreshed = await refreshToken();
          if (refreshed) {
            return uploadFile(
              fileName: fileName,
              fileData: fileData,
              metadata: metadata,
            );
          }
        }
        
        return UploadResult.failure('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Dropbox upload error: $e');
      return UploadResult.failure('Upload failed: $e');
    }
  }

  @override
  Future<DownloadResult> downloadFile(String filePath) async {
    try {
      final headers = {
        'Authorization': 'Bearer ${_settingsService.getDropboxToken()}',
        'Dropbox-API-Arg': json.encode({
          'path': filePath,
        }),
      };

      final response = await http.post(
        Uri.parse('$_contentUrl/files/download'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return DownloadResult.success(response.bodyBytes);
      } else {
        print('Dropbox download error: ${response.body}');
        
        // Try to refresh token and retry once
        if (response.statusCode == 401) {
          final refreshed = await refreshToken();
          if (refreshed) {
            return downloadFile(filePath);
          }
        }
        
        return DownloadResult.failure('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Dropbox download error: $e');
      return DownloadResult.failure('Download failed: $e');
    }
  }

  @override
  Future<bool> deleteFile(String filePath) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/files/delete_v2'),
        headers: _getHeaders(),
        body: json.encode({
          'path': filePath,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Dropbox delete error: $e');
      return false;
    }
  }

  @override
  Future<List<CloudFileMetadata>> listFiles() async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/files/list_folder'),
        headers: _getHeaders(),
        body: json.encode({
          'path': _backupFolderPath,
          'recursive': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final entries = data['entries'] as List;
        
        return entries.map((entry) {
          return CloudFileMetadata(
            id: entry['path_display'],
            name: entry['name'],
            size: entry['size'] ?? 0,
            modifiedTime: entry['client_modified'] != null
                ? DateTime.parse(entry['client_modified'])
                : null,
          );
        }).toList();
      } else {
        print('Dropbox list error: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Dropbox list error: $e');
      return [];
    }
  }

  @override
  Future<bool> fileExists(String filePath) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/files/get_metadata'),
        headers: _getHeaders(),
        body: json.encode({
          'path': filePath,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int?> getAvailableSpace() async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/users/get_space_usage'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allocated = data['allocation']['allocated'] as int;
        final used = data['used'] as int;
        return allocated - used;
      }
      return null;
    } catch (e) {
      print('Dropbox storage check error: $e');
      return null;
    }
  }
}
