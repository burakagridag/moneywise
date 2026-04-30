# QA Report — Sprint 05: Stats Screen, Budget, and Note Views

**Branch:** sprint/05-stats-budget
**Date:** 2026-04-29
**Tester:** qa-agent
**Stories:** US-026, US-027, US-028, US-029, US-030

---

## QA Decision: FAIL

**Reason:** One P1 bug (BUG-010 — December boundary defect in BudgetEditModal) and multiple P2 bugs that leave sprint goal acceptance criteria unmet, including: pie segment navigation not implemented (BUG-005), period selector not functional (BUG-006), Income/Expense toggle missing from BudgetSettingScreen (BUG-007), NoteTransactionRow displays raw UUID instead of category name (BUG-009), and the TOTAL budget row not persisted as a DB record (BUG-003).

---

## Static Analysis

- `flutter analyze`: **0 warnings, 0 errors** — PASS
- `flutter test` (Sprint 5 scope — `test/features/budget/`, `test/features/stats/`, `test/core/widgets/budget_progress_bar_test.dart`): **97 tests, all passed** — PASS
- Full test suite: 431 total, 7 failures — all 7 are pre-existing `DbEncryptionService` tests unrelated to Sprint 5 (platform channel unavailable in test host); these were present before this sprint. Sprint 5 tests: **all pass**.

---

## Per-Story Verdict

| Story | Title | Status | Notes |
|-------|-------|--------|-------|
| US-026 | StatsScreen — pie chart | PARTIAL | Chart renders; segment tap and period selector are placeholders (BUG-005, BUG-006) |
| US-027 | Budget DB layer | PARTIAL | Core DAO/repository/carry-over work; soft-delete (BUG-011), carryOverEnabled flag (BUG-002), TOTAL row stored as null categoryId (BUG-003) not implemented |
| US-028 | BudgetView | PARTIAL | Summary card and progress bars work; unbudgeted categories hidden (BUG-001), carry-over unconditional (BUG-002) |
| US-029 | BudgetSettingScreen | PARTIAL | Screen accessible and modal works; 0.00 validation wrong (BUG-004), Income toggle missing (BUG-007), December boundary latent defect (BUG-010), TOTAL not editable (BUG-003) |
| US-030 | NoteView | PARTIAL | Grouping and sort work; "(no note)" position inverted (BUG-008), raw categoryId shown in expanded rows (BUG-009) |

---

## Sprint Goal Acceptance Criteria — Pass/Fail

| # | Sprint Goal Item | Result |
|---|-----------------|--------|
| 1 | Stats tab opens to Stats sub-tab by default | PASS |
| 2 | Three-sub-tab control visible, active tab branded | PASS |
| 3 | Period selector opens W/M/Y picker; updates navigator and data | FAIL — snackbar placeholder only (BUG-006) |
| 4 | Month/Year navigator advances and retreats all sub-tabs reactively | PASS |
| 5 | Income/Expense toggle switches aggregation across all sub-tabs | PASS |
| 6 | Stats sub-tab: donut chart with brand palette + legend | PASS |
| 7 | Stats sub-tab: tapping pie segment navigates to filtered DailyView | FAIL — snackbar placeholder (BUG-005) |
| 8 | Stats sub-tab: empty state with illustration and text | PASS (text shown; no illustration — acceptable) |
| 9 | Budget sub-tab: summary card with remaining, budget, spent, progress bar, Today indicator | PASS |
| 10 | Budget sub-tab: "Budget Setting >" link navigates to BudgetSettingScreen | PASS |
| 11 | Budget sub-tab: progress bar threshold colors (brand <70%, warning >=70%, error >=100%) | PASS |
| 12 | Budget sub-tab: carry-over applied when carryOverEnabled = true | PARTIAL — carry-over is always applied regardless of flag (BUG-002) |
| 13 | Note sub-tab: grouped by note, sorted, count badge, "(no note)" group | PARTIAL — "(no note)" position inverted (BUG-008) |
| 14 | Note sub-tab: tapping row opens detail | PASS — inline expand/collapse (acceptable variant) |
| 15 | BudgetSettingScreen reachable from More tab | PASS |
| 16 | BudgetSettingScreen: category list with TOTAL row first | PASS — TOTAL is derived sum (BUG-003 tracks DB gap) |
| 17 | BudgetEditModal: save with/without "Only this month" creates correct row | PASS (except December boundary latent defect BUG-010) |
| 18 | Budget DB: Drift migration adds budgets table on existing install | PASS — schemaVersion 5, `if (from < 5) createTable(budgets)` |
| 19 | Carry-over: negative carry-over clamped to 0 | PASS |
| 20 | Monetary values: no float artifacts in totals or percentages | PASS |
| 21 | flutter analyze passes zero warnings | PASS |
| 22 | All unit and widget tests pass | PARTIAL — Sprint 5 tests all pass; 7 pre-existing encryption test failures present |

