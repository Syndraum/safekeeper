/// Enum representing the backup status of a document
enum BackupState {
  none,       // Not backed up
  pending,    // Queued for backup
  uploading,  // Currently uploading
  completed,  // Successfully backed up
  failed,     // Backup failed
}

/// Model representing backup status for a specific cloud provider
class ProviderBackupStatus {
  final String provider;
  final BackupState state;
  final String? fileId;  // Cloud file ID (Google Drive file ID or Dropbox path)
  final DateTime? lastBackupDate;
  final String? errorMessage;

  ProviderBackupStatus({
    required this.provider,
    required this.state,
    this.fileId,
    this.lastBackupDate,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'state': state.name,
      'fileId': fileId,
      'lastBackupDate': lastBackupDate?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory ProviderBackupStatus.fromJson(Map<String, dynamic> json) {
    return ProviderBackupStatus(
      provider: json['provider'],
      state: BackupState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => BackupState.none,
      ),
      fileId: json['fileId'],
      lastBackupDate: json['lastBackupDate'] != null
          ? DateTime.parse(json['lastBackupDate'])
          : null,
      errorMessage: json['errorMessage'],
    );
  }

  ProviderBackupStatus copyWith({
    String? provider,
    BackupState? state,
    String? fileId,
    DateTime? lastBackupDate,
    String? errorMessage,
  }) {
    return ProviderBackupStatus(
      provider: provider ?? this.provider,
      state: state ?? this.state,
      fileId: fileId ?? this.fileId,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Model representing complete backup status for a document across all providers
class DocumentBackupStatus {
  final int documentId;
  final Map<String, ProviderBackupStatus> providers;

  DocumentBackupStatus({
    required this.documentId,
    required this.providers,
  });

  /// Check if document is backed up to at least one provider
  bool get isBackedUp {
    return providers.values.any((status) => status.state == BackupState.completed);
  }

  /// Check if any backup is in progress
  bool get isUploading {
    return providers.values.any((status) => status.state == BackupState.uploading);
  }

  /// Check if any backup has failed
  bool get hasFailed {
    return providers.values.any((status) => status.state == BackupState.failed);
  }

  /// Get backup status for a specific provider
  ProviderBackupStatus? getProviderStatus(String provider) {
    return providers[provider];
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'providers': providers.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory DocumentBackupStatus.fromJson(Map<String, dynamic> json) {
    return DocumentBackupStatus(
      documentId: json['documentId'],
      providers: (json['providers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          ProviderBackupStatus.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}
