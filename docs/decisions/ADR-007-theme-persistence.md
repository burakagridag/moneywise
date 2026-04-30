# ADR-007: Theme Mode Persistence via shared_preferences

## Status
Accepted — 2026-04-30

## Context
Sprint 5 shipped an `AppThemeModeNotifier` that toggles ThemeMode in memory only.
On app restart the choice is lost — the app always opens in dark mode.

Sprint 6 requires Light / Dark / System selection that survives restarts. The same
persistence layer will also store currency code and language code, which the new
Settings screen exposes.

Options considered:

1. **shared_preferences** — NSUserDefaults / SharedPreferences backed key/value.
   Simple, well-maintained by the Flutter team, no native setup.

2. **flutter_secure_storage** (already in project) — encrypts values in Keychain /
   EncryptedSharedPreferences. Overkill for non-sensitive UI preferences; would couple
   unrelated concerns to the security subsystem.

3. **Drift AppPreferences table** — store preferences as key/value rows in the
   encrypted SQLite database. Heavyweight; requires a new schema migration for a
   single string value.

4. **Custom file I/O** — write raw JSON to app-support directory. Re-implements what
   shared_preferences already provides.

## Decision
Add **`shared_preferences ^2.3.x`** and implement a single
`AppPreferencesNotifier` (`AsyncNotifier<AppPreferences>`) that loads all
UI preferences at startup and exposes typed mutators.

`MaterialApp` in `main.dart` watches `appPreferencesProvider` and passes
`appPreferences.themeMode` to `MaterialApp.themeMode`. The existing
`AppThemeModeNotifier` in `theme_mode_provider.dart` is deleted.

Provider location:
`lib/features/more/presentation/providers/app_preferences_provider.dart`

## Consequences

### Positive
- Theme / currency / language choices survive restart.
- Single provider is the source of truth for all persistent UI preferences.
- Unit-testable via `SharedPreferences.setMockInitialValues`.
- No native entitlement or setup required.

### Negative
- New dependency must be added to pubspec.yaml.
- `AppThemeModeNotifier` (Sprint 5 artefact) must be deleted; any widgets watching
  it must migrate to `appPreferencesProvider`.
- MaterialApp gains an async dependency; a zero-frame splash/loading guard is needed
  until preferences are hydrated (typically <50 ms on device).

## Alternatives Rejected
- **flutter_secure_storage**: encrypting theme preference adds no security value.
- **Drift table**: schema migration overhead; database open is slower than prefs read.
- **Custom file I/O**: reimplements shared_preferences with no benefit.

## References
- shared_preferences: https://pub.dev/packages/shared_preferences
- Existing provider to replace: `lib/features/more/presentation/providers/theme_mode_provider.dart`
