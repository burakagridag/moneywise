# ADR-003: Sprint 1 Sponsor Decisions

## Status
Accepted — 2026-04-28

## Decisions

### 1. SQLCipher Encryption — Deferred to Sprint 2
The local Drift database (`NativeDatabase`) runs unencrypted in Sprint 1.
SQLCipher will be wired up in Sprint 2 alongside the first real data tables (accounts, categories).

### 2. App Icon — UX Designer to Propose Concepts
No icon is locked yet. UX Designer will propose 2–3 icon concepts (wallet + pen direction per SPEC.md §2.4).
Sponsor selects one before Sprint 2 ends.

### 3. First-Launch Language — Silent Device Follow
The app follows the device locale silently on first launch (no language picker in onboarding).
TR is served if the device is set to Turkish; EN otherwise.
A manual override is available later via the Language screen (Sprint 6).

### 4. App Icon — Concept 3 "W Chart" Selected
Sponsor selected Concept 3: five white vertical bars on solid coral (#FF6B5C) background,
simultaneously reading as the letter W and a bar chart.
Production spec written in `docs/specs/SPEC-003b-app-icon-final.md`.
