# ADR-012: Analytics Service — Stub-First Approach

**Status:** Accepted
**Date:** 2026-05-01
**Epic:** EPIC8A-12

## Context

MoneyWise V1 does not have a real analytics backend. However, product analytics
(home tab views, insight card taps) were requested in EPIC8A-12 to enable future
funnel analysis once a backend (e.g., Firebase Analytics) is added.

The initial implementation shipped `AnalyticsService` as a concrete class. The
code reviewer (2026-05-01) flagged that a concrete class breaks the swap contract —
a future `FirebaseAnalyticsService` cannot be typed as `AnalyticsService` without
inheritance, and overriding the provider in tests requires instantiating the concrete
stub rather than a spy.

## Decision

Implement a thin `AnalyticsService` abstract interface and a `StubAnalyticsService`
concrete implementation that logs to `debugPrint` in debug mode only (guarded by
`kDebugMode`). Wire via Riverpod so the provider can be overridden in tests and
swapped for a real backend in a future sprint.

### Interface contract

```dart
abstract interface class AnalyticsService {
  void logEvent(String name, {Map<String, dynamic>? parameters});
}
```

### Stub implementation

`StubAnalyticsService` implements `AnalyticsService` and uses
`debugPrint('[Analytics] ...')` in `kDebugMode` only. In release/profile builds
it is a true no-op with zero overhead.

### Provider

`analyticsServiceProvider` returns `AnalyticsService` (the interface). Swap path
for Firebase:

```dart
analyticsServiceProvider.overrideWith((_) => FirebaseAnalyticsService())
```

### V1 event registry

| Event name | Trigger | Parameters |
|---|---|---|
| `home_tab_viewed` | HomeScreen first mount (fire-once per mount, guarded by `_didLogTabView`) | none |
| `insight_card_tapped` | User taps an InsightCard in ThisWeekSection | `insight_type: String` (= `Insight.id`) |

### Fire-once guard for `home_tab_viewed`

`_HomeScreenState` carries a `bool _didLogTabView` field initialised to `false`.
The `initState` post-frame callback checks and sets this flag before firing the
event, ensuring the event fires at most once per widget mount even if `initState`
is somehow invoked more than once.

## Alternatives considered

**Option A — Concrete class only (initial implementation):** Simpler but breaks
the swap contract. A future Firebase class cannot be typed as `AnalyticsService`
without inheritance. Tests must instantiate the stub, not a spy. Rejected.

**Option B — Abstract interface + stub (chosen):** `AnalyticsService` is the
interface; `StubAnalyticsService` is the V1 implementation. The provider returns
the interface type. Future Firebase implementation just implements the interface
and overrides the provider.

## Consequences

- All analytics call sites depend on `AnalyticsService` (the interface), not the
  stub — call sites never change when the backend is swapped.
- Tests can inject a `_SpyAnalyticsService implements AnalyticsService` to assert
  specific events fired without any mocking framework.
- In release builds the stub is a true no-op — zero console noise in production.
- Adding Firebase requires: (1) create `FirebaseAnalyticsService implements
  AnalyticsService`, (2) `analyticsServiceProvider.overrideWith(...)` in app
  bootstrap, (3) no changes to call sites.

## References

- EPIC8A-12 implementation PR
- Code review findings 2026-05-01 (Critical 3)
