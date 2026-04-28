# US-008: CI pipeline — GitHub Actions pr_checks.yml runs lint, format check, and tests on every PR

## Source
SPEC.md §12.1.1 (pr_checks.yml), §11.4 (Coverage targets), §16.1 Sprint 1 checklist — "CI/CD temel pipeline (lint + test + build)"

## Persona
A flutter engineer and code reviewer who need automated quality gates on every pull request so that broken code can never be merged into main or develop.

## Story
**As** the MoneyWise development team
**I want** a GitHub Actions workflow that runs lint, format check, and tests automatically on every pull request
**So that** quality regressions are caught before code is merged, without relying on manual checks

## Acceptance Criteria

```gherkin
Scenario: Workflow triggers on every PR targeting main or develop
  Given a developer opens a pull request targeting the main branch
  When the PR is created or a new commit is pushed to the PR branch
  Then the "PR Checks" workflow starts automatically within 2 minutes

Scenario: Workflow triggers on PRs targeting develop
  Given a developer opens a pull request targeting the develop branch
  When the PR is created
  Then the "PR Checks" workflow starts automatically

Scenario: flutter analyze must pass for the workflow to succeed
  Given the PR Checks workflow is running
  When the `flutter analyze` step executes
  Then if any analyzer error or warning is found, the step fails and the workflow is marked red
  And the PR cannot be merged until the failure is resolved

Scenario: dart format check must pass for the workflow to succeed
  Given the PR Checks workflow is running
  When the `dart format --set-exit-if-changed .` step executes
  Then if any file is not correctly formatted, the step fails
  And the PR cannot be merged until all files are formatted

Scenario: Code generation runs before analyze and test
  Given the PR Checks workflow is running
  When the `dart run build_runner build --delete-conflicting-outputs` step executes before flutter analyze
  Then generated files are up to date before lint and tests run
  And the workflow does not fail due to missing generated files

Scenario: flutter test runs and coverage is uploaded
  Given the PR Checks workflow is running
  When the `flutter test --coverage` step executes
  Then if any test fails, the step fails and the workflow is marked red
  And the coverage report (coverage/lcov.info) is uploaded to Codecov

Scenario: Workflow uses correct Flutter version
  Given the pr_checks.yml workflow file is inspected
  When the subosito/flutter-action step is examined
  Then it specifies flutter-version "3.22.x" and channel "stable"

Scenario: Workflow file is located at the correct path
  Given the repository root is inspected
  When .github/workflows/ is browsed
  Then pr_checks.yml exists at .github/workflows/pr_checks.yml
```

## Edge Cases
- [ ] The workflow must cache Flutter SDK and pub packages to avoid exceeding GitHub Actions free tier minutes unnecessarily
- [ ] If `build_runner` generates conflicting outputs (e.g., two packages both generate a file with the same name), the `--delete-conflicting-outputs` flag must resolve this silently
- [ ] The workflow must not use deprecated GitHub Actions versions (e.g., actions/checkout must be v4, not v2)
- [ ] The Codecov upload step must be configured to not fail the workflow if the Codecov service is temporarily unavailable (continue-on-error: true for the upload step)
- [ ] Secrets (e.g., CODECOV_TOKEN) must be stored as GitHub repository secrets, not hardcoded in the YAML
- [ ] The workflow must run on `ubuntu-latest` runner for the PR checks job (macOS runner is reserved for iOS build jobs to control cost)

## Test Scenarios for QA
1. Open a PR with a deliberate analyzer warning (e.g., unused variable) — verify workflow fails on the analyze step
2. Open a PR with an unformatted file — verify workflow fails on the format step
3. Open a PR with a failing unit test — verify workflow fails on the test step
4. Open a PR with all checks passing — verify workflow succeeds and the PR merge button becomes available
5. Inspect the Actions tab for a passing PR — verify coverage report was uploaded to Codecov
6. Verify workflow runtime is under 10 minutes for a clean run (with caching)

## UX Spec
N/A — no UI involved

## Estimate
S (1–2 days)

## Dependencies
- US-001 (project must exist and be pushed to GitHub)
- US-007 (pubspec.yaml with all dependencies, so pub get does not fail in CI)
