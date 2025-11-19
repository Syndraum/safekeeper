import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import '../core/logger_service.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _storage = const FlutterSecureStorage();
  static const String _rsaPrivateKeyKey = 'rsa_private_key';
  static const String _rsaPublicKeyKey = 'rsa_public_key';

  RSAPrivateKey? _privateKey;
  RSAPublicKey? _publicKey;

  /// Initialize the encryption service - generates RSA keys if not present
  Future<void> initialize() async {
    await _loadOrGenerateRSAKeys();
  }

  bool _isEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Load existing RSA keys or generate new ones
  Future<void> _loadOrGenerateRSAKeys() async {
    try {
      // Try to load existing keys
      String? privateKeyStr = await _storage.read(key: _rsaPrivateKeyKey);
      String? publicKeyStr = await _storage.read(key: _rsaPublicKeyKey);

      if (privateKeyStr != null && publicKeyStr != null) {
        _privateKey = _deserializePrivateKey(privateKeyStr);
        _publicKey = _deserializePublicKey(publicKeyStr);
        AppLogger.info('RSA keys loaded from storage');
      } else {
        // Generate new keys
        await _generateAndStoreRSAKeys();
        AppLogger.info('New RSA keys generated and stored');
      }
    } catch (e) {
      AppLogger.error('Error loading RSA keys', e);
      // If there's an error, generate new keys
      await _generateAndStoreRSAKeys();
    }
  }

  /// Generate new RSA key pair and store securely
  Future<void> _generateAndStoreRSAKeys() async {
    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
          _getSecureRandom(),
        ),
      );

    final pair = keyGen.generateKeyPair();
    _privateKey = pair.privateKey as RSAPrivateKey;
    _publicKey = pair.publicKey as RSAPublicKey;

    // Serialize and store keys
    String privateKeyStr = _serializePrivateKey(_privateKey!);
    String publicKeyStr = _serializePublicKey(_publicKey!);

    await _storage.write(key: _rsaPrivateKeyKey, value: privateKeyStr);
    await _storage.write(key: _rsaPublicKeyKey, value: publicKeyStr);
  }

  /// Serialize private key to JSON string
  String _serializePrivateKey(RSAPrivateKey key) {
    final map = {
      'modulus': key.n.toString(),
      'privateExponent': key.privateExponent.toString(),
      'p': key.p.toString(),
      'q': key.q.toString(),
    };
    return json.encode(map);
  }

  /// Deserialize private key from JSON string
  RSAPrivateKey _deserializePrivateKey(String keyStr) {
    final map = json.decode(keyStr) as Map<String, dynamic>;
    return RSAPrivateKey(
      BigInt.parse(map['modulus']),
      BigInt.parse(map['privateExponent']),
      BigInt.parse(map['p']),
      BigInt.parse(map['q']),
    );
  }

  /// Serialize public key to JSON string
  String _serializePublicKey(RSAPublicKey key) {
    final map = {
      'modulus': key.modulus.toString(),
      'exponent': key.exponent.toString(),
    };
    return json.encode(map);
  }

  /// Deserialize public key from JSON string
  RSAPublicKey _deserializePublicKey(String keyStr) {
    final map = json.decode(keyStr) as Map<String, dynamic>;
    return RSAPublicKey(
      BigInt.parse(map['modulus']),
      BigInt.parse(map['exponent']),
    );
  }

  /// Get secure random number generator
  SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  /// Hybrid encryption: Encrypt file with AES, then encrypt AES key with RSA
  Future<HybridEncryptionResult> encryptFile(Uint8List fileBytes) async {
    if (_publicKey == null) {
      throw Exception('RSA keys not initialized. Call initialize() first.');
    }

    // Generate a random AES key for this file
    final aesKey = encrypt.Key.fromSecureRandom(32); // 256-bit key
    final iv = encrypt.IV.fromLength(16);

    // Encrypt file with AES
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey));
    final encryptedFile = encrypter.encryptBytes(fileBytes, iv: iv);

    // Encrypt the AES key with RSA
    final encryptedAesKey = _rsaEncrypt(aesKey.bytes, _publicKey!);

    // Calculer le HMAC des données chiffrées
    final hmac = Hmac(sha256, aesKey.bytes);
    final hmacBytes = Uint8List.fromList(
      hmac.convert(encryptedFile.bytes).bytes,
    );

    return HybridEncryptionResult(
      encryptedData: encryptedFile.bytes,
      encryptedKey: encryptedAesKey,
      iv: iv.bytes,
      hmac: hmacBytes,
    );
  }

  /// Hybrid decryption: Decrypt AES key with RSA, then decrypt file with AES
  Future<Uint8List> decryptFile(
    Uint8List encryptedData,
    Uint8List encryptedKey,
    Uint8List iv,
    Uint8List? hmac,
  ) async {
    if (_privateKey == null) {
      throw Exception('RSA keys not initialized. Call initialize() first.');
    }

    // Decrypt the AES key with RSA
    final aesKeyBytes = _rsaDecrypt(encryptedKey, _privateKey!);
    final aesKey = encrypt.Key(Uint8List.fromList(aesKeyBytes));
    final ivObj = encrypt.IV(Uint8List.fromList(iv));
    if (hmac != null) {
      final hmacCheck = Hmac(sha256, aesKey.bytes);
      final calculatedHmac = hmacCheck.convert(encryptedData).bytes;
      if (!_isEqual(hmac, Uint8List.fromList(calculatedHmac))) {
        throw Exception('HMAC verification failed - data may be corrupted');
      }
    }

    // Decrypt file with AES
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey));
    final encrypted = encrypt.Encrypted(Uint8List.fromList(encryptedData));
    final decryptedBytes = encrypter.decryptBytes(encrypted, iv: ivObj);

    return Uint8List.fromList(decryptedBytes);
  }

  /// RSA encryption using OAEP padding
  Uint8List _rsaEncrypt(Uint8List data, RSAPublicKey publicKey) {
    final encryptor = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    return _processInBlocks(encryptor, data);
  }

  /// RSA decryption using OAEP padding
  Uint8List _rsaDecrypt(Uint8List data, RSAPrivateKey privateKey) {
    final decryptor = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    return _processInBlocks(decryptor, data);
  }

  /// Process data in blocks for RSA (due to size limitations)
  Uint8List _processInBlocks(AsymmetricBlockCipher cipher, Uint8List data) {
    final numBlocks = (data.length / cipher.inputBlockSize).ceil();
    final output = <int>[];

    for (var i = 0; i < numBlocks; i++) {
      final start = i * cipher.inputBlockSize;
      final end = (start + cipher.inputBlockSize < data.length)
          ? start + cipher.inputBlockSize
          : data.length;
      final block = data.sublist(start, end);
      final processed = cipher.process(block);
      output.addAll(processed);
    }

    return Uint8List.fromList(output);
  }

  /// Get public key for export/sharing (if needed)
  String? getPublicKeyString() {
    if (_publicKey == null) return null;
    return _serializePublicKey(_publicKey!);
  }

  /// Check if keys are initialized
  bool get isInitialized => _privateKey != null && _publicKey != null;
}

/// Result of hybrid encryption
class HybridEncryptionResult {
  final Uint8List encryptedData;
  final Uint8List encryptedKey;
  final Uint8List iv;
  final Uint8List? hmac;

  HybridEncryptionResult({
    required this.encryptedData,
    required this.encryptedKey,
    required this.iv,
    this.hmac,
  });

  /// Convert to base64 strings for storage
  Map<String, String> toBase64Map() {
    return {
      'encryptedData': base64.encode(encryptedData),
      'encryptedKey': base64.encode(encryptedKey),
      'iv': base64.encode(iv),
      if (hmac != null) 'hmac': base64.encode(hmac!),
    };
  }

  /// Create from base64 strings
  factory HybridEncryptionResult.fromBase64Map(Map<String, String> map) {
    return HybridEncryptionResult(
      encryptedData: base64.decode(map['encryptedData']!),
      encryptedKey: base64.decode(map['encryptedKey']!),
      iv: base64.decode(map['iv']!),
      hmac: map['hmac'] != null ? base64.decode(map['hmac']!) : null,
    );
  }
}
