# Sprint 05 — Bug Report

**Branch:** sprint/05-stats-budget
**Date:** 2026-04-29
**Tester:** qa-agent

---

## BUG-001: BudgetView does not show categories without a configured budget

**Severity:** P2
**Story:** US-028
**File:** `lib/features/budget/presentation/widgets/budget_view.dart` line 63–127

**AC Text:**
> "Category with no budget configured appears in list without a progress bar"

**Reproduction Steps:**
1. Add an expense of 89.14 for "Transport" category
2. Do NOT set a budget for "Transport"
3. Navigate to Stats → Budget sub-tab

**Expected:** "Transport" appears in the category list with its spent amount (89.14) and no progress bar

**Actual:** "Transport" does not appear in the list at all. `budgetsForMonthProvider` only emits categories that have a budget row in the DB. The `_BudgetContent` widget iterates only over `budgets` (configured budgets), so unconfigured categories are invisible.

**Impact:** Users cannot see overspending in categories they forgot to budget for.

---

## BUG-002: `carryOverEnabled` flag not implemented — carry-over is unconditional

**Severity:** P2
**Story:** US-027, US-028
**Files:**
- `lib/data/local/tables/budgets_table.dart` (missing `carryOverEnabled` column)
- `lib/features/budget/domain/budget_entity.dart` (missing field)
- `lib/features/budget/domain/use_cases/carry_over_budget.dart` (ignores flag)

**AC Text (US-027):**
> "CarryOverBudget does not carry over when previous month overspent" — the AC describes a `carryOverEnabled` property on the budget; (US-028): "carryOverEnabled = true for Food"

**Reproduction Steps:**
1. Set Food budget 400 for March with NO explicit carry-over setting
2. Spend 430 in March (overspent)
3. Navigate to BudgetView for April

**Expected:** Carry-over behavior should only apply when `carryOverEnabled = true`; user should be able to disable it per category

**Actual:** Carry-over is applied unconditionally to every budget. The `CarryOverBudgetUseCase` has no `carryOverEnabled` check. The `BudgetEntity` has no such field. The Drift `Budgets` table has no `carry_over_enabled` column.

**Note:** The sprint-05 goal states carry-over is "applied when carryOverEnabled = true" — this boolean was described as a DB field in US-027 but is absent from the schema. The UI settings for toggling it are deferred to Sprint 6 per `sprint_05.md` "Out of Scope." This is a design gap: the DB layer lacks the column, making Sprint 6 implementation require a schema migration. Severity is P2 (carry-over works, just not user-controllable yet).

---

## BUG-003: TOTAL row in BudgetSettingScreen is a derived sum, not the US-027 stored TOTAL budget

**Severity:** P2
**Story:** US-027, US-029
**File:** `lib/features/more/presentation/screens/budget_setting_screen.dart` lines 169–211

**AC Text (US-027):**
> "BudgetDAO supports a TOTAL budget (categoryId = null) — the row is stored with categoryId null and BudgetRepository.watchTotalBudget emits the new row"

**AC Text (US-029):**
> "Setting TOTAL budget (first row) configures the overall monthly limit — BudgetRepository stores a row with categoryId = null"

**Reproduction Steps:**
1. Navigate to More → Budget Setting
2. Observe the TOTAL row
3. Tap the TOTAL row

**Expected:** Tapping TOTAL opens BudgetEditModal allowing the user to set an overall monthly spending cap (stored as a `categoryId = null` row in the DB)

**Actual:** The TOTAL row is read-only and shows a derived sum of all per-category budgets. The `_TotalRow` widget has no `InkWell`/`onTap`. The `BudgetRepository` has no `watchTotalBudget` method. The `Budgets` table schema requires `categoryId` to be a non-null foreign key — a `null` value would fail the FK constraint.

**Impact:** The concept of a separate "overall monthly cap" stored in DB (AC from US-027/029) is not implemented. The sprint goal item "TOTAL row is always first" is satisfied, but the TOTAL is computed rather than stored — making the BudgetView summary card reflect the sum of per-category budgets rather than an independent cap.

---

## BUG-004: Saving a budget of 0.00 is rejected — contradicts US-029 AC

**Severity:** P2
**Story:** US-029
**File:** `lib/features/more/presentation/widgets/budget_edit_modal.dart` line 98

