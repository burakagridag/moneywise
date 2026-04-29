// Unit tests for DbEncryptionService — data/local/encryption feature.
// Uses a fake in-memory FlutterSecureStorage to avoid platform-channel calls.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/encryption/db_encryption_service.dart';

// ---------------------------------------------------------------------------
// Fake in-memory implementation of FlutterSecureStorage
// ---------------------------------------------------------------------------

/// Replaces the real platform-channel-backed storage with an in-memory map.
/// We swap it in via FlutterSecureStorage.setMockInitialValues before each test.

void main() {
  setUp(() {
    // Reset the mock storage before every test for isolation.
    FlutterSecureStorage.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // getEncryptionKey
  // ---------------------------------------------------------------------------

  group('DbEncryptionService.getEncryptionKey', () {
    test('generates a 64-character hex key on first call', () async {
      final key = await DbEncryptionService.getEncryptionKey();
      // 32 raw bytes → 64 hex characters
      expect(key.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(key), isTrue);
    });

    test('returns the same key on subsequent calls (key is persisted)',
        () async {
      final key1 = await DbEncryptionService.getEncryptionKey();
      final key2 = await DbEncryptionService.getEncryptionKey();
      expect(key1, equals(key2));
    });

    test('returns different keys for independent storage sessions', () async {
      final key1 = await DbEncryptionService.getEncryptionKey();
      // Reset storage → simulates fresh install
      FlutterSecureStorage.setMockInitialValues({});
      final key2 = await DbEncryptionService.getEncryptionKey();
      // With overwhelming probability two random 32-byte keys differ.
      expect(key1, isNot(equals(key2)));
    });
  });

  // ---------------------------------------------------------------------------
  // hasKey
  // ---------------------------------------------------------------------------

  group('DbEncryptionService.hasKey', () {
    test('returns false when no key has been stored', () async {
      final result = await DbEncryptionService.hasKey();
      expect(result, isFalse);
    });

    test('returns true after getEncryptionKey is called', () async {
      await DbEncryptionService.getEncryptionKey();
      final result = await DbEncryptionService.hasKey();
      expect(result, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteKey
  // ---------------------------------------------------------------------------

  group('DbEncryptionService.deleteKey', () {
    test('hasKey returns false after deleteKey', () async {
      await DbEncryptionService.getEncryptionKey();
      expect(await DbEncryptionService.hasKey(), isTrue);

      await DbEncryptionService.deleteKey();
      expect(await DbEncryptionService.hasKey(), isFalse);
    });

    test('getEncryptionKey generates a new key after deleteKey', () async {
      final key1 = await DbEncryptionService.getEncryptionKey();
      await DbEncryptionService.deleteKey();
      final key2 = await DbEncryptionService.getEncryptionKey();
      // New random key must differ from the old one (with overwhelming probability).
      expect(key1, isNot(equals(key2)));
    });
  });
}
