# ADR-006: SQLCipher Activation — Key Derivation and Upgrade Migration

## Status
Accepted — 2026-04-29

## Context
ADR-004 deferred SQLCipher activation to Sprint 3. The binary (`sqlcipher_flutter_libs`)
was linked in Sprint 2 but the Dart-level key management was not implemented.
Sprint 3 must:

1. Replace `sqlite3_flutter_libs` with `sqlcipher_flutter_libs` as the sole SQLite
   provider.
2. Generate and store an encryption key in hardware-backed secure storage on first
   launch.
3. Migrate existing Sprint 2 unencrypted databases to encrypted in place.
4. Ensure CI and in-memory tests are not broken.

The user story is US-017. The implementation must satisfy all acceptance criteria
in `docs/user_stories/sprint-03-transactions-stats-sqlcipher.md`.

---

## Decision

### 1. Dependency Change — pubspec.yaml

Remove `sqlite3_flutter_libs` and add `sqlcipher_flutter_libs` and
`flutter_secure_storage`:

```yaml
# Remove:
#   sqlite3_flutter_libs: ^0.5.24

# Add:
  sqlcipher_flutter_libs: ^0.5.4
  flutter_secure_storage: ^9.2.2
```

`sqlcipher_flutter_libs` ships its own SQLite amalgamation with the SQLCipher
patch applied. Having both packages linked simultaneously causes duplicate symbol
linker errors on iOS and Android. `sqlite3_flutter_libs` must be removed entirely
before `sqlcipher_flutter_libs` is enabled.

The `drift` package talks to SQLite via the `sqlite3` Dart package, which auto-detects
the native library provided by whichever `*_flutter_libs` package is linked.
No changes are needed to any `import` or `drift` API call.

**Platform minimum versions (unchanged from Sprint 2):**
- Android `minSdkVersion 21` — satisfies `flutter_secure_storage` requirement of ≥ 18.
- iOS deployment target 13.0 — satisfies Keychain API availability.

---

### 2. Key Derivation — Random 32-Byte Key via flutter_secure_storage

A random 32-byte key is generated once using Dart's `dart:math` `Random.secure()`
and stored as a base64 string in `flutter_secure_storage` under a fixed key identifier.

```
Secure storage key identifier: "moneywise_db_encryption_key"
```

Key lifecycle:

```
App launch
  └─ flutter_secure_storage.read("moneywise_db_encryption_key")
       ├─ null (first launch or key wiped)
       │    └─ generate 32 random bytes via Random.secure()
       │    └─ base64-encode
       │    └─ flutter_secure_storage.write(key: "moneywise_db_encryption_key", value: encoded)
       │    └─ use value to open/create DB
       └─ non-null (subsequent launches)
            └─ use stored value to open DB
```

The key is passed to Drift's cipher executor as the SQLCipher `PRAGMA key` value.
It is never written to `SharedPreferences`, the app bundle, or any file outside
the OS secure enclave.

**flutter_secure_storage platform configuration:**

| Platform | Storage backend |
|----------|----------------|
| iOS | Keychain Services — `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |
| Android | Android Keystore + EncryptedSharedPreferences |

The `FlutterSecureStorage` instance is configured with:

```dart
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device),
);
```

**Fallback — secure storage unavailable:**
If `flutter_secure_storage.read` throws (e.g. device lacks secure hardware),
the service catches the exception, logs a warning to the console, and derives a
best-effort key using `package:crypto` HMAC-SHA256 of
`"moneywise" + Platform.operatingSystemVersion`. This ensures the DB is never left
unencrypted even on degraded hardware. The fallback is logged to Crashlytics
(Phase 2+ analytics) and surfaced as a warning-level diagnostic in the More tab.

**Key retrieval failure on subsequent launch (e.g. iOS Keychain wiped after factory reset):**
The `_openConnection()` function catches the SQLCipher "file is not a database"
exception (indicating wrong key) and redirects to a `DataRecoveryScreen` with the
copy: "We could not decrypt your financial data. You can reset the app to start fresh."
No automatic data recovery is attempted. This screen offers a single CTA: "Reset App",
which deletes the database file and triggers a fresh launch.

---

### 3. Cipher Executor — Replacing NativeDatabase

`lib/data/local/database.dart` replaces `NativeDatabase.createInBackground` with a
cipher-aware executor using `drift/native.dart`'s `NativeDatabase` with a setup
callback that executes `PRAGMA key` before the connection is used:

```dart
// Simplified — actual file: lib/data/local/cipher_executor.dart
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

