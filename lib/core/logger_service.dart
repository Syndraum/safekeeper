import 'package:flutter/foundation.dart';

/// Centralized logging service for the application
/// Automatically disables verbose logging in release mode
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  /// Log level for debug messages (only in debug mode)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🔍 [DEBUG] $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   StackTrace: $stackTrace');
      }
    }
  }

  /// Log level for informational messages
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [INFO] $message');
    }
  }

  /// Log level for warning messages
  static void warning(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('⚠️ [WARNING] $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
    }
  }

  /// Log level for error messages (logged even in release mode for critical errors)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    // Always log errors, even in release mode, but with less detail
    if (kDebugMode) {
      debugPrint('❌ [ERROR] $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   StackTrace: $stackTrace');
      }
    } else {
      // In release mode, only log the message without details
      debugPrint('[ERROR] $message');
    }
  }

  /// Log level for success messages
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ [SUCCESS] $message');
    }
  }
}
