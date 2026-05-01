# Story EPIC8A-17 — Feature Flag + DevOps

**Assigned to:** DevOps Engineer
**Estimated effort:** 1 point
**Dependencies:** EPIC8A-16 (QA sign-off required)
**Phase:** 4

## Description

Configure and deploy the `homeTabEnabled` feature flag to gate the Epic 8a Home tab rollout. The feature flag controls whether the new 4-tab IA (Home as default tab) is active or the old experience is shown. The flag allows a gradual rollout: 10% → 50% → 100% of users, with the ability to kill-switch back to the old experience without a new app release.

The feature flag implementation must be consistent with however flags are managed in this codebase. If no feature flag infrastructure exists yet, implement a minimal `FeatureFlags` class with a local override (a `dart_define` or a `SharedPreferences` key). Do not integrate a paid remote config service without Sponsor approval; a local flag (`--dart-define=FEATURE_HOME_TAB=true`) is acceptable for the initial rollout.

The DevOps engineer also prepares a draft release note for the TestFlight and Play Internal builds, and a post-release monitoring checklist.

## Inputs (agent must read)

- `docs/qa/epic8a-results.md` and `docs/qa/epic8a-bugs.md` — QA sign-off (EPIC8A-16 output)
- Existing CI/CD configuration: `.github/workflows/` — GitHub Actions pipelines
- `lib/main.dart` — app entry point for flag check
- `docs/decisions/` — check for any existing ADR on feature flags

## Outputs (agent must produce)

- `lib/core/config/feature_flags.dart` — `FeatureFlags` class with `homeTabEnabled` bool (read from `dart_define` or equivalent; default `false` for old behavior, `true` to enable new Home tab)
- `lib/main.dart` or `lib/core/router/app_router.dart` — flag check: if `homeTabEnabled = false`, initial location is `/transactions` (old behavior); if `true`, initial location is `/home`
- `.github/workflows/` — update build workflow to pass `--dart-define=FEATURE_HOME_TAB=true` for the "feature-enabled" build variant (TestFlight + Play Internal)
- `docs/releases/epic8a-release-notes.md` — draft release notes for Sponsor review (user-facing language, no technical jargon)
- `docs/releases/epic8a-monitoring-checklist.md` — post-release checklist: crash rate, home tab engagement metrics, 7-day stability window

## Acceptance Criteria

- [ ] `homeTabEnabled = false`: app launches with Transactions as default tab (old behavior identical to pre-Epic-8a)
- [ ] `homeTabEnabled = true`: app launches with Home as default tab; all 5 Home components render
- [ ] Feature flag can be toggled without a code change (via `dart_define` or equivalent)
- [ ] TestFlight and Play Internal builds are submitted with `homeTabEnabled = true`
- [ ] Release notes draft is written in user-facing English (no "Riverpod", "Drift", "flutter_analyze" mentions)
- [ ] Monitoring checklist includes: crash-free session rate, home tab open rate, pull-to-refresh usage rate, 7-day window before 100% rollout
- [ ] CI pipeline passes with the new flag parameter

## Out of Scope

- 100% rollout to production App Store / Play Store (requires Sponsor approval in weekly review)
- A/B testing infrastructure (Sponsor has not approved an A/B test — full commit to Home tab)
- Remote config SDK integration

## Quality Bar

The kill-switch must work: setting `homeTabEnabled = false` in a rebuild must revert the app to pre-Epic-8a behavior with no crashes or data issues. This must be verified and documented in the PR.
