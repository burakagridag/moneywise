# ADR-005: Integer Primary Key for Transactions Table (Phase 1)

## Status
Accepted — 2026-04-29

## Context
SPEC.md §6.4 specifies UUID v4 as the primary key format for all tables to
support conflict-free offline sync with Supabase in a later phase. However, the
current Sprint 4 implementation uses `integer().autoIncrement()` for the
`Transactions` table, which matches the simpler `accounts` and `categories` tables
that use text PKs but not the UUID requirement.

Migrating to UUID now would require:
1. A schema migration on a table that may already have user data in test builds.
2. Ripple changes across DAOs, repositories, domain entities, providers, and tests.
3. Coordinating the change with Sprint 5 (Budget) which builds on top of this table.

Supabase sync is explicitly deferred to Phase 2 (Sprint 9+). The app is currently
local-only, so UUID uniqueness across devices is not yet needed.

## Decision
Keep `integer().autoIncrement()` as the primary key for the `Transactions` table
through Sprint 8 (inclusive). No migration to UUID will be performed in Sprints
4–8.

## Consequences

### Positive
- No risky migration in an actively-developed table.
- Tests remain stable; no ID type changes cascade to existing test fixtures.
- Keeps Sprint 4 scope contained to the blocker fixes identified by code review.

### Negative
- SPEC.md §6.4 is temporarily violated.
- When Supabase sync is introduced in Sprint 9, a data migration from integer PK
  to UUID will be required. This migration must be planned carefully to preserve
  existing user data.

### Mitigation
- Sprint 9 (Supabase Setup) will include a dedicated task:
  "Migrate `Transactions.id` from `INTEGER AUTOINCREMENT` to `TEXT` (UUID v4),
  with a one-time migration function that generates UUIDs for existing rows."
- All new code MUST avoid hard-coupling to the integer PK type (use `int` via
  Drift-generated types; never cast to `String` unless explicitly mapping).

## Alternatives Rejected
- **Migrate now**: High-risk, cross-cutting change; violates sprint scope.
- **Dual column (int + uuid)**: Over-engineering for a local-only phase.

## References
- SPEC.md §6.4 — Data model UUID requirement
- Code Reviewer Sprint 4 blocker report — KRITIK 4
- Sprint 9 plan (to be created): Supabase integration milestone
