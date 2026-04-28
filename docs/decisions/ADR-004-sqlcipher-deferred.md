# ADR-004: Defer SQLCipher Encryption to Sprint 3

## Status
Accepted — 2026-04-28

## Context
ADR-002 specified SQLCipher as the encryption layer for the Drift SQLite database.
Sprint 1 included a TODO comment to add encryption in Sprint 2.

During Sprint 2 implementation the following facts were established:
- `sqlcipher_flutter_libs` has been added to `pubspec.yaml` and resolves correctly.
- Enabling SQLCipher requires replacing `NativeDatabase` with a cipher-aware
  executor that accepts an encryption key derived from a user passphrase or a
  hardware-backed secure storage value.
- A migration path is needed to transparently upgrade existing unencrypted
  databases to encrypted ones (e.g. first-launch detection + `ATTACH / PRAGMA key`).
- Sprint 2 scope is already large (3 tables, 2 DAOs, 2 repositories, 3 screens,
  full i18n, 28 seed categories, unit + widget tests). Adding encryption would
  risk destabilising the sprint.

## Decision
Defer SQLCipher key setup and migration to Sprint 3.

Sprint 2 ships with:
- `sqlcipher_flutter_libs: ^0.5.4` added to `pubspec.yaml` (binary linkage ready).
- `NativeDatabase.createInBackground` retained for now.
- A code comment in `database.dart` explaining the deferral and noting that
  Sprint 3 will add the key derivation step.

Sprint 3 will implement:
1. Secure key storage via `flutter_secure_storage`.
2. First-launch detection: if the DB file exists and is unencrypted, re-key it.
3. Replace `NativeDatabase` with a `QueryExecutor` that opens the cipher DB with
   `PRAGMA key = '...'` before any other statement.
4. CI test using an in-memory (non-encrypted) executor — no change needed there.

## Consequences

### Positive
- Sprint 2 ships on time with a stable data layer.
- SQLCipher binary is already linked; Sprint 3 only adds Dart-level key management.
- Test infrastructure (in-memory `NativeDatabase`) is unaffected.

### Negative
- Data at rest is unencrypted in Sprint 2 builds distributed to internal testers.
- The TODO-to-real-code gap spans two sprints, which requires clear documentation
  (this ADR).

## Alternatives Rejected
- **Implement SQLCipher in Sprint 2**: Increases sprint scope significantly; risk
  of shipping a broken DB migration to testers.
- **Use SharedPreferences for a simple key**: Not suitable — too low entropy and
  not hardware-backed.

## References
- ADR-002: Local database decision (Drift + SQLCipher intent)
- `lib/data/local/database.dart` — deferred TODO comment
- sqlcipher_flutter_libs: https://pub.dev/packages/sqlcipher_flutter_libs
