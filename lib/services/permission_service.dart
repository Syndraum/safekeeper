import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app permissions and onboarding
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  SharedPreferences? _prefs;

  // Settings keys
  static const String _keyPermissionsOnboardingCompleted = 'permissions_onboarding_completed';

  /// Initialize the permission service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw Exception('PermissionService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  /// Check if permissions onboarding has been completed
  bool isPermissionsOnboardingCompleted() {
    return _preferences.getBool(_keyPermissionsOnboardingCompleted) ?? false;
  }

  /// Mark permissions onboarding as completed
  Future<void> setPermissionsOnboardingCompleted(bool completed) async {
    await _preferences.setBool(_keyPermissionsOnboardingCompleted, completed);
  }

  /// Get list of required permissions for this app
  List<Permission> getRequiredPermissions() {
    return [
      Permission.camera,
      Permission.microphone,
    ];
  }

  /// Get list of optional permissions
  List<Permission> getOptionalPermissions() {
    return [
      Permission.notification,
    ];
  }

  /// Check status of a specific permission
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return await permission.status;
  }

  /// Request a specific permission
  Future<PermissionStatus> requestPermission(Permission permission) async {
    return await permission.request();
  }

  /// Request all required permissions at once
  Future<Map<Permission, PermissionStatus>> requestRequiredPermissions() async {
    return await getRequiredPermissions().request();
  }

  /// Request all optional permissions at once
  Future<Map<Permission, PermissionStatus>> requestOptionalPermissions() async {
    return await getOptionalPermissions().request();
  }

  /// Check if all required permissions are granted
  Future<bool> areAllRequiredPermissionsGranted() async {
    final statuses = await Future.wait(
      getRequiredPermissions().map((permission) => permission.status),
    );
    return statuses.every((status) => status.isGranted);
  }

  /// Get permission display name
  String getPermissionDisplayName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.microphone:
        return 'Microphone';
      case Permission.notification:
        return 'Notifications';
      default:
        return 'Unknown Permission';
    }
  }

  /// Get permission description explaining why it's needed
  String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'To scan and photograph your important documents, as well as to record emergency videos.';
      case Permission.microphone:
        return 'To record emergency audio messages in critical situations.';
      case Permission.notification:
        return 'To alert you about cloud backups and important updates.';
      default:
        return 'This permission is necessary for the app to function.';
    }
  }

  /// Get permission icon
  IconData getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return Icons.camera_alt;
      case Permission.microphone:
        return Icons.mic;
      case Permission.notification:
        return Icons.notifications;
      default:
        return Icons.settings;
    }
  }

  /// Open app settings to manually grant permissions
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
