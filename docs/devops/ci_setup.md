# CI/CD Setup — Updated EPIC8C-01 (2026-05-08)

## Workflows

### `.github/workflows/pr_checks.yml`

Triggered on every pull request targeting `main` or `develop`.

Steps executed in order:
1. Checkout the repository
2. Set up Flutter 3.22.x (stable) with pub cache enabled
3. Restore the `~/.pub-cache` layer from cache (keyed on `pubspec.lock`)
4. `flutter pub get`
5. `dart run build_runner build --delete-conflicting-outputs` — regenerates all `freezed`, `riverpod_generator`, and `drift_dev` outputs
6. `dart format --set-exit-if-changed .` — fails if any file is not formatted
7. `flutter analyze` — fails on any warning or error
8. `flutter test --coverage` — runs the full test suite and writes `coverage/lcov.info`
9. Uploads `coverage/lcov.info` to Codecov (`fail_ci_if_error: false` so a missing token never blocks the PR)
10. Parses `coverage/lcov.info` to compute overall line coverage; fails the job if coverage is below 75%

Generated files (`*.g.dart`, `*.freezed.dart`) are NOT cached. They are always regenerated from source to prevent stale output from masking build errors.

### `.github/workflows/build_android.yml`

Triggered on every push to `develop` or `main`.

Steps executed in order:
1. Checkout the repository
2. Set up Flutter 3.22.x (stable) with pub cache enabled
3. Restore `~/.pub-cache` and Gradle wrapper/caches from cache
4. `flutter pub get`
5. `dart run build_runner build --delete-conflicting-outputs`
6. `flutter build apk --flavor dev -t lib/main_dev.dart --debug` — produces the dev-flavor debug APK
7. Uploads the APK as a GitHub Actions artifact (retained for 7 days) named `moneywise-dev-debug-<sha>`

This workflow validates that the Android toolchain and flavor configuration are intact after every merge. Signed release builds are handled by `release.yml` (see below).

### `.github/workflows/build_ios.yml` — added EPIC8C-01

Triggered on every push to `develop` or `main`. Runs on `macos-latest`.

Steps executed in order:
1. Checkout the repository
2. Set up Flutter (stable) with pub cache enabled
3. Restore `~/.pub-cache` and CocoaPods `ios/Pods` from cache (keyed on `Podfile.lock`)
4. `flutter pub get`
5. `dart run build_runner build --delete-conflicting-outputs`
6. `pod install --repo-update` in the `ios/` directory
7. `flutter build ios --flavor dev -t lib/main_dev.dart --debug --no-codesign` — validates the iOS toolchain without requiring signing credentials
8. Uploads `Runner.app` as a GitHub Actions artifact (retained for 7 days)

### `.github/workflows/release.yml` — added EPIC8C-01

Triggered on any tag matching `v*` (e.g., `v0.8c.1`, `v1.0.0`). Contains three parallel jobs:

**`release_ios`** (macOS):
1. Installs Fastlane and runs `fastlane match appstore --readonly` to pull production certificates
2. Builds signed IPA: `flutter build ipa --flavor prod -t lib/main_prod.dart --release`
3. Uploads to TestFlight via `xcrun altool`
4. Retains IPA artifact for 30 days

**`release_android`** (Ubuntu):
1. Decodes `ANDROID_KEYSTORE_BASE64` secret into `android/app/keystore.jks`
2. Builds signed AAB: `flutter build appbundle --flavor prod -t lib/main_prod.dart --release`
3. Uploads AAB to Play Internal Testing track via `r0adkll/upload-google-play@v1`
4. Cleans up keystore file (always runs, even on failure)
5. Retains AAB artifact for 30 days

**`github_release`** (Ubuntu, runs after both store uploads succeed):
1. Extracts the matching version block from `CHANGELOG.md`
2. Creates a GitHub Release with the tag and changelog excerpt

## Running Checks Locally Before Pushing

Run these commands from the repository root in the same order as CI:

```bash
# 1. Get dependencies
flutter pub get

# 2. Regenerate code
dart run build_runner build --delete-conflicting-outputs

# 3. Check formatting (use --output=none to just see diffs, or --set-exit-if-changed to mirror CI)
dart format --set-exit-if-changed .

# 4. Static analysis
flutter analyze

# 5. Tests with coverage
flutter test --coverage

# 6. Manual coverage check (requires lcov installed: brew install lcov)
genhtml coverage/lcov.info --output-directory coverage/html
open coverage/html/index.html
```

To check the numeric coverage threshold locally without a browser:

```bash
LINES_FOUND=$(grep -E '^LF:' coverage/lcov.info | awk -F: '{ sum += $2 } END { print sum+0 }')
LINES_HIT=$(grep -E '^LH:' coverage/lcov.info | awk -F: '{ sum += $2 } END { print sum+0 }')
awk "BEGIN { printf \"Coverage: %.2f%%\n\", ($LINES_HIT / $LINES_FOUND) * 100 }"
```

## Required GitHub Secrets

The table below documents all secrets that must be configured in GitHub repository settings before each workflow can succeed.

| Secret name | Used by | When needed | Notes |
|---|---|---|---|
| `CODECOV_TOKEN` | `pr_checks.yml` | Now (optional) | Codecov upload works without a token for public repos; required for private repos. Obtain from codecov.io project settings. |
| `ANDROID_KEYSTORE_BASE64` | `release.yml` | Before first signed release | Base64-encoded `.jks` keystore file. Generate with `keytool`; encode with `base64 -i keystore.jks`. |
| `ANDROID_KEYSTORE_PASSWORD` | `release.yml` | Before first signed release | Keystore password. |
| `ANDROID_KEY_ALIAS` | `release.yml` | Before first signed release | Key alias within the keystore. |
| `ANDROID_KEY_PASSWORD` | `release.yml` | Before first signed release | Key password. |
| `PLAY_STORE_JSON_KEY` | `release.yml` | Before Play Store deploy | Google Play service account JSON (plaintext). |
| `APP_STORE_CONNECT_API_KEY` | `release.yml` | Before TestFlight deploy | App Store Connect API key (.p8 file contents). |
| `APP_STORE_CONNECT_API_KEY_ID` | `release.yml` | Before TestFlight deploy | Key ID from App Store Connect (10-char string). |
| `APP_STORE_CONNECT_API_ISSUER_ID` | `release.yml` | Before TestFlight deploy | Issuer UUID from App Store Connect. |
| `MATCH_PASSWORD` | `release.yml` | Before iOS signed build | Passphrase for the fastlane match certificates repo. |
| `MATCH_GIT_BASIC_AUTHORIZATION` | `release.yml` | Before iOS signed build | Base64-encoded `username:token` for the match certificates private repo. |

## Flutter Version Pin Rationale

Workflows are pinned to `3.22.x` (latest patch in the 3.22 stable line) rather than `stable` or `latest`.

Reasons:
- `stable` can shift to a new minor/major without notice and introduce breaking API changes mid-sprint.
- Pinning to a minor series (e.g., `3.22.x`) picks up patch-level bug fixes automatically while keeping the API surface stable.
- All team members should run the same Flutter version locally. Use `fvm` (Flutter Version Management) or update your local SDK to `3.22.x` to match CI exactly.
- When the team decides to upgrade Flutter, a single PR updates `FLUTTER_VERSION` in both workflow files and the change is reviewed like any other code change.
