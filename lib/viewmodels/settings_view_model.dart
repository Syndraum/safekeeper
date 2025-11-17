import '../core/base_view_model.dart';
import '../services/settings_service.dart';
import '../services/cloud_backup_service.dart';
import '../services/cloud_providers/google_drive_provider.dart';
import '../services/cloud_providers/dropbox_provider.dart';

class SettingsViewModel extends BaseViewModel {
  final SettingsService _settingsService;
  final CloudBackupService _backupService;
  final GoogleDriveProvider _googleDriveProvider;
  final DropboxProvider _dropboxProvider;

  bool _isBackupEnabled = false;
  bool _isAutoBackupEnabled = false;
  bool _isGoogleDriveEnabled = false;
  bool _isDropboxEnabled = false;
  bool _isGoogleDriveAuthenticated = false;
  bool _isDropboxAuthenticated = false;

  SettingsViewModel({
    required SettingsService settingsService,
    required CloudBackupService backupService,
    required GoogleDriveProvider googleDriveProvider,
    required DropboxProvider dropboxProvider,
  })  : _settingsService = settingsService,
        _backupService = backupService,
        _googleDriveProvider = googleDriveProvider,
        _dropboxProvider = dropboxProvider;

  // Getters
  bool get isBackupEnabled => _isBackupEnabled;
  bool get isAutoBackupEnabled => _isAutoBackupEnabled;
  bool get isGoogleDriveEnabled => _isGoogleDriveEnabled;
  bool get isDropboxEnabled => _isDropboxEnabled;
  bool get isGoogleDriveAuthenticated => _isGoogleDriveAuthenticated;
  bool get isDropboxAuthenticated => _isDropboxAuthenticated;
  
  List<String> get enabledProviders => _settingsService.getEnabledProviders();
  bool get hasEnabledProvider => _settingsService.hasEnabledProvider();

  /// Initialize settings
  Future<void> initialize() async {
    await runBusyFuture(
      () async {
        _isBackupEnabled = _settingsService.isBackupEnabled();
        _isAutoBackupEnabled = _settingsService.isAutoBackupEnabled();
        _isGoogleDriveEnabled = _settingsService.isGoogleDriveEnabled();
        _isDropboxEnabled = _settingsService.isDropboxEnabled();
        _isGoogleDriveAuthenticated = _settingsService.isGoogleDriveAuthenticated();
        _isDropboxAuthenticated = _settingsService.isDropboxAuthenticated();
      },
      errorMessage: 'Failed to load settings',
    );
  }

  /// Toggle backup enabled/disabled
  Future<void> toggleBackup(bool enabled) async {
    await runBusyFuture(
      () async {
        await _settingsService.setBackupEnabled(enabled);
        _isBackupEnabled = enabled;
        
        // If disabling backup, also disable auto-backup
        if (!enabled && _isAutoBackupEnabled) {
          await _settingsService.setAutoBackupEnabled(false);
          _isAutoBackupEnabled = false;
        }
      },
      errorMessage: 'Failed to update backup setting',
    );
  }

  /// Toggle auto-backup enabled/disabled
  Future<void> toggleAutoBackup(bool enabled) async {
    await runBusyFuture(
      () async {
        await _settingsService.setAutoBackupEnabled(enabled);
        _isAutoBackupEnabled = enabled;
      },
      errorMessage: 'Failed to update auto-backup setting',
    );
  }

  /// Connect to Google Drive
  Future<bool> connectGoogleDrive() async {
    final result = await runBusyFutureWithSuccess(
      () async {
        await _googleDriveProvider.authenticate();
        _isGoogleDriveAuthenticated = await _googleDriveProvider.isAuthenticated();
        
        if (_isGoogleDriveAuthenticated) {
          await _settingsService.setGoogleDriveEnabled(true);
          _isGoogleDriveEnabled = true;
        }
      },
      successMessage: 'Connected to Google Drive successfully',
      errorMessage: 'Failed to connect to Google Drive',
    );
    return result != null;
  }

  /// Disconnect from Google Drive
  Future<bool> disconnectGoogleDrive() async {
    final result = await runBusyFutureWithSuccess(
      () async {
        await _settingsService.clearGoogleDriveAuth();
        _isGoogleDriveAuthenticated = false;
        _isGoogleDriveEnabled = false;
      },
      successMessage: 'Disconnected from Google Drive',
      errorMessage: 'Failed to disconnect from Google Drive',
    );
    return result != null;
  }

  /// Connect to Dropbox
  Future<bool> connectDropbox() async {
    final result = await runBusyFutureWithSuccess(
      () async {
        await _dropboxProvider.authenticate();
        _isDropboxAuthenticated = await _dropboxProvider.isAuthenticated();
        
        if (_isDropboxAuthenticated) {
          await _settingsService.setDropboxEnabled(true);
          _isDropboxEnabled = true;
        }
      },
      successMessage: 'Connected to Dropbox successfully',
      errorMessage: 'Failed to connect to Dropbox',
    );
    return result != null;
  }

  /// Disconnect from Dropbox
  Future<bool> disconnectDropbox() async {
    final result = await runBusyFutureWithSuccess(
      () async {
        await _settingsService.clearDropboxAuth();
        _isDropboxAuthenticated = false;
        _isDropboxEnabled = false;
      },
      successMessage: 'Disconnected from Dropbox',
      errorMessage: 'Failed to disconnect from Dropbox',
    );
    return result != null;
  }

  /// Sync all documents
  Future<bool> syncAllDocuments() async {
    if (!_isBackupEnabled) {
      setError('Backup is not enabled');
      return false;
    }

    if (!hasEnabledProvider) {
      setError('No cloud provider enabled');
      return false;
    }

    final result = await runBusyFutureWithSuccess(
      () async {
        await _backupService.syncAllDocuments();
      },
      successMessage: 'All documents synced successfully',
      errorMessage: 'Failed to sync documents',
    );
    return result != null;
  }

  /// Get provider display name
  String getProviderDisplayName(String provider) {
    switch (provider) {
      case 'google_drive':
        return 'Google Drive';
      case 'dropbox':
        return 'Dropbox';
      default:
        return provider;
    }
  }
}
