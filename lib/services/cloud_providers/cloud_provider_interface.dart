import 'dart:typed_data';

/// Result of a file upload operation
class UploadResult {
  final bool success;
  final String? fileId;  // Cloud file ID or path
  final String? errorMessage;

  UploadResult({
    required this.success,
    this.fileId,
    this.errorMessage,
  });

  factory UploadResult.success(String fileId) {
    return UploadResult(success: true, fileId: fileId);
  }

  factory UploadResult.failure(String errorMessage) {
    return UploadResult(success: false, errorMessage: errorMessage);
  }
}

/// Result of a file download operation
class DownloadResult {
  final bool success;
  final Uint8List? data;
  final String? errorMessage;

  DownloadResult({
    required this.success,
    this.data,
    this.errorMessage,
  });

  factory DownloadResult.success(Uint8List data) {
    return DownloadResult(success: true, data: data);
  }

  factory DownloadResult.failure(String errorMessage) {
    return DownloadResult(success: false, errorMessage: errorMessage);
  }
}

/// Cloud file metadata
class CloudFileMetadata {
  final String id;
  final String name;
  final int size;
  final DateTime? modifiedTime;

  CloudFileMetadata({
    required this.id,
    required this.name,
    required this.size,
    this.modifiedTime,
  });
}

/// Abstract interface for cloud storage providers
abstract class CloudProviderInterface {
  /// Get the provider name
  String get providerName;

  /// Check if the provider is authenticated
  Future<bool> isAuthenticated();

  /// Authenticate with the provider
  /// Returns true if authentication was successful
  Future<bool> authenticate();

  /// Sign out from the provider
  Future<void> signOut();

  /// Upload a file to the cloud
  /// [fileName] - Name of the file
  /// [fileData] - File content as bytes
  /// [metadata] - Optional metadata (e.g., original name, encryption info)
  Future<UploadResult> uploadFile({
    required String fileName,
    required Uint8List fileData,
    Map<String, String>? metadata,
  });

  /// Download a file from the cloud
  /// [fileId] - Cloud file ID or path
  Future<DownloadResult> downloadFile(String fileId);

  /// Delete a file from the cloud
  /// [fileId] - Cloud file ID or path
  Future<bool> deleteFile(String fileId);

  /// List all files in the backup folder
  Future<List<CloudFileMetadata>> listFiles();

  /// Check if a file exists
  /// [fileId] - Cloud file ID or path
  Future<bool> fileExists(String fileId);

  /// Get available storage space (in bytes)
  /// Returns null if not available
  Future<int?> getAvailableSpace();

  /// Refresh authentication token if needed
  Future<bool> refreshToken();
}

/// Exception thrown by cloud providers
class CloudProviderException implements Exception {
  final String message;
  final String? providerName;
  final dynamic originalError;

  CloudProviderException(
    this.message, {
    this.providerName,
    this.originalError,
  });

  @override
  String toString() {
    if (providerName != null) {
      return 'CloudProviderException [$providerName]: $message';
    }
    return 'CloudProviderException: $message';
  }
}