**AC Text:**
> "Setting a budget of 0.00 clears the budget for that category — BudgetView no longer shows a progress bar for Food"

**Reproduction Steps:**
1. Open BudgetSettingScreen
2. Tap Food (existing budget 400)
3. Clear the amount field and enter "0"
4. Tap Save

**Expected:** Budget saved as 0.00; Food disappears from BudgetView progress bars

**Actual:** Validation at line 98 (`value == null || value <= 0`) rejects 0.00 with the error "Amount must be greater than zero". The user cannot save a zero budget; the only way to remove a budget is the "Clear budget" destructive action (delete row).

**Note:** The "Clear budget" button does achieve the same end result by deleting the row, so the functional outcome is achievable — but the AC-specified path (enter 0.00 → Save) fails. Severity P2 because workaround exists.

---

## BUG-005: Tapping a pie segment does not navigate to filtered DailyView

**Severity:** P2
**Story:** US-026
**File:** `lib/features/stats/presentation/screens/stats_screen.dart` line 337–339

**AC Text:**
> "Tapping a pie segment navigates to DailyView filtered to that category's transactions for the selected month"

**Sprint Goal:**
> "Stats sub-tab: tapping a pie segment navigates to DailyView filtered by that category"

**Reproduction Steps:**
1. Navigate to Stats tab (Stats sub-tab)
2. Tap any colored segment in the pie chart

**Expected:** App navigates to a transaction list filtered by the tapped category and selected month

**Actual:** A "Coming soon" snackbar is displayed. Navigation is not implemented.

**Note:** The pie chart segments themselves (`PieChartWidget`) have no tap handler — taps on the legend rows in `_StatsContent` show the snackbar. The `PieChartData` does not set `pieTouchData`. Segment tap navigation is fully absent.

---

## BUG-006: Period selector (W / M / Y) is not functional

**Severity:** P2
**Story:** US-026, US-028, US-029, US-030
**File:** `lib/features/stats/presentation/screens/stats_screen.dart` lines 143–145

**AC Text (multiple stories):**
> "Period selector switches between W / M / Y — selecting one updates the Month/Year navigator and all sub-tab data"

**Sprint Goal:**
> "Period selector ('M ▼') opens a picker with W / M / Y options; selecting one updates the Month/Year navigator and all sub-tab data"

**Reproduction Steps:**
1. Navigate to Stats tab
2. Tap "M ▼" period selector button

**Expected:** A picker/dropdown opens with W, M, Y options; selecting one switches the navigator mode and re-aggregates all data

**Actual:** A "Coming soon" snackbar is displayed. The period selector is a static label and the only functional navigator is Monthly.

**Note:** BudgetSettingScreen also shows only a MonthNavigator with no period picker.

---

## BUG-007: BudgetSettingScreen lacks Income/Expense toggle

**Severity:** P2
**Story:** US-029
**File:** `lib/features/more/presentation/screens/budget_setting_screen.dart`

**AC Text:**
> "Income mode shows income categories instead — the category list shows income categories (Salary, Bonus, Allowance, etc.)"

**Reproduction Steps:**
1. Open More → Budget Setting

**Expected:** An "Income / Exp." toggle is visible; tapping "Income" shows income categories with their budget amounts

**Actual:** No Income/Expense toggle exists in BudgetSettingScreen. The screen always shows expense categories only (`expenseCats` filter is hardcoded).

---

## BUG-008: "(no note)" group is pinned LAST — AC specifies it should be FIRST

**Severity:** P3
**Story:** US-030
**File:** `lib/features/stats/presentation/providers/note_provider.dart` line 100

**AC Text:**
> "transactions with empty notes are grouped in a single '(no note)' row at the top"

**Reproduction Steps:**
1. Add expenses: "Gym" (29.99 x2), no-note (65.95) in same month
2. Navigate to Stats → Note sub-tab

**Expected:** "(no note)" row appears at the top of the list (highest total amount or pinned)

**Actual:** "(no note)" group is always pinned at the BOTTOM. Code at line 100: `return [...namedGroups, ...noNoteGroup];`

**Note:** The AC says "at the top" but one could argue the "(no note)" group should be sorted normally by amount (which may place it at the top in the test data). The implementation makes it always last, which is the opposite of the AC. Severity P3 because it is a cosmetic ordering issue, not a data correctness issue.

---

## BUG-009: `NoteTransactionRow` shows `categoryId` (raw ID string) instead of category name

