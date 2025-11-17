import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings and user preferences
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // Settings keys
  static const String _keyBackupEnabled = 'backup_enabled';
  static const String _keyGoogleDriveEnabled = 'google_drive_enabled';
  static const String _keyDropboxEnabled = 'dropbox_enabled';
  static const String _keyAutoBackup = 'auto_backup';
  static const String _keyWifiOnly = 'wifi_only';
  static const String _keyGoogleDriveToken = 'google_drive_token';
  static const String _keyGoogleDriveRefreshToken = 'google_drive_refresh_token';
  static const String _keyDropboxToken = 'dropbox_token';
  static const String _keyDropboxRefreshToken = 'dropbox_refresh_token';

  /// Initialize the settings service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw Exception('SettingsService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // ========== Backup Settings ==========

  /// Check if cloud backup is enabled
  bool isBackupEnabled() {
    return _preferences.getBool(_keyBackupEnabled) ?? false;
  }

  /// Enable or disable cloud backup
  Future<void> setBackupEnabled(bool enabled) async {
    await _preferences.setBool(_keyBackupEnabled, enabled);
  }

  /// Check if auto backup is enabled (backup immediately after upload)
  bool isAutoBackupEnabled() {
    return _preferences.getBool(_keyAutoBackup) ?? true;
  }

  /// Enable or disable auto backup
  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _preferences.setBool(_keyAutoBackup, enabled);
  }

  /// Check if backup should only happen on WiFi
  bool isWifiOnlyEnabled() {
    return _preferences.getBool(_keyWifiOnly) ?? true;
  }

  /// Enable or disable WiFi-only backup
  Future<void> setWifiOnlyEnabled(bool enabled) async {
    await _preferences.setBool(_keyWifiOnly, enabled);
  }

  // ========== Google Drive Settings ==========

  /// Check if Google Drive is enabled
  bool isGoogleDriveEnabled() {
    return _preferences.getBool(_keyGoogleDriveEnabled) ?? false;
  }

  /// Enable or disable Google Drive
  Future<void> setGoogleDriveEnabled(bool enabled) async {
    await _preferences.setBool(_keyGoogleDriveEnabled, enabled);
  }

  /// Get Google Drive access token
  String? getGoogleDriveToken() {
    return _preferences.getString(_keyGoogleDriveToken);
  }

  /// Save Google Drive access token
  Future<void> setGoogleDriveToken(String? token) async {
    if (token == null) {
      await _preferences.remove(_keyGoogleDriveToken);
    } else {
      await _preferences.setString(_keyGoogleDriveToken, token);
    }
  }

  /// Get Google Drive refresh token
  String? getGoogleDriveRefreshToken() {
    return _preferences.getString(_keyGoogleDriveRefreshToken);
  }

  /// Save Google Drive refresh token
  Future<void> setGoogleDriveRefreshToken(String? token) async {
    if (token == null) {
      await _preferences.remove(_keyGoogleDriveRefreshToken);
    } else {
      await _preferences.setString(_keyGoogleDriveRefreshToken, token);
    }
  }

  /// Check if Google Drive is authenticated
  bool isGoogleDriveAuthenticated() {
    return getGoogleDriveToken() != null;
  }

  /// Clear Google Drive authentication
  Future<void> clearGoogleDriveAuth() async {
    await setGoogleDriveToken(null);
    await setGoogleDriveRefreshToken(null);
    await setGoogleDriveEnabled(false);
  }

  // ========== Dropbox Settings ==========

  /// Check if Dropbox is enabled
  bool isDropboxEnabled() {
    return _preferences.getBool(_keyDropboxEnabled) ?? false;
  }

  /// Enable or disable Dropbox
  Future<void> setDropboxEnabled(bool enabled) async {
    await _preferences.setBool(_keyDropboxEnabled, enabled);
  }

  /// Get Dropbox access token
  String? getDropboxToken() {
    return _preferences.getString(_keyDropboxToken);
  }

  /// Save Dropbox access token
  Future<void> setDropboxToken(String? token) async {
    if (token == null) {
      await _preferences.remove(_keyDropboxToken);
    } else {
      await _preferences.setString(_keyDropboxToken, token);
    }
  }

  /// Get Dropbox refresh token
  String? getDropboxRefreshToken() {
    return _preferences.getString(_keyDropboxRefreshToken);
  }

  /// Save Dropbox refresh token
  Future<void> setDropboxRefreshToken(String? token) async {
    if (token == null) {
      await _preferences.remove(_keyDropboxRefreshToken);
    } else {
      await _preferences.setString(_keyDropboxRefreshToken, token);
    }
  }

  /// Check if Dropbox is authenticated
  bool isDropboxAuthenticated() {
    return getDropboxToken() != null;
  }

  /// Clear Dropbox authentication
  Future<void> clearDropboxAuth() async {
    await setDropboxToken(null);
    await setDropboxRefreshToken(null);
    await setDropboxEnabled(false);
  }

  // ========== Helper Methods ==========

  /// Get list of enabled providers
  List<String> getEnabledProviders() {
    final providers = <String>[];
    if (isGoogleDriveEnabled() && isGoogleDriveAuthenticated()) {
      providers.add('google_drive');
    }
    if (isDropboxEnabled() && isDropboxAuthenticated()) {
      providers.add('dropbox');
    }
    return providers;
  }

  /// Check if any provider is enabled and authenticated
  bool hasEnabledProvider() {
    return getEnabledProviders().isNotEmpty;
  }

  /// Clear all settings
  Future<void> clearAllSettings() async {
    await _preferences.clear();
  }
}
