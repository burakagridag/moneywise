// Database encryption key management — data/local/encryption feature.
import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Manages the SQLCipher encryption key lifecycle.
///
/// - iOS / Android: key stored in platform Keychain / EncryptedSharedPreferences
///   via flutter_secure_storage (requires no special entitlements on those platforms).
/// - macOS: key stored as a restricted file in the app's support directory
///   (flutter_secure_storage requires keychain-access-groups entitlement + signing
///   on macOS, which is not available in unsigned debug builds).
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
    if (!kIsWeb && Platform.isMacOS) {
      return _getMacOsKey();
    }
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

  /// Returns true when a key is already stored.
  static Future<bool> hasKey() async {
    if (!kIsWeb && Platform.isMacOS) {
      final file = await _macOsKeyFile();
      return file.exists();
    }
    return (await _storage.read(key: _keyAlias)) != null;
  }

  /// Deletes the encryption key — renders the database permanently inaccessible.
  /// Only call as part of a deliberate "Reset All Data" flow.
  static Future<void> deleteKey() async {
    if (!kIsWeb && Platform.isMacOS) {
      final file = await _macOsKeyFile();
      if (await file.exists()) await file.delete();
      return;
    }
    return _storage.delete(key: _keyAlias);
  }

  // ---------------------------------------------------------------------------
  // macOS file-based key storage
  // ---------------------------------------------------------------------------

  static Future<File> _macOsKeyFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/.moneywise_db_key');
  }

  static Future<String> _getMacOsKey() async {
    final file = await _macOsKeyFile();
    if (await file.exists()) {
      return (await file.readAsString()).trim();
    }
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await file.writeAsString(hex);
    return hex;
  }
}
