# CI/CD Setup — Sprint 1

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

This workflow validates that the Android toolchain and flavor configuration are intact after every merge. Signed release builds are handled by a separate `release.yml` workflow (planned for Sprint 2+).

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

No secrets are required for Sprint 1. The table below documents all secrets that must be configured before later workflows can succeed.

| Secret name | Used by | When needed | Notes |
|---|---|---|---|
| `CODECOV_TOKEN` | `pr_checks.yml` | Now (optional) | Codecov upload works without a token for public repos; required for private repos. Obtain from codecov.io project settings. |
| `ANDROID_KEYSTORE_BASE64` | `release.yml` (Sprint 2+) | Before first signed release | Base64-encoded `.jks` keystore file. Generate with `keytool`; encode with `base64 -i keystore.jks`. |
| `ANDROID_KEYSTORE_PASSWORD` | `release.yml` (Sprint 2+) | Before first signed release | Keystore password. |
| `ANDROID_KEY_ALIAS` | `release.yml` (Sprint 2+) | Before first signed release | Key alias within the keystore. |
| `ANDROID_KEY_PASSWORD` | `release.yml` (Sprint 2+) | Before first signed release | Key password. |
| `PLAY_STORE_JSON_KEY` | `release.yml` (Sprint 2+) | Before Play Store deploy | Google Play service account JSON. |
| `APP_STORE_CONNECT_API_KEY` | `release.yml` (Sprint 2+) | Before TestFlight/App Store deploy | App Store Connect API key (base64 or raw). |
| `MATCH_PASSWORD` | `build_ios.yml` (Sprint 2+) | Before iOS build | Passphrase for the fastlane match certificates repo. |
| `MATCH_GIT_BASIC_AUTHORIZATION` | `build_ios.yml` (Sprint 2+) | Before iOS build | Base64-encoded `username:token` for the match certificates private repo. |

## Flutter Version Pin Rationale

Workflows are pinned to `3.22.x` (latest patch in the 3.22 stable line) rather than `stable` or `latest`.

Reasons:
- `stable` can shift to a new minor/major without notice and introduce breaking API changes mid-sprint.
- Pinning to a minor series (e.g., `3.22.x`) picks up patch-level bug fixes automatically while keeping the API surface stable.
- All team members should run the same Flutter version locally. Use `fvm` (Flutter Version Management) or update your local SDK to `3.22.x` to match CI exactly.
- When the team decides to upgrade Flutter, a single PR updates `FLUTTER_VERSION` in both workflow files and the change is reviewed like any other code change.
