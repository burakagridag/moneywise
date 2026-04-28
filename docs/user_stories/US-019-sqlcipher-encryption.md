# US-019: SQLCipher encryption — wire up sqlcipher_flutter_libs to replace NativeDatabase

## Persona
A MoneyWise user who stores sensitive personal financial data locally and expects that data to
be unreadable if their device is accessed without authorisation.

## Story
**As** a MoneyWise user
**I want** the local SQLite database to be encrypted at rest using SQLCipher
**So that** my financial records cannot be read by other apps, forensic tools, or anyone who
obtains a physical copy of the device storage

## Source
SPEC.md §4.1 (sqlcipher_flutter_libs — "Hassas finans verisi şifrelenmeli");
ADR-003 (2026-04-28) — SQLCipher deferred from Sprint 1, due in Sprint 2;
Sprint 2 goal — Account & Category Management.

## RISK RATING: HIGHEST RISK STORY IN SPRINT 2

SQLCipher requires native build configuration on both iOS (CocoaPods, replacing the default
SQLite) and Android (Gradle, replacing the default SQLite). Any misconfiguration silently
falls back to an unencrypted database or causes a build failure. The flutter-engineer must
spike this on Day 1 of Sprint 2 and escalate to the Orchestrator within 4 hours if unresolved.

## Story
**As** a MoneyWise developer
**I want** the Drift database to open via `NativeDatabase.createInBackground` backed by
`sqlcipher_flutter_libs` with a per-installation derived passphrase
**So that** all database files on the device are encrypted at rest with AES-256

## Acceptance Criteria

```gherkin
Scenario: Database file is encrypted on first launch
  Given the app is installed fresh
  When the app launches and the database initialises
  Then the raw .db file on device storage is NOT readable by the sqlite3 CLI without a passphrase
  And opening it with the correct passphrase returns the expected schema tables

Scenario: Database opens successfully on subsequent launches
  Given the encrypted database exists with the Sprint 2 schema
  When the app is killed and relaunched
  Then the database opens without error
  And all seeded data (account groups, categories) is accessible

Scenario: Passphrase is derived per-installation and stored securely
  Given the app is installed
  When the passphrase is generated on first launch
  Then it is stored in the platform secure storage
    (iOS: Keychain, Android: EncryptedSharedPreferences or Keystore-backed)
  And it is NOT stored in plain text in SharedPreferences or on disk

Scenario: Existing unencrypted Sprint 1 database is migrated to encrypted
  Given a device that ran the Sprint 1 build (unencrypted NativeDatabase)
  When the Sprint 2 build is installed as an update
  Then the migration procedure:
    1. Opens the old unencrypted DB
    2. Re-encrypts it using sqlcipher ATTACH + EXPORT (or equivalent)
    3. Replaces the old file with the encrypted file
    4. Verifies the encrypted file opens correctly
  And user data from Sprint 1 is preserved post-migration
  And the old unencrypted file is securely deleted

Scenario: Application works identically with encrypted and unencrypted build
  Given encryption is enabled
  When the user interacts with AccountsScreen and CategoryManagementScreen
  Then no performance degradation is observable for typical data volumes
    (< 1000 rows per table in Sprint 2)
  And all CRUD operations succeed identically to the unencrypted path

Scenario: iOS build succeeds with SQLCipher Podfile configuration
  Given the Podfile specifies sqlcipher_flutter_libs
  When `pod install` is run in the ios/ directory
  Then no CocoaPods error is emitted
  And the resulting iOS build links SQLCipher instead of the OS-bundled SQLite
  And the app launches on a physical iOS device and Simulator

Scenario: Android build succeeds with SQLCipher Gradle configuration
  Given android/app/build.gradle includes sqlcipher_flutter_libs dependency
  When `flutter build apk` is run
  Then no Gradle error is emitted
  And the resulting APK links SQLCipher
  And the app launches on a physical Android device and Emulator

Scenario: flutter analyze passes with SQLCipher integration
  Given the SQLCipher Drift integration code is written
  When `flutter analyze` is run
  Then zero warnings or errors are reported
```

## Edge Cases
- [ ] Passphrase loss — if the Keychain / Keystore entry is cleared (e.g. device reset, app uninstall), the database is permanently unreadable; the migration strategy must document this and the user-facing behaviour must be a "Data not recoverable — please restore from backup" error
- [ ] Multiple processes (iOS Share Extension, Android background worker) — only one process should open the encrypted DB at a time in Sprint 2; background workers must close/re-open with same passphrase
- [ ] Device upgrade / data migration — if the passphrase is tied to a device-specific key, a new device install will open a new empty DB (not carry data); backup/restore (Sprint 8) is the correct recovery path
- [ ] SQLCipher version compatibility — `sqlcipher_flutter_libs` must match the version Drift's `drift_sqflite` integration expects; version pinning in pubspec.yaml is required
- [ ] Build time regression — SQLCipher adds native compilation time; CI must be updated with an increased timeout if needed
- [ ] File size overhead — SQLCipher adds ~10% file size overhead vs. plain SQLite; acceptable for Sprint 2
- [ ] Downgrade (rolling back to Sprint 1 unencrypted build) — not supported; encrypted DB is not readable by Sprint 1 binary; this is acceptable and must be documented in the ADR

## Test Scenarios for QA
1. Fresh install Sprint 2 on iOS: verify DB file is unreadable via `sqlite3` CLI without passphrase
2. Fresh install Sprint 2 on Android: same check using `adb pull` + sqlite3
3. Cold restart on iOS: verify DB opens and seed data is intact
4. Cold restart on Android: same check
5. iOS build: `pod install` completes without errors; `flutter build ios --no-codesign` succeeds
6. Android build: `flutter build apk --debug` succeeds; no Gradle errors
7. Upgrade from Sprint 1 build (unencrypted DB): data preserved after migration on both platforms
8. Performance: open AccountsScreen with 11 groups and 5 accounts — no visible lag (under 300ms first render)
9. flutter analyze: zero warnings after integration
10. Simulate Keychain loss (manual Keychain delete on iOS Simulator): confirm graceful "data not recoverable" error (not a crash)

## UX Spec
N/A — infrastructure story only, no UI changes visible to users.

## Estimate
M (3–4 days) — elevated from S due to native build risk on two platforms.
The flutter-engineer must spike on Day 1 of Sprint 2 and escalate within 4 hours if blocked.

## Dependencies
- US-004 (Drift DB initialised — base NativeDatabase to be replaced)
- US-011, US-012, US-013 — schema must be stable before encryption migration is tested
  end-to-end; can be developed in parallel but integration test requires all three

## ADR Required
The flutter-engineer must write ADR-004 documenting:
- Passphrase derivation and storage mechanism chosen
- Migration strategy from Sprint 1 unencrypted DB
- SQLCipher + Drift version pinning
- Fallback / recovery behaviour on passphrase loss
