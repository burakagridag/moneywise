# Story EPIC8A-12 — Analytics Events: home_tab_viewed + insight_card_tapped

**Assigned to:** Flutter Engineer
**Estimated effort:** 1 point
**Dependencies:** EPIC8A-03, EPIC8A-08
**Phase:** 3

## Description

Add the two analytics events mandated by the Sponsor for the Home tab: `home_tab_viewed` (fired once per session when the Home tab becomes active) and `insight_card_tapped` (fired each time the user taps an insight card).

The analytics implementation must follow whatever analytics infrastructure is already in the codebase (check `lib/core/analytics/` or `lib/services/analytics/`). If no analytics service exists yet, create a minimal `AnalyticsService` interface with a `logEvent(String name, {Map<String, Object>? parameters})` method and a no-op `NoOpAnalyticsService` implementation. Do not integrate a paid third-party SDK without Sponsor approval.

Event payloads:
- `home_tab_viewed`: no additional parameters required for V1
- `insight_card_tapped`: `{ "insight_id": insight.id, "insight_severity": insight.severity.name }`

## Inputs (agent must read)

- `lib/core/analytics/` or `lib/services/analytics/` — existing analytics infrastructure (if any)
- `lib/features/home/presentation/screens/home_screen.dart` — where to fire `home_tab_viewed`
- `lib/features/home/presentation/widgets/insight_card.dart` — where to fire `insight_card_tapped` (or in the `onTap` handler in `HomeScreen`)
- `lib/features/insights/domain/insight.dart` — `Insight.id` and `InsightSeverity` for the event payload
- Sponsor decisions: analytics events `home_tab_viewed` + `insight_card_tapped`

## Outputs (agent must produce)

- `lib/core/analytics/analytics_service.dart` — `abstract class AnalyticsService` + `NoOpAnalyticsService` (if not already present)
- `lib/features/home/presentation/screens/home_screen.dart` — fires `home_tab_viewed` on tab focus (using `WidgetsBindingObserver` or router listener; same mechanism as tab focus invalidation from EPIC8A-11 if applicable)
- `lib/features/home/presentation/widgets/insight_card.dart` — `onTap` wrapper fires `insight_card_tapped` before calling the provided `onTap` callback
- `test/features/home/analytics_test.dart` — unit tests with a mock `AnalyticsService` verifying both events fire with correct payloads
- `docs/prs/epic8a-12.md`

## Acceptance Criteria

- [ ] `home_tab_viewed` fires once each time the user navigates to the Home tab (not on every rebuild)
- [ ] `home_tab_viewed` does not fire when the Home tab is already active and a rebuild occurs
- [ ] `insight_card_tapped` fires with `insight_id` and `insight_severity` when a tappable insight card is tapped
- [ ] Analytics events do not fire in test environments (use `NoOpAnalyticsService` override in tests)
- [ ] If no analytics SDK is present, `NoOpAnalyticsService` is the default binding — no crash, no side effects
- [ ] `flutter analyze` and `dart format` pass

## Out of Scope

- Integrating Firebase Analytics, Amplitude, or any paid SDK (requires Sponsor approval)
- Analytics events for any other tab or screen
- A/B test event tracking

## Quality Bar

Mock analytics events must be verifiable via unit tests. The engineer must confirm that `home_tab_viewed` is called exactly once per tab visit, not multiple times during widget rebuilds — this must be covered by a test that rebuilds the widget and asserts the call count.
