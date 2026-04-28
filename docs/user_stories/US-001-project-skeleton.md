# US-001: Flutter project initialised with dev/staging/prod flavors

## Source
SPEC.md §16.1 Sprint 1 checklist — "Flutter proje oluştur (flavors: dev, staging, prod)"

## Persona
A flutter engineer who needs a properly structured, multi-flavor Flutter project to begin feature development without rework.

## Story
**As** the MoneyWise development team
**I want** a Flutter project created with three separate build flavors (dev, staging, prod) and corresponding entry points
**So that** each environment can be built, distributed, and configured independently without code changes

## Acceptance Criteria

```gherkin
Scenario: Project runs on iOS with dev flavor
  Given the repository has been cloned and `flutter pub get` has been run
  When the developer runs `flutter run --flavor dev -t lib/main_dev.dart`
  Then the app launches on an iOS simulator
  And the app name displayed on the device home screen includes ".dev" suffix (e.g., "MoneyWise.dev")
  And no compile errors or analyzer warnings are present

Scenario: Project runs on Android with dev flavor
  Given the repository has been cloned and `flutter pub get` has been run
  When the developer runs `flutter run --flavor dev -t lib/main_dev.dart`
  Then the app launches on an Android emulator
  And the app name includes ".dev" suffix
  And no compile errors or analyzer warnings are present

Scenario: Staging flavor builds successfully
  Given the repository is set up
  When the developer runs `flutter build apk --flavor staging -t lib/main_staging.dart`
  Then the build completes without errors
  And the output APK is named with "staging" in the artifact path

Scenario: Prod flavor builds successfully
  Given the repository is set up
  When the developer runs `flutter build apk --flavor prod -t lib/main_prod.dart`
  Then the build completes without errors
  And the app name does not include any suffix (plain "MoneyWise")

Scenario: Environment is loaded correctly per flavor
  Given the app is built with the dev flavor
  When the Env.current value is read at runtime
  Then Env.current equals Environment.dev

Scenario: Separate bundle IDs per flavor
  Given the three flavors are configured
  Then dev uses bundle ID suffix ".dev" (e.g., com.moneywise.app.dev)
  And staging uses bundle ID suffix ".staging"
  And prod uses the base bundle ID (e.g., com.moneywise.app)
```

## Edge Cases
- [ ] Running `flutter run` without specifying a flavor must fail with a clear error, not silently use a default
- [ ] `main_prod.dart` must not reference any debug/dev-only libraries
- [ ] Building prod flavor with debug symbols should still work for crash reporting setup
- [ ] `flutter analyze` must pass on all three entry point files
- [ ] iOS xcconfig files for each flavor must be committed; absent xcconfig causes silent config fallback

## Test Scenarios for QA
1. Build and launch dev flavor on iOS Simulator — verify ".dev" app name suffix
2. Build and launch dev flavor on Android Emulator — verify ".dev" app name suffix
3. Build and launch staging flavor on iOS Simulator — verify ".staging" app name suffix
4. Build prod flavor (release) on Android — verify plain app name, no debug banner
5. Verify bundle IDs in running app match expected per-flavor values
6. Run `flutter analyze` on entire project — zero warnings required

## UX Spec
N/A — no UI involved

## Estimate
S (1–2 days)

## Dependencies
None — this is the foundational story
