import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

/// Service d'authentification pour gérer le mot de passe global
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

  /// Vérifie si un mot de passe a été configuré
  Future<bool> isPasswordSet() async {
    final isSet = await _storage.read(key: _isPasswordSetKey);
    return isSet == 'true';
  }

  /// Vérifie si l'utilisateur est actuellement authentifié
  bool get isAuthenticated => _isAuthenticated;

  /// Vérifie si l'application est en mode panic lock
  bool get isPanicLocked => _isPanicLocked;

  /// Active le mode panic lock
  void activatePanicLock() {
    _isPanicLocked = true;
    _isAuthenticated = false;
  }

  /// Désactive le mode panic lock après vérification du mot de passe
  Future<bool> unlockFromPanic(String password) async {
    final isValid = await verifyPassword(password);
    if (isValid) {
      _isPanicLocked = false;
      _isAuthenticated = true;
      return true;
    }
    return false;
  }

  /// Configure un nouveau mot de passe
  Future<bool> setPassword(String password) async {
    try {
      // Valider le mot de passe
      if (password.length < 6) {
        throw Exception('Le mot de passe doit contenir au moins 6 caractères');
      }

      // Générer un salt aléatoire
      final salt = _generateSalt();

      // Dériver la clé avec PBKDF2
      final hash = _deriveKey(password, salt);

      // Stocker le hash et le salt
      await _storage.write(key: _passwordHashKey, value: base64.encode(hash));
      await _storage.write(key: _passwordSaltKey, value: base64.encode(salt));
      await _storage.write(key: _isPasswordSetKey, value: 'true');

      _isAuthenticated = true;
      return true;
    } catch (e) {
      print('Erreur lors de la configuration du mot de passe: $e');
      return false;
    }
  }

  /// Vérifie le mot de passe
  Future<bool> verifyPassword(String password) async {
    try {
      // Récupérer le hash et le salt stockés
      final storedHashStr = await _storage.read(key: _passwordHashKey);
      final storedSaltStr = await _storage.read(key: _passwordSaltKey);

      if (storedHashStr == null || storedSaltStr == null) {
        return false;
      }

      final storedHash = base64.decode(storedHashStr);
      final storedSalt = base64.decode(storedSaltStr);

      // Dériver la clé avec le même salt
      final derivedHash = _deriveKey(password, storedSalt);

      // Comparer les hash
      if (_compareBytes(storedHash, derivedHash)) {
        _isAuthenticated = true;
        return true;
      }

      return false;
    } catch (e) {
      print('Erreur lors de la vérification du mot de passe: $e');
      return false;
    }
  }

  /// Change le mot de passe (nécessite l'ancien mot de passe)
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    // Vérifier l'ancien mot de passe
    if (!await verifyPassword(oldPassword)) {
      return false;
    }

    // Configurer le nouveau mot de passe
    return await setPassword(newPassword);
  }

  /// Déconnecte l'utilisateur
  void logout() {
    _isAuthenticated = false;
    _isPanicLocked = false;
  }

  /// Réinitialise le mot de passe (supprime toutes les données)
  Future<void> resetPassword() async {
    await _storage.delete(key: _passwordHashKey);
    await _storage.delete(key: _passwordSaltKey);
    await _storage.delete(key: _isPasswordSetKey);
    _isAuthenticated = false;
  }

  /// Génère un salt aléatoire de 32 bytes
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

  /// Dérive une clé à partir du mot de passe avec PBKDF2
  Uint8List _deriveKey(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 10000, 32)); // 10000 itérations, 32 bytes

    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Compare deux tableaux de bytes de manière sécurisée (constant-time)
  bool _compareBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Obtient une clé dérivée du mot de passe pour le chiffrement
  /// (utilisé pour ajouter une couche de protection supplémentaire)
  Future<Uint8List?> getDerivedKey(String password) async {
    try {
      final storedSaltStr = await _storage.read(key: _passwordSaltKey);
      if (storedSaltStr == null) return null;

      final salt = base64.decode(storedSaltStr);
      return _deriveKey(password, salt);
    } catch (e) {
      print('Erreur lors de la dérivation de la clé: $e');
      return null;
    }
  }
}