**Sprint goal items passed:** 14 / 22
**Sprint goal items failed:** 3 (items 3, 7, and 12 fully; partial credit on 13, 16, 17, 22)

---

## Bug Summary

| Bug ID | Severity | Title | Blocker? |
|--------|----------|-------|---------|
| BUG-010 | P1 | December boundary in BudgetEditModal uses unchecked `month + 1` | Yes |
| BUG-001 | P2 | BudgetView hides categories without a configured budget | No |
| BUG-002 | P2 | `carryOverEnabled` flag not in DB schema — carry-over unconditional | No |
| BUG-003 | P2 | TOTAL row is derived sum, not a stored DB row with categoryId = null | No |
| BUG-004 | P2 | Saving 0.00 rejected — AC requires it to clear the budget | No |
| BUG-005 | P2 | Pie segment tap shows snackbar instead of navigating to DailyView | Yes |
| BUG-006 | P2 | Period selector (W/M/Y) is not functional | Yes |
| BUG-007 | P2 | BudgetSettingScreen lacks Income/Expense toggle | No |
| BUG-009 | P2 | NoteTransactionRow shows raw categoryId UUID instead of category name | No |
| BUG-011 | P2 | Budget soft-delete not implemented; hard delete only | No |
| BUG-008 | P3 | "(no note)" group pinned LAST — AC says FIRST | No |

**P1 count:** 1
**P2 count:** 9
**P3 count:** 1

---

## What Works Well

- Core DB layer is solid: Drift migration is clean, schemaVersion bump correct, DAO queries correct
- CarryOverBudgetUseCase logic is correct (overspend reduces effective budget, clamped to 0); January/December boundary handled
- BudgetProgressBar threshold colors are correctly implemented and clamped
- BudgetView empty state and error state are present
- BudgetSettingScreen navigation from both More tab and BudgetView link is correct
- BudgetEditModal "Only this month" checkbox creates correctly bounded effectiveTo (except December latent issue)
- NoteView grouping, sort toggle, count badge, and collapse animation are well-implemented
- All Sprint 5 unit and widget tests pass (97/97)
- `flutter analyze` clean

---

## Required Actions Before Re-QA

### Must Fix (blocking sprint acceptance)

1. **BUG-010 (P1):** Fix December boundary in `BudgetEditModal._save()` — guard `month == 12` before `month + 1`
2. **BUG-005 (P2):** Implement or formally defer pie segment tap navigation with a written ADR decision
3. **BUG-006 (P2):** Implement or formally defer period selector (W/M/Y) with a written ADR decision
4. **BUG-009 (P2):** Replace `transaction.categoryId` with resolved category name in `_NoteTransactionRow`

### Should Fix (AC gaps)

5. **BUG-007 (P2):** Add Income/Expense toggle to BudgetSettingScreen
6. **BUG-004 (P2):** Change validation to allow 0.00 (treat as "clear budget" via delete, or store 0)
7. **BUG-008 (P3):** Decide on "(no note)" position — AC says top, code says bottom; align one to the other and document

### Defer to Sprint 6 (acceptable gaps)

8. **BUG-001 (P2):** Show unbudgeted-but-spent categories in BudgetView — requires query join across categories + transactions without a budget row; add to Sprint 6 backlog
9. **BUG-002 (P2):** Add `carryOverEnabled` column to Drift schema (Sprint 6 migration) and UI toggle
10. **BUG-003 (P2):** Decide whether TOTAL budget is a separate DB row or remains a derived sum; document as ADR
11. **BUG-011 (P2):** Replace hard delete with soft delete if audit requirement is confirmed; otherwise remove the AC from US-027

---

## Re-QA Conditions

This sprint may be re-submitted for QA when:
- BUG-010 (P1) is fixed AND either resolved or formally deferred with PM sign-off for BUG-005, BUG-006, and BUG-009.
- `flutter analyze` still passes zero warnings after fixes.
- Sprint 5 unit/widget tests still all pass after fixes.