QueryExecutor buildCipherExecutor(File dbFile, String hexKey) {
  return NativeDatabase.createInBackground(
    dbFile,
    setup: (rawDb) {
      rawDb.execute("PRAGMA key = \"x'$hexKey'\";");
    },
  );
}
```

The key is passed as a hex blob (`x'...'` SQLCipher syntax) rather than a raw
passphrase, which bypasses SQLCipher's PBKDF2 derivation loop and reduces
open-time latency to < 1 ms.

The `hexKey` is derived from the base64-stored random bytes by decoding them back
to a `Uint8List` and hex-encoding via `package:convert`.

**Test builds:** The `AppDatabase.forTesting(QueryExecutor e)` constructor that
accepts a pre-built executor (introduced in Sprint 2) is unchanged. All test files
pass `NativeDatabase.memory()` — a plain, non-encrypted in-memory database — and
are unaffected by this change.

---

### 4. Upgrade Migration — Unencrypted to Encrypted

This migration is distinct from the Drift schema migration (ADR-005 §4). It operates
at the SQLite file level before Drift opens the database.

**Detection:** SQLCipher can open an unencrypted SQLite file but returns garbage
data when a `PRAGMA key` is applied to a file that was not previously encrypted.
The detection strategy uses a PRAGMA probe:

```dart
Future<bool> _isDatabaseUnencrypted(File dbFile) async {
  // Open WITHOUT a key via raw sqlite3 package.
  try {
    final db = sqlite3.open(dbFile.path);
    db.execute('SELECT count(*) FROM sqlite_master;'); // succeeds on plaintext
    db.dispose();
    return true;
  } catch (_) {
    return false; // already encrypted or corrupted
  }
}
```

**Re-key procedure (SQLCipher ATTACH + sqlcipher_export):**

SQLCipher's recommended in-place encryption of an existing plaintext database uses
`ATTACH` with a key and `sqlcipher_export`:

```sql
-- Open the existing plaintext DB (no PRAGMA key).
ATTACH DATABASE 'path/to/moneywise_encrypted.db' AS encrypted KEY "x'<hexKey>'";
SELECT sqlcipher_export('encrypted');
DETACH DATABASE encrypted;
```

After this completes:
1. Rename `moneywise_encrypted.db` → `moneywise.db` (atomic rename on POSIX).
2. Delete the old plaintext file.
3. The subsequent Drift open uses the cipher executor with the stored key.

**Progress indicator:** A full-screen overlay reading "Securing your data…" is shown
using a `SplashScreen` variant while re-keying runs on an `Isolate`. This prevents
the UI thread from blocking and avoids an ANR on Android.

**Re-key failure recovery:**
If the rename step fails (e.g. app killed mid-rekey), the next launch finds:
- `moneywise_encrypted.db` exists → rekey was partial → delete encrypted file, retry.
- `moneywise.db` is not openable with the stored key AND the plaintext probe fails
  → DB is corrupted → show `DataRecoveryScreen`.

The implementation in `lib/data/local/cipher_migration_service.dart` encodes this
state machine explicitly using an `enum CipherMigrationState`.

---

### 5. CI Environment

The GitHub Actions workflow runs `flutter test` against in-memory `NativeDatabase`
instances provided by `AppDatabase.forTesting(NativeDatabase.memory())`. These
tests use the plain `sqlite3` native library bundled by the test runner — they do
not exercise the cipher executor and do not require `sqlcipher_flutter_libs` to be
installed on the CI runner.

No changes to `.github/workflows/` are required.

If a test specifically needs to verify cipher behaviour, it must spin up a
temporary real file-based encrypted DB in a `setUpAll` block, using
`NativeDatabase` with a hardcoded test key. Such tests are tagged `@Tags(['cipher'])`
and excluded from the default `flutter test` run to keep CI fast.

---

## Consequences

### Positive
- All user data at rest is protected by AES-256 (SQLCipher default cipher suite).
- Key is hardware-backed on both iOS (Keychain) and Android (Keystore).
- Upgrade migration is transparent to the user (one-time "Securing your data" screen).
- Test infrastructure requires no changes.

### Negative
- `sqlcipher_flutter_libs` increases the native binary size by ~600 KB (vs vanilla SQLite).
- Re-key of a large database (10 000+ rows) can take 2–5 seconds; a progress indicator
  is mandatory to prevent perceived hangs.
- Key loss (Keychain wipe on factory reset) leads to irrecoverable data loss. The
  `DataRecoveryScreen` makes this explicit and consent-gated.
- macOS debug builds may require entitlement changes for Keychain access; if macOS
  is used as a development target, test with plain `NativeDatabase.memory()` only.

## Alternatives Rejected

- **Store key in SharedPreferences:** Not hardware-backed; key is readable by any
  process on a rooted device. Rejected per US-017 acceptance criteria.
- **User-supplied passphrase as key:** Requires a UI screen for passphrase entry;
  out of scope for Phase 1. Passphrase-based unlock is a Phase 2 feature.
- **Encrypt only the backup file:** Leaves the live database unencrypted; does not
  satisfy "data at rest" protection requirements.
- **Keep sqlite3_flutter_libs and link sqlcipher_flutter_libs alongside:** Causes
  duplicate symbol errors at link time. Only one SQLite binary is permitted.

## References
- ADR-004: SQLCipher deferred to Sprint 3
- ADR-002: Local database (Drift + SQLCipher intent)
- US-017: Activate SQLCipher database encryption
- sqlcipher_flutter_libs: https://pub.dev/packages/sqlcipher_flutter_libs
- flutter_secure_storage: https://pub.dev/packages/flutter_secure_storage
- SQLCipher documentation: https://www.zetetic.net/sqlcipher/sqlcipher-api/
- SPEC.md §6 (data model), §7.1 (balance formula)
