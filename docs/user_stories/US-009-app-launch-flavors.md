# US-009: App launches on both iOS and Android with correct flavors

## Source
SPEC.md §12.4 (Environments), §16.1 Sprint 1 checklist — integration of flavors with end-to-end launch verification

## Persona
A QA engineer and Product Sponsor who need to verify the complete end-to-end launch experience on both platforms before Sprint 1 can be signed off.

## Story
**As** a MoneyWise stakeholder
**I want** to launch the app on both iOS and Android devices using the dev, staging, and prod flavors, with each flavor showing the correct app name and environment configuration
**So that** I can confirm the foundational build pipeline is working correctly before feature development begins

## Acceptance Criteria

```gherkin
Scenario: Dev flavor app launches on iOS with correct name and environment
  Given an iOS device or simulator is connected
  When the app is built and launched with `flutter run --flavor dev -t lib/main_dev.dart`
  Then the app name shown on the home screen is "MoneyWise.dev"
  And the Env.current value inside the app is Environment.dev
  And the 4-tab navigation shell is displayed without errors
  And no red error screen or uncaught exception appears

Scenario: Dev flavor app launches on Android with correct name and environment
  Given an Android emulator or device is connected
  When the app is built and launched with `flutter run --flavor dev -t lib/main_dev.dart`
  Then the app name shown in the app drawer is "MoneyWise.dev"
  And the Env.current value inside the app is Environment.dev
  And the 4-tab navigation shell is displayed without errors

Scenario: Staging flavor app launches on both platforms
  Given a device or emulator is connected
  When the app is built with the staging flavor
  Then the app name is "MoneyWise.staging" (or "MoneyWise Beta" — exact name TBD with Sponsor)
  And Env.current is Environment.staging

Scenario: Prod flavor app launches with clean app name
  Given a device or emulator is connected
  When the app is built with `flutter build apk --flavor prod --release`
  Then the app name is "MoneyWise" with no suffix
  And Env.current is Environment.prod
  And no debug banner is shown (release mode)

Scenario: Each flavor has a distinct bundle ID
  Given all three flavors are installed simultaneously on one device
  When an engineer checks installed app bundle IDs
  Then dev shows bundle ID ending in ".dev"
  And staging shows bundle ID ending in ".staging"
  And prod shows the base bundle ID
  And all three coexist without overwriting each other

Scenario: Bootstrap sequence completes without error on cold start
  Given the app launches in any flavor
  When bootstrap.dart runs (DI setup, DB init, env loading)
  Then the sequence completes within 3 seconds on a mid-range device
  And no error is thrown during bootstrap
  And the app displays the 4-tab navigation shell
```

## Edge Cases
- [ ] Low memory device: bootstrap must not fail if the device has less than 2 GB RAM
- [ ] App killed during bootstrap (e.g., user swipes away during loading): on relaunch the bootstrap must run cleanly again without corrupted state
- [ ] Missing .env file for a flavor must produce a build error, not a runtime crash (fail fast)
- [ ] First launch performance: the cold start time (time to interactive) must be measurable and recorded as a Sprint 1 baseline; target is under 3 seconds on a Pixel 6 / iPhone 12
- [ ] iOS: app must not crash if launched in airplane mode (no network required for basic launch)
- [ ] Dark mode and light mode: app must launch correctly under both system theme settings

## Test Scenarios for QA
1. iOS Simulator — install and launch dev flavor, verify ".dev" app name and no crash
2. iOS Simulator — install and launch prod flavor (release), verify plain "MoneyWise" name and no debug banner
3. Android Emulator — install and launch dev flavor, verify ".dev" app name and no crash
4. Android Emulator — install and launch prod flavor (release), verify plain "MoneyWise" name
5. Install all three flavors on one physical Android device simultaneously — verify they coexist under separate icons and bundle IDs
6. Measure cold start time (from tap to first frame) on both platforms — record baseline result
7. Launch app with device in airplane mode — verify app launches without crash

## UX Spec
N/A — this story verifies foundational infrastructure, not UI design

## Estimate
S (1 day — primarily validation; implementation is covered by US-001 and US-003)

## Dependencies
- US-001 (flavor configuration)
- US-003 (navigation shell — app must show tabs after launch)
- US-004 (Drift DB — bootstrap includes DB init)
- US-007 (all dependencies must be resolved)
