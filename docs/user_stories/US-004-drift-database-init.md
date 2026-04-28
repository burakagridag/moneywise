# US-004: Drift database initialised with SQLCipher encryption — initial migration

## Source
SPEC.md §4.1 (Tech Stack — Drift + sqlcipher_flutter_libs), §6 (Data Model), §13.1 (Local Data Security), §16.1 Sprint 1 checklist — "Drift DB initial migration"

## Persona
A flutter engineer who needs a working, encrypted local database with an initial schema migration so that all future data layers can build on a solid foundation.

## Story
**As** a MoneyWise developer
**I want** the Drift database initialised with SQLCipher encryption and the initial schema migration run on first launch
**So that** all stored financial data is encrypted at rest from day one, and future migrations can be added incrementally

## Acceptance Criteria

```gherkin
Scenario: Database opens successfully on first launch (iOS)
  Given the app is installed fresh on an iOS device
  When the app launches for the first time
  Then the Drift database is created and opened without error
  And no unhandled exception is thrown
  And the app proceeds to the main navigation screen

Scenario: Database opens successfully on first launch (Android)
  Given the app is installed fresh on an Android device
  When the app launches for the first time
  Then the Drift database is created and opened without error
  And the app proceeds to the main navigation screen

Scenario: Database is encrypted with SQLCipher
  Given the app has launched and the database file exists on disk
  When an engineer attempts to open the raw .db file with a standard SQLite browser (without the passphrase)
  Then the file content is unreadable — only encrypted binary data is visible
  And standard sqlite3 CLI returns "file is not a database" error

Scenario: Encryption key is stored in the device keychain
  Given the app has launched for the first time and the DB has been created
  When an engineer inspects flutter_secure_storage
  Then an encryption key entry exists for the MoneyWise app
  And the key is not stored in SharedPreferences or any plaintext file

Scenario: Initial schema migration version is 1
  Given the app has launched and the DB is open
  When the Drift schema version is queried
  Then the version is 1
  And no migration errors appear in logs

Scenario: Database file persists across app restarts
  Given the app has launched and the database was created
  When the app is closed and relaunched
  Then the existing database file is reopened (not recreated)
  And the schema version remains 1
  And no data is lost

Scenario: In-memory database works for tests
  Given a test is run using NativeDatabase.memory()
  When the Drift database is instantiated with the in-memory adapter
  Then the database opens without requiring a real file or encryption key
  And queries execute successfully
```

## Edge Cases
- [ ] Key generation failure (e.g., keychain unavailable on first launch) must surface a user-visible error rather than silently storing an unencrypted DB
- [ ] Database corruption (disk full, interrupted write) must be detected on open and offer a "restore from backup" path — log the error in Sprint 1 at minimum
- [ ] Upgrading to a new schema version (migration 1 → 2 in future sprints) must not destroy existing data — migration callbacks must be wired up correctly from the start
- [ ] Schema must define all tables referenced in SPEC.md §6 as empty stubs even if DAOs are not implemented yet (avoids migration debt)
- [ ] `flutter_secure_storage` key must use a fixed, non-random key identifier so it is retrievable across sessions
- [ ] iOS background fetch must not attempt to open the database before the keychain is unlocked (after-first-unlock entitlement)

## Test Scenarios for QA
1. Fresh install on iOS — launch app, confirm no crash, confirm DB file created in app documents directory
2. Fresh install on Android — same as above for Android data directory
3. Close and relaunch app on both platforms — confirm app starts without recreating DB
4. Attempt to open raw DB file with DB Browser for SQLite — confirm it is unreadable (encrypted)
5. Run unit test using in-memory Drift database — confirm test passes without file system or keychain dependency
6. Simulate disk-full scenario (emulator) — confirm graceful error handling, no crash

## UX Spec
N/A — no UI involved

## Estimate
M (3–4 days)

## Dependencies
- US-001 (project skeleton)
- US-007 (pubspec.yaml with drift, sqlcipher_flutter_libs, flutter_secure_storage dependencies)