---

## Test Environments Covered (static review)

- Implementation read and analyzed on `sprint/05-stats-budget` branch
- `flutter analyze` executed on macOS (darwin 25.0.0) — clean
- `flutter test` executed — Sprint 5 scope: 97/97 pass
- Runtime testing on device/simulator not performed at this stage (static + automated only per agent capability)

---

## Re-QA — 2026-04-29 (Post-Fix Verification)

**Re-QA Tester:** qa-agent
**Re-QA Date:** 2026-04-29
**Commit verified:** 1731225 fix(sprint-5): fix QA blocker bugs (P1+P2)

### Bug Re-Verification Results

| Bug ID | Severity | Title | Verdict |
|--------|----------|-------|---------|
| BUG-010 | P1 | December boundary in BudgetEditModal | FIXED |
| BUG-005 | P2 | Pie segment tap — no navigation | FIXED |
| BUG-006 | P2 | Period selector W/M/Y not functional | FIXED |
| BUG-009 | P2 | NoteTransactionRow shows raw UUID | FIXED |

#### BUG-010 — December boundary fix (FIXED)

`budget_edit_modal.dart` line 119–123:

```dart
final effectiveTo = _onlyThisMonth
    ? (month.month == 12
        ? DateTime(month.year + 1, 1, 0) // Dec 31
        : DateTime(month.year, month.month + 1, 0))
    : null;
```

Guard `month.month == 12` is present. December path uses `DateTime(year+1, 1, 0)` which resolves to December 31. Non-December path uses `DateTime(year, month+1, 0)` which resolves to the last day of the current month. Both branches are correct.

#### BUG-005 — Pie segment tap navigation (FIXED)

`stats_provider.dart` lines 89–95: `StatsCategoryFilter` notifier is defined with a `set(String? categoryId)` method.

`stats_screen.dart` lines 484–494: `_navigateToCategory()` method is implemented. It calls `ref.read(statsCategoryFilterProvider.notifier).set(...)` to store the selected category and then calls `context.go(Routes.transactions)` to navigate to the Transactions tab. Both the notifier and the navigation call are present and wired correctly to `CategoryLegendRow.onTap`.

#### BUG-006 — Period selector W/M/Y (FIXED)

`stats_provider.dart` lines 62–80: `StatsPeriodMode` enum with `week`, `month`, `year` values is defined. `StatsPeriod` notifier (`statsPeriodProvider`) holds the selected mode with a `select()` mutator.

`stats_provider.dart` lines 103–138: `statsPeriodRange()` helper computes the correct date range for each mode. `statsTxns` provider now calls `getByDateRange(range.from, range.to)` instead of `getByMonth()`, so data correctly reflects the selected period.

`stats_screen.dart` lines 166–259: `_PeriodSelector` widget renders a bottom sheet via `showModalBottomSheet` with three `_PeriodOption` tiles (Week, Month, Year). Selecting an option calls `onChanged(mode)` which updates `statsPeriodProvider`. The period label in the button dynamically reflects the active mode (W/M/Y). Month navigator is hidden when `StatsPeriodMode.week` is active.

#### BUG-009 — NoteTransactionRow category display (FIXED)

`note_view.dart` lines 305–310:

```dart
final catsAsync = ref.watch(statsCategoryListProvider);
// ...
final cat = cats.where((c) => c.id == transaction.categoryId).firstOrNull;
// displays: '${cat.iconEmoji} ${cat.name}' or fallback '—'
```

`statsCategoryListProvider` is watched. The widget resolves `transaction.categoryId` to the matching `Category` object and displays `iconEmoji + name`. Raw UUID is no longer shown.

### Static Analysis — Post-Fix

- `flutter analyze --no-pub`: **No issues found** — PASS
- `flutter test` (Sprint 5 scope — `test/features/stats/`, `test/features/budget/`, `test/core/widgets/budget_progress_bar_test.dart`): **99 tests, all passed** — PASS (count increased from 97 to 99, confirming new tests were added for the fixed scenarios)

### FINAL VERDICT: PASS

All four required bug fixes are confirmed present in commit `1731225`. Static analysis is clean. Sprint 5 test suite passes completely. The sprint meets the re-QA conditions stated above and is approved for DevOps deployment to TestFlight and Play Internal Testing.
