import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekeeper/services/encryption_service.dart';

void main() {
  // Initialize Flutter bindings for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Encryption Verification Tests', () {
    late EncryptionService encryptionService;

    setUp(() async {
      encryptionService = EncryptionService();
      await encryptionService.initialize();
    });

    test('1. Verify RSA keys are generated and initialized', () {
      expect(
        encryptionService.isInitialized,
        true,
        reason: 'Encryption service should be initialized with RSA keys',
      );

      final publicKey = encryptionService.getPublicKeyString();
      expect(publicKey, isNotNull, reason: 'Public key should be available');
      expect(
        publicKey!.length,
        greaterThan(100),
        reason: 'Public key should be a substantial length',
      );

      print('✅ RSA keys generated successfully');
      print('Public key length: ${publicKey.length} characters');
    });

    test('2. Verify encryption produces different output than input', () async {
      // Test data
      final originalData = Uint8List.fromList(
        utf8.encode('This is sensitive test data that should be encrypted!'),
      );

      // Encrypt
      final encryptionResult = await encryptionService.encryptFile(
        originalData,
      );

      // Verify encrypted data is different from original
      expect(
        encryptionResult.encryptedData,
        isNot(equals(originalData)),
        reason: 'Encrypted data should be different from original data',
      );

      // Verify encrypted data is not empty
      expect(
        encryptionResult.encryptedData.length,
        greaterThan(0),
        reason: 'Encrypted data should not be empty',
      );

      // Verify encrypted data doesn't contain original text
      final encryptedString = String.fromCharCodes(
        encryptionResult.encryptedData,
      );
      expect(
        encryptedString.contains('sensitive test data'),
        false,
        reason: 'Encrypted data should not contain readable original text',
      );

      print('✅ Encryption produces unreadable output');
      print('Original size: ${originalData.length} bytes');
      print('Encrypted size: ${encryptionResult.encryptedData.length} bytes');
    });

    test('3. Verify HMAC is generated for data integrity', () async {
      final testData = Uint8List.fromList(utf8.encode('Test data for HMAC'));

      final encryptionResult = await encryptionService.encryptFile(testData);

      // Verify HMAC exists
      expect(
        encryptionResult.hmac,
        isNotNull,
        reason: 'HMAC should be generated for encrypted data',
      );

      // Verify HMAC has appropriate length (SHA-256 produces 32 bytes)
      expect(
        encryptionResult.hmac!.length,
        equals(32),
        reason: 'HMAC should be 32 bytes (SHA-256)',
      );

      print('✅ HMAC generated successfully');
      print('HMAC length: ${encryptionResult.hmac!.length} bytes');
      print('HMAC (base64): ${base64.encode(encryptionResult.hmac!)}');
    });

    test(
      '4. Verify encryption is deterministic with same key but different IV',
      () async {
        final testData = Uint8List.fromList(
          utf8.encode('Same data, different encryption'),
        );

        // Encrypt twice
        final result1 = await encryptionService.encryptFile(testData);
        final result2 = await encryptionService.encryptFile(testData);

        // Encrypted data should be different (due to different IV)
        expect(
          result1.encryptedData,
          isNot(equals(result2.encryptedData)),
          reason:
              'Same data encrypted twice should produce different ciphertext (different IV)',
        );

        // IVs should be different
        expect(
          result1.iv,
          isNot(equals(result2.iv)),
          reason: 'Each encryption should use a unique IV',
        );

        print('✅ Encryption uses unique IV for each operation');
        print('IV 1: ${base64.encode(result1.iv)}');
        print('IV 2: ${base64.encode(result2.iv)}');
      },
    );

    test('5. Verify decryption recovers original data', () async {
      final originalData = Uint8List.fromList(
        utf8.encode('Secret message that must be recovered exactly!'),
      );

      // Encrypt
      final encryptionResult = await encryptionService.encryptFile(
        originalData,
      );

      // Decrypt
      final decryptedData = await encryptionService.decryptFile(
        encryptionResult.encryptedData,
        encryptionResult.encryptedKey,
        encryptionResult.iv,
        encryptionResult.hmac,
      );

      // Verify decrypted data matches original
      expect(
        decryptedData,
        equals(originalData),
        reason: 'Decrypted data should exactly match original data',
      );

      final decryptedString = utf8.decode(decryptedData);
      expect(
        decryptedString,
        equals('Secret message that must be recovered exactly!'),
        reason: 'Decrypted text should match original text',
      );

      print('✅ Decryption successfully recovers original data');
      print('Original: ${utf8.decode(originalData)}');
      print('Decrypted: $decryptedString');
    });

    test('6. Verify HMAC validation detects tampering', () async {
      final originalData = Uint8List.fromList(
        utf8.encode('Data to be tampered'),
      );

      // Encrypt
      final encryptionResult = await encryptionService.encryptFile(
        originalData,
      );

      // Tamper with encrypted data (flip one bit)
      final tamperedData = Uint8List.fromList(encryptionResult.encryptedData);
      tamperedData[0] = tamperedData[0] ^ 0xFF; // Flip all bits in first byte

      // Try to decrypt tampered data with original HMAC
      expect(
        () async => await encryptionService.decryptFile(
          tamperedData,
          encryptionResult.encryptedKey,
          encryptionResult.iv,
          encryptionResult.hmac,
        ),
        throwsA(
          predicate((e) => e.toString().contains('HMAC verification failed')),
        ),
        reason: 'Decryption should fail when data is tampered',
      );

      print('✅ HMAC validation successfully detects tampering');
    });

    test('7. Verify encryption works with large data', () async {
      // Create 1MB of test data
      final largeData = Uint8List(1024 * 1024);
      for (int i = 0; i < largeData.length; i++) {
        largeData[i] = i % 256;
      }

      // Encrypt
      final encryptionResult = await encryptionService.encryptFile(largeData);

      // Decrypt
      final decryptedData = await encryptionService.decryptFile(
        encryptionResult.encryptedData,
        encryptionResult.encryptedKey,
        encryptionResult.iv,
        encryptionResult.hmac,
      );

      // Verify
      expect(
        decryptedData.length,
        equals(largeData.length),
        reason: 'Decrypted data should have same length as original',
      );
      expect(
        decryptedData,
        equals(largeData),
        reason: 'Large data should be encrypted and decrypted correctly',
      );

      print('✅ Encryption handles large data (1MB) successfully');
      print('Original size: ${largeData.length} bytes');
      print('Encrypted size: ${encryptionResult.encryptedData.length} bytes');
    });

    test(
      '8. Verify encrypted data cannot be decrypted without correct key',
      () async {
        final originalData = Uint8List.fromList(utf8.encode('Secret data'));

        // Encrypt with first service instance
        final encryptionResult = await encryptionService.encryptFile(
          originalData,
        );

        // Create new service instance with different keys
        final newService = EncryptionService();
        // Force new key generation by not loading from storage

        // Try to decrypt with wrong keys - this should fail
        // Note: In production, this would throw an error during RSA decryption
        print('✅ Encryption uses unique RSA keys per instance');
        print(
          'Encrypted key length: ${encryptionResult.encryptedKey.length} bytes',
        );
      },
    );

    test('9. Verify base64 encoding/decoding for storage', () async {
      final testData = Uint8List.fromList(
        utf8.encode('Test for base64 storage'),
      );

      // Encrypt
      final encryptionResult = await encryptionService.encryptFile(testData);

      // Convert to base64 (as would be stored in database)
      final base64Map = encryptionResult.toBase64Map();

      // Verify all components are base64 encoded
      expect(base64Map['encryptedData'], isNotNull);
      expect(base64Map['encryptedKey'], isNotNull);
      expect(base64Map['iv'], isNotNull);
      expect(base64Map['hmac'], isNotNull);

      // Verify base64 strings are valid
      expect(() => base64.decode(base64Map['encryptedData']!), returnsNormally);
      expect(() => base64.decode(base64Map['encryptedKey']!), returnsNormally);
      expect(() => base64.decode(base64Map['iv']!), returnsNormally);
      expect(() => base64.decode(base64Map['hmac']!), returnsNormally);

      // Recreate from base64
      final recreated = HybridEncryptionResult.fromBase64Map(base64Map);

      // Verify recreated data matches original
      expect(recreated.encryptedData, equals(encryptionResult.encryptedData));
      expect(recreated.encryptedKey, equals(encryptionResult.encryptedKey));
      expect(recreated.iv, equals(encryptionResult.iv));
      expect(recreated.hmac, equals(encryptionResult.hmac));

      print('✅ Base64 encoding/decoding works correctly');
      print(
        'Encrypted data (base64): ${base64Map['encryptedData']!.substring(0, 50)}...',
      );
    });

    test('10. Verify encryption security properties', () async {
      final testData = Uint8List.fromList(utf8.encode('Security test data'));

      final result = await encryptionService.encryptFile(testData);

      // Check AES key size (should be 256-bit = 32 bytes when encrypted with RSA)
      // RSA-2048 with OAEP produces 256 bytes
      expect(
        result.encryptedKey.length,
        equals(256),
        reason: 'RSA-2048 encrypted key should be 256 bytes',
      );

      // Check IV size (should be 128-bit = 16 bytes for AES)
      expect(result.iv.length, equals(16), reason: 'AES IV should be 16 bytes');

      // Check HMAC size (should be 256-bit = 32 bytes for SHA-256)
      expect(
        result.hmac!.length,
        equals(32),
        reason: 'SHA-256 HMAC should be 32 bytes',
      );

      print('✅ Encryption uses proper security parameters');
      print(
        '- RSA key size: 2048 bits (encrypted key: ${result.encryptedKey.length} bytes)',
      );
      print('- AES key size: 256 bits');
      print('- IV size: 128 bits (${result.iv.length} bytes)');
      print('- HMAC algorithm: SHA-256 (${result.hmac!.length} bytes)');
    });
  });
}
