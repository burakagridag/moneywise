# Story EPIC8A-02 — Stats Tab Removal & Codebase Cleanup

**Assigned to:** Flutter Engineer
**Estimated effort:** 2 points
**Dependencies:** EPIC8A-01
**Phase:** 1

## Description

Remove all Stats tab artefacts from the codebase after the routing shell is in place (EPIC8A-01). This includes deleting the Stats feature directory, removing all Stats-related imports, and verifying that no dead references remain. Critically, the cleanup must be surgical: the "Note" sub-tab feature (`StatsNoteView`) is removed, but transaction-level notes (the `note` field on individual transactions, visible in transaction detail and Bookmarks) must continue to work without regression.

The donut chart previously in Stats will eventually appear on the Home tab (Phase 2), but that wiring is not part of this story — the chart widget may be moved to a shared widgets location if it already exists, or left in place temporarily with a TODO comment for EPIC8A-08.

## Inputs (agent must read)

- `lib/features/stats/` — full directory listing and all files
- `lib/features/transactions/` — confirm transaction-level note field is not in Stats
- `lib/features/more/` — confirm no cross-import from Stats
- `lib/core/router/app_router.dart` — confirm Stats routes removed (EPIC8A-01 output)
- Search codebase for `StatsNoteView`, `stats_note`, `/stats` string literals
- `docs/stories/epic-8a/README.md` — Sponsor decision: Stats tab removed; Notes feature at transaction level stays

## Outputs (agent must produce)

- Delete `lib/features/stats/` directory entirely (or the sub-directories for the Stats-only views)
- Remove all `import` statements referencing deleted Stats files from any remaining file
- `lib/features/transactions/presentation/widgets/` — confirm `TransactionDetailSheet` still shows the `note` field
- `lib/features/bookmarks/` (if exists from Sprint 6) — confirm no import of Stats files
- `docs/prs/epic8a-02.md` — PR description listing every deleted file, every updated import, and a QA checklist for note regression

## Acceptance Criteria

- [ ] `lib/features/stats/` directory (or all Stats-specific sub-files) is deleted from the codebase
- [ ] Zero references to `StatsNoteView`, `StatsScreen`, `StatsTab`, or `/stats` routes remain anywhere in `lib/` (confirmed via `grep`)
- [ ] `flutter analyze` passes with zero warnings after deletion
- [ ] Transaction detail bottom sheet still displays the `note` field for transactions that have one
- [ ] Bookmarks screen (Sprint 6 feature) loads without error and displays bookmarked transactions
- [ ] The donut chart widget file (if it exists as a reusable widget) is either preserved in a shared location with a TODO comment referencing EPIC8A-08, or its absence is explicitly noted in the PR description
- [ ] No compilation errors on either platform
- [ ] `dart format` passes

## Out of Scope

- Moving or re-implementing the donut chart on the Home tab (EPIC8A-08)
- Changing the Budget screen (it is already promoted in EPIC8A-01)
- Any UI changes to the Transactions or More screens
- Removing the `note` column from the transactions database table

## Quality Bar

A reviewer running `grep -r "stats" lib/ --include="*.dart" -i` (excluding legitimate lowercase uses in non-Stats contexts) should find zero hits. The PR description must include the grep command output confirming zero Stats references. Transaction note display must be verified on both platforms.
