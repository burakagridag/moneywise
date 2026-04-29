// Database encryption key management — data/local/encryption feature.
import 'dart:math';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the SQLCipher encryption key lifecycle.
/// Generates a 32-byte random key on first launch and persists it in the
/// platform-native secure keystore (Keychain on iOS, EncryptedSharedPreferences
/// on Android).
class DbEncryptionService {
  DbEncryptionService._();

  static const _keyAlias = 'moneywise_db_encryption_key';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Returns the hex-encoded 64-character encryption key.
  /// Generates and persists a new key if none exists yet.
  static Future<String> getEncryptionKey() async {
    String? stored = await _storage.read(key: _keyAlias);
    if (stored == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      stored = base64Encode(bytes);
      await _storage.write(key: _keyAlias, value: stored);
    }
    final bytes = base64Decode(stored);
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Returns true when a key is already stored in the secure keystore.
  static Future<bool> hasKey() async =>
      (await _storage.read(key: _keyAlias)) != null;

  /// Deletes the encryption key — renders the database permanently inaccessible.
  /// Only call as part of a deliberate "Reset All Data" flow.
  static Future<void> deleteKey() async => _storage.delete(key: _keyAlias);
}
