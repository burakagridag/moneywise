# US-007: pubspec.yaml configured with all Sprint 1 dependencies

## Source
SPEC.md §4.1 (Technology Stack — full dependency list), §16.1 Sprint 1 checklist — "pubspec.yaml + tüm dependencies"

## Persona
A flutter engineer who needs all required packages declared and resolvable in pubspec.yaml before any feature work begins.

## Story
**As** a MoneyWise developer
**I want** pubspec.yaml to declare all project dependencies with correct version constraints
**So that** every team member and the CI pipeline resolves the same package versions without conflicts

## Acceptance Criteria

```gherkin
Scenario: All Sprint 1 runtime dependencies are declared
  Given the pubspec.yaml file exists at the project root
  When `flutter pub get` is run
  Then the following packages resolve without conflict:
    | flutter_riverpod     | ^2.5.0  |
    | riverpod_annotation  | ^2.3.0  |
    | go_router            | ^14.0.0 |
    | drift                | ^2.18.0 |
    | sqlcipher_flutter_libs | latest |
    | flutter_secure_storage | latest |
    | freezed_annotation   | latest  |
    | json_annotation      | latest  |
    | intl                 | latest  |
    | money2               | latest  |
    | fl_chart             | ^0.68.0 |
    | phosphor_flutter     | latest  |
    | dio                  | ^5.4.0  |

Scenario: All dev_dependencies are declared
  Given the pubspec.yaml file exists
  When `flutter pub get` is run
  Then the following dev packages resolve without conflict:
    | build_runner         | latest |
    | riverpod_generator   | latest |
    | drift_dev            | latest |
    | freezed              | latest |
    | json_serializable    | latest |
    | flutter_lints        | ^4.0.0 |
    | mocktail             | latest |

Scenario: build_runner code generation runs successfully
  Given all dependencies are resolved
  When `dart run build_runner build --delete-conflicting-outputs` is executed
  Then the command completes without error
  And generated .g.dart and .freezed.dart files are produced

Scenario: flutter analyze passes with zero warnings
  Given all dependencies are installed and code generation has run
  When `flutter analyze` is executed
  Then zero errors and zero warnings are reported

Scenario: App version is correctly set
  Given the pubspec.yaml is configured
  When the version field is inspected
  Then it reads "1.0.0+1"
  And the app display name is "MoneyWise"

Scenario: flutter_lints analysis_options.yaml is configured
  Given the project root contains analysis_options.yaml
  When the file is inspected
  Then it includes `flutter_lints` rule set
  And it enables prefer_const_constructors and avoid_print rules at minimum
```

## Edge Cases
- [ ] Version constraints must use caret (^) ranges, not exact pins, to allow patch-level security updates without lock-file conflicts
- [ ] `sqlcipher_flutter_libs` requires native build configuration on both iOS (Podfile) and Android (build.gradle) — the podfile and gradle changes must accompany this story
- [ ] `phosphor_flutter` icon set must be added to the assets/fonts section if it ships as a font file
- [ ] All packages that require iOS permissions (local_auth, image_picker etc.) must have their Info.plist usage description keys added in this story to avoid build failures in future sprints
- [ ] `flutter_secure_storage` requires Android's minSdkVersion to be at least 18; pubspec and gradle must enforce this
- [ ] The analysis_options.yaml must not suppress warnings that would hide real issues (e.g., `avoid_dynamic_calls` should be enabled)

## Test Scenarios for QA
1. Run `flutter pub get` on a clean clone — expect zero resolution errors
2. Run `dart run build_runner build --delete-conflicting-outputs` — expect zero errors and generated files created
3. Run `flutter analyze` — zero warnings or errors
4. Run `flutter build apk --flavor dev` — expect successful build with all native dependencies linked
5. Run `flutter build ios --flavor dev --no-codesign` — expect successful build (on macOS)
6. Inspect pubspec.lock and confirm all package versions are consistent with stated constraints

## UX Spec
N/A — no UI involved

## Estimate
S (1 day)

## Dependencies
- US-001 (project skeleton must exist before pubspec.yaml can be configured)
