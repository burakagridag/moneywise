// Unit tests for DbEncryptionService — data/local/encryption feature.
// Uses a fake in-memory FlutterSecureStorage to avoid platform-channel calls.
// On macOS the service uses path_provider; we swap in a temp-dir mock.
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/encryption/db_encryption_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ---------------------------------------------------------------------------
// Fake PathProviderPlatform — returns a temp directory for all path types.
// ---------------------------------------------------------------------------

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  _FakePathProvider(this.tempPath);

  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getTemporaryPath() async => tempPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationCachePath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('moneywise_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    // Reset the mock storage before every test for isolation.
    FlutterSecureStorage.setMockInitialValues({});
    // Remove any persisted macOS key file so tests start clean.
    final keyFile = File('${tempDir.path}/.moneywise_db_key');
    if (await keyFile.exists()) await keyFile.delete();
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
      // Reset storage → simulates fresh install (wipe both storage backends).
      FlutterSecureStorage.setMockInitialValues({});
      final keyFile = File('${tempDir.path}/.moneywise_db_key');
      if (await keyFile.exists()) await keyFile.delete();
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
