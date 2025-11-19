import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import '../core/logger_service.dart';

/// Authentication service to manage the global password
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  static const String _passwordHashKey = 'password_hash';
  static const String _passwordSaltKey = 'password_salt';
  static const String _isPasswordSetKey = 'is_password_set';

  bool _isAuthenticated = false;
  bool _isPanicLocked = false;

  /// Check if a password has been configured
  Future<bool> isPasswordSet() async {
    final isSet = await _storage.read(key: _isPasswordSetKey);
    return isSet == 'true';
  }

  /// Check if the user is currently authenticated
  bool get isAuthenticated => _isAuthenticated;

  /// Check if the app is in panic lock mode
  bool get isPanicLocked => _isPanicLocked;

  /// Activate panic lock mode
  void activatePanicLock() {
    _isPanicLocked = true;
    _isAuthenticated = false;
  }

  /// Deactivate panic lock mode after password verification
  Future<bool> unlockFromPanic(String password) async {
    final isValid = await verifyPassword(password);
    if (isValid) {
      _isPanicLocked = false;
      _isAuthenticated = true;
      return true;
    }
    return false;
  }

  /// Set up a new password
  Future<bool> setPassword(String password) async {
    try {
      // Validate the password
      if (password.length < 6) {
        throw Exception('Password must contain at least 6 characters');
      }

      // Generate a random salt
      final salt = _generateSalt();

      // Derive the key with PBKDF2
      final hash = _deriveKey(password, salt);

      // Store the hash and salt
      await _storage.write(key: _passwordHashKey, value: base64.encode(hash));
      await _storage.write(key: _passwordSaltKey, value: base64.encode(salt));
      await _storage.write(key: _isPasswordSetKey, value: 'true');

      _isAuthenticated = true;
      return true;
    } catch (e) {
      AppLogger.error('Error setting up password', e);
      return false;
    }
  }

  /// Verify the password
  Future<bool> verifyPassword(String password) async {
    try {
      // Retrieve the stored hash and salt
      final storedHashStr = await _storage.read(key: _passwordHashKey);
      final storedSaltStr = await _storage.read(key: _passwordSaltKey);

      if (storedHashStr == null || storedSaltStr == null) {
        return false;
      }

      final storedHash = base64.decode(storedHashStr);
      final storedSalt = base64.decode(storedSaltStr);

      // Derive the key with the same salt
      final derivedHash = _deriveKey(password, storedSalt);

      // Compare the hashes
      if (_compareBytes(storedHash, derivedHash)) {
        _isAuthenticated = true;
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.error('Error verifying password', e);
      return false;
    }
  }

  /// Change the password (requires the old password)
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    // Verify the old password
    if (!await verifyPassword(oldPassword)) {
      return false;
    }

    // Set up the new password
    return await setPassword(newPassword);
  }

  /// Log out the user
  void logout() {
    _isAuthenticated = false;
    _isPanicLocked = false;
  }

  /// Reset the password (deletes all data)
  Future<void> resetPassword() async {
    await _storage.delete(key: _passwordHashKey);
    await _storage.delete(key: _passwordSaltKey);
    await _storage.delete(key: _isPasswordSetKey);
    _isAuthenticated = false;
  }

  /// Generate a random 32-byte salt
  Uint8List _generateSalt() {
    final random = FortunaRandom();
    final seed = List<int>.generate(
      32,
      (_) => DateTime.now().millisecondsSinceEpoch % 256,
    );
    random.seed(KeyParameter(Uint8List.fromList(seed)));

    final salt = Uint8List(32);
    for (int i = 0; i < salt.length; i++) {
      salt[i] = random.nextUint8();
    }
    return salt;
  }

  /// Derive a key from the password with PBKDF2
  Uint8List _deriveKey(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 10000, 32)); // 10000 iterations, 32 bytes

    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Compare two byte arrays securely (constant-time)
  bool _compareBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Get a derived key from the password for encryption
  /// (used to add an additional layer of protection)
  Future<Uint8List?> getDerivedKey(String password) async {
    try {
      final storedSaltStr = await _storage.read(key: _passwordSaltKey);
      if (storedSaltStr == null) return null;

      final salt = base64.decode(storedSaltStr);
      return _deriveKey(password, salt);
    } catch (e) {
      AppLogger.error('Error deriving key', e);
      return null;
    }
  }
}