**Severity:** P2
**Story:** US-030
**File:** `lib/features/stats/presentation/widgets/note_view.dart` line 390

**AC Text (expand detail):**
> "The detail shows date, category, account, and amount for each transaction"

**Reproduction Steps:**
1. Navigate to Stats → Note sub-tab
2. Tap a note group row to expand it
3. Observe the transaction rows

**Expected:** Each expanded transaction row shows the human-readable category name (e.g., "Restaurant") and account name

**Actual:** The primary text in `_NoteTransactionRow` displays `transaction.categoryId` (a raw UUID string like `cat-001`) — not the category name. The account name is not shown. Category lookup against the category list is not performed in this widget.

---

## BUG-010: December boundary in `BudgetEditModal._save()` — `month + 1` unchecked

**Severity:** P1
**Story:** US-029
**File:** `lib/features/more/presentation/widgets/budget_edit_modal.dart` lines 118–123

**Reproduction Steps:**
1. Set the MonthNavigator to December of any year (e.g., Dec 2026)
2. Open BudgetEditModal for any category
3. Check "Only this month"
4. Enter an amount and tap Save

**Expected:** `effectiveTo` is set to the last day of December (Dec 31)

**Actual:** `effectiveTo` is computed as:
```dart
DateTime(
  widget.selectedMonth.year,
  widget.selectedMonth.month + 1,  // 12 + 1 = 13
  0,
)
```
In Dart, `DateTime(2026, 13, 0)` overflows to `DateTime(2026, 12, 31)` via Dart's normalization — so this actually produces the correct value accidentally. However, this relies on undocumented overflow behavior. It is not a runtime bug in current Dart but is a code quality defect. Severity P1 is assigned because it is a latent correctness risk that could behave differently if Dart's behavior changes, and the pattern is inconsistent with the correctly guarded `month == 12` checks elsewhere in the codebase (e.g., `budget_dao.dart` line 91–93).

**Recommended Fix:**
```dart
final effectiveTo = _onlyThisMonth
    ? DateTime(
        widget.selectedMonth.month == 12
            ? widget.selectedMonth.year + 1
            : widget.selectedMonth.year,
        widget.selectedMonth.month == 12 ? 1 : widget.selectedMonth.month + 1,
        0,
      )
    : null;
```

---

## BUG-011: Soft delete not implemented in Budget DB layer — only hard delete exists

**Severity:** P2
**Story:** US-027
**File:** `lib/data/local/daos/budget_dao.dart` line 80–81

**AC Text:**
> "Soft delete removes a budget without affecting historical reports — the row's isDeleted flag is set to true; BudgetDAO.watchAll no longer emits that row"

**Actual:** `deleteBudget` performs a hard DELETE (`delete(budgets)..where(...).go()`). There is no `isDeleted` column in the `Budgets` table. Historical reports referencing a deleted budget row will find no row (not just a hidden row). The distinction matters if the AC expects soft-delete semantics (row preserved for audit/history).

**Note:** The `getSpentAmount` SQL query references `is_deleted = 0` on the `transactions` table (not budgets) — the budgets table never had `is_deleted`. This is a spec-vs-implementation gap. Severity P2 since functional behavior (remove from list) is achieved via hard delete.

---

## Summary Table

| Bug ID | Severity | Title |
|--------|----------|-------|
| BUG-001 | P2 | BudgetView hides categories without a budget |
| BUG-002 | P2 | carryOverEnabled flag not in DB schema — carry-over is unconditional |
| BUG-003 | P2 | TOTAL row is derived sum, not a stored DB row (categoryId=null) |
| BUG-004 | P2 | Saving 0.00 rejected — AC says it should clear the budget |
| BUG-005 | P2 | Pie segment tap shows snackbar instead of navigating to DailyView |
| BUG-006 | P2 | Period selector (W/M/Y) is not functional |
| BUG-007 | P2 | BudgetSettingScreen lacks Income/Expense toggle |
| BUG-008 | P3 | "(no note)" group pinned LAST — AC says it should be FIRST |
| BUG-009 | P2 | NoteTransactionRow shows raw categoryId UUID instead of category name |
| BUG-010 | P1 | December boundary in BudgetEditModal uses unchecked month + 1 |
| BUG-011 | P2 | Budget soft-delete not implemented; hard delete only |
