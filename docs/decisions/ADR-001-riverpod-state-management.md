# ADR-001: Use Riverpod for State Management

## Status
Accepted — 2026-04-28

## Context
MoneyWise is a Flutter mobile app with significant reactive state requirements:
- Reactive UI bound to a local SQLite database (Drift) that streams updates
- Form state (Add Transaction modal) with multi-field validation
- Cross-feature state (filters, period selection, theme) shared across screens
- Testability — all state must be unit-testable

We evaluated:
- **Riverpod 2.5+** with `riverpod_generator` and `freezed`
- **BLoC / Cubit**
- **Provider** (basic)
- **Redux**

## Decision
Use **Riverpod 2.5+** with code-gen (`riverpod_generator`) and `freezed` for immutable state classes.

## Rationale

### Why Riverpod
1. **Compile-time safety** — `@riverpod` annotation generates strongly-typed providers
2. **Drift integration** — Drift's `Stream<T>` queries plug directly into `StreamProvider`
3. **Testability** — `ProviderContainer` with `overrideWith` makes unit testing trivial
4. **No BuildContext dependency** — providers are framework-agnostic
5. **AsyncValue pattern** — first-class loading/error/data handling for async operations

### Why not BLoC
- More boilerplate (event + state + bloc per feature)
- Less seamless integration with Drift streams
- Pattern-overkill for many simple state cases

### Why not basic Provider
- Lacks compile-time safety
- Less ergonomic for async operations
- No code-gen support

### Why not Redux
- Significant boilerplate
- Single-store architecture is overkill for a feature-first app
- Community momentum has shifted to Riverpod / BLoC

## Consequences

### Positive
- High test coverage achievable (`ProviderContainer` overrides)
- Clean separation: UI ↔ Provider ↔ Repository ↔ DAO
- Familiar pattern for Flutter community

### Negative
- `build_runner` step required (tooling overhead)
- Engineers new to Riverpod will need ramp-up time
- Slightly more verbose than basic `Provider`

## References
- Riverpod docs: https://riverpod.dev
- SPEC.md Section 4.1, Section 10
- Drift + Riverpod integration: https://drift.simonbinder.eu/docs/getting-started/

## Reviewers
- flutter-engineer (author)
- Product Sponsor (approved)
