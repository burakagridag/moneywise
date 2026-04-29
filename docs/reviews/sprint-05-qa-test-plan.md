# Test Plan — Sprint 05: Stats Screen, Budget, and Note Views

**Stories:** US-026, US-027, US-028, US-029, US-030
**Created:** 2026-04-29
**Tester:** qa-agent
**Branch:** sprint/05-stats-budget

---

## Test Environments

- iOS 17.x on iPhone 15 Simulator
- iOS 16.x on iPhone 13 Simulator (N-1)
- Android 14 on Pixel 7 Emulator
- Android 13 on Pixel 6 Emulator (N-1)

---

## US-026 — StatsScreen: Pie Chart and Sub-tab Shell

### Scenario 26-01: Stats sub-tab is default on entry (iOS + Android)
**Steps:**
1. Launch app fresh (no prior Stats tab visit)
2. Tap the Stats bottom-tab icon

**Expected:** "Stats" sub-tab is active (underline indicator in brand color); "Budget" and "Note" sub-tabs are inactive (text secondary color); pie chart area is visible

---

### Scenario 26-02: Sub-tab switching
**Steps:**
1. On Stats tab, tap "Budget" sub-tab
2. Verify BudgetView renders
3. Tap "Note" sub-tab
4. Verify NoteView renders
5. Tap "Stats" sub-tab
6. Verify pie chart returns

**Expected:** Each tap changes the active indicator to the tapped tab; content area switches accordingly; no crash

---

### Scenario 26-03: Pie chart renders with expense categories (happy path)
**Preconditions:** At least 3 expense transactions in the current month
**Steps:**
1. Navigate to Stats tab (Stats sub-tab)
2. Ensure "Expense" toggle is active

**Expected:** Donut pie chart shows segments with distinct colors; legend list below chart shows emoji, category name, amount, percentage badge for each category; percentage badges sum to approximately 100%

---

### Scenario 26-04: Income toggle switches chart
**Steps:**
1. On Stats sub-tab, tap "Income" toggle
**Expected:** Pie chart re-renders with income categories; legend list updates; "Income" toggle underline becomes active

---

### Scenario 26-05: Month navigator — previous month
**Steps:**
1. Tap "<" arrow in Month/Year navigator
**Expected:** Navigator label changes to prior month; chart and legend re-render with prior month data; subsequent "<" taps continue retreating

---

### Scenario 26-06: Month navigator — next month guarded at current month
**Steps:**
1. Ensure current month is selected
2. Tap ">" arrow
**Expected:** Month does not advance past current month; navigator label remains unchanged

---

### Scenario 26-07: Empty state — no transactions for selected period
**Steps:**
1. Navigate back to a month with no transactions (e.g., Jan 2024)
**Expected:** No pie chart rendered; centered empty-state message "No data for this period" visible; no crash

---

### Scenario 26-08: Tapping a pie segment (current behavior)
**Steps:**
1. Tap a segment in the pie chart
**Expected:** A "Coming soon" snackbar appears (navigation to filtered DailyView is marked as deferred); no crash

*Note: AC requires navigation to DailyView — see BUG-005 in bug report.*

---

### Scenario 26-09: Period selector (W / M / Y)
**Steps:**
1. Tap "M ▼" period selector
**Expected:** A "Coming soon" snackbar is shown; period does not change

*Note: Period switching is behind a placeholder — see BUG-006.*

---

### Scenario 26-10: More than 8 expense categories — "Other" grouping
**Steps:**
1. Add 9+ distinct expense categories with transactions in the same month
**Expected:** Chart shows at most 8 named segments + an "Other" segment; no layout overflow

---

### Scenario 26-11: Light and Dark theme
**Steps:**
1. Toggle theme in More > Settings
2. Navigate to Stats tab
**Expected:** Chart segment colors remain readable on both backgrounds; legend text contrast is sufficient

---

## US-027 — Budget DB Layer (unit/integration tests only)

These scenarios are verified via automated tests, not manual UI steps.

### Scenario 27-01: Budget insert and watch stream
**Verify:** `budget_dao_test.dart` — inserting a row causes watchBudgetsForMonth stream to emit it

### Scenario 27-02: watchBudgetsForMonth time-bound filter
**Verify:** Budgets with effectiveTo before the queried month are excluded; open-ended budgets are included

### Scenario 27-03: getSpentAmount aggregates correctly
**Verify:** Only `type = 'expense'`, `is_excluded = 0`, `is_deleted = 0` transactions in the target month are summed

### Scenario 27-04: CarryOverBudgetUseCase — under budget (carryOver = 0)
**Verify:** `carry_over_budget_use_case_test.dart` — previous month spending < budget: carryOver = 0, effective = budget.amount

### Scenario 27-05: CarryOverBudgetUseCase — overspent (carryOver > 0, effective clamped)
**Verify:** overspend > 0: carryOver = overspend, effective = budget.amount - carryOver (>= 0)

### Scenario 27-06: CarryOverBudgetUseCase — no previous budget row (carryOver = 0)
**Verify:** When previous month has no budget row, carryOver = 0 regardless of spending

### Scenario 27-07: January — previous month is December
**Verify:** _previousMonth correctly returns December of prior year for January input

### Scenario 27-08: Hard delete removes row from stream
**Verify:** After deleteBudget, watchBudgetsForMonth no longer emits the deleted row

### Scenario 27-09: Schema migration from Sprint 4 (version 4 → 5)
**Verify:** budgets table created cleanly; no data loss in existing categories/transactions

---

## US-028 — BudgetView

### Scenario 28-01: Summary card with total budget configured (happy path iOS)
**Preconditions:** At least one category budget set for the current month; expenses entered
**Steps:**
1. Navigate to Stats tab → Budget sub-tab
**Expected:** Summary card shows "Remaining (Monthly)" label; a remaining amount displayed; progress bar with "Today" indicator; "Spent" and "Budget" amounts in footer; "Budget Setting >" link in header

### Scenario 28-02: Same as 28-01 on Android

### Scenario 28-03: Progress bar color thresholds
**Steps:**
1. Set up: category A budget 100, spent 50 (50% — brand color)
2. Set up: category B budget 100, spent 75 (75% — warning orange)
3. Set up: category C budget 100, spent 110 (110% — error red)
**Expected:** Each row's progress bar reflects the correct color; error row clamps bar at 100% width

### Scenario 28-04: Overspent category
**Expected:** Warning icon appears; amount in footer shown in error color; bar is full-width error color

### Scenario 28-05: Category with no budget set — no progress bar
**Steps:**
1. Ensure a category has spending but no budget
**Expected:** Category does not appear in BudgetView (only categories with configured budgets appear)

*Note: See BUG-001 for difference between AC expectation and actual behavior.*

### Scenario 28-06: Carry-over increases effective budget
**Steps:**
1. Set Food budget at 400 for March 2026; enter 310 spending
2. Set Food budget at 400 for April 2026 (carry-over always applied)
3. Navigate to BudgetView for April 2026
**Expected:** Effective budget shown as 490.00 (400 + 90 carry-over)

*Note: carryOverEnabled flag does not exist — carry-over is always applied — see BUG-002.*

### Scenario 28-07: "Budget Setting >" link navigation
**Steps:**
1. Tap "Budget Setting >" link in summary card header
**Expected:** BudgetSettingScreen opens at route /more/budget-setting

### Scenario 28-08: Empty state — no budgets at all
**Steps:**
1. Delete all budget entries
2. Navigate to Budget sub-tab
**Expected:** Centered empty-state with "No budgets set" title, subtitle, and "Set Up Budgets" button; button navigates to BudgetSettingScreen

### Scenario 28-09: "Today" indicator — first day of month
**Steps:**
1. Run test on the first day of a month (or mock date)
**Expected:** Indicator line at far left; no overflow

### Scenario 28-10: "Today" indicator — last day of month
**Expected:** Indicator line at far right; no overflow (clamped via Positioned left constraint)

---

## US-029 — BudgetSettingScreen

### Scenario 29-01: Reachable from More tab (iOS)
**Steps:**
1. Navigate to More tab
2. Tap "Budget Setting" row
**Expected:** BudgetSettingScreen opens; AppBar title is "Budget Setting"; back arrow visible; MonthNavigator shows current month

### Scenario 29-02: Same as 29-01 on Android (back button returns to More)

### Scenario 29-03: Reachable from BudgetView "Budget Setting >" link
**Steps:**
1. Navigate to Stats → Budget → tap "Budget Setting >"
**Expected:** BudgetSettingScreen opens

### Scenario 29-04: Category list shows all expense categories with current budgets
**Expected:** TOTAL row first (read-only, shows sum of per-category budgets); all expense categories listed with current budget amount or "€ 0,00"; each row has chevron ">"

### Scenario 29-05: TOTAL row is read-only
**Steps:**
1. Tap TOTAL row
**Expected:** Nothing happens (no modal opens); TOTAL row has no InkWell / tap handler

*Note: See BUG-003 — TOTAL row currently shows no tap response but also lacks explicit read-only semantics.*

### Scenario 29-06: Tapping category row opens BudgetEditModal
**Steps:**
1. Tap a category row (e.g., Food)
**Expected:** Bottom sheet slides up; title shows category emoji and name; amount field pre-filled with existing budget or empty; "Only this month" checkbox unchecked by default; Save and (if existing budget) Clear buttons visible

### Scenario 29-07: Save — all future months
**Steps:**
1. Open BudgetEditModal for Food, amount 400
2. Leave "Only this month" unchecked
3. Change to 350 and tap Save
**Expected:** Modal closes; Food row shows 350.00; upsertBudget called with effectiveTo = null

### Scenario 29-08: Save — only this month
**Steps:**
1. Open BudgetEditModal for Food
2. Check "Only this month"
3. Enter 250 and tap Save
**Expected:** Modal closes; Food shows 250 for current month; budget for next month reverts to previous value

### Scenario 29-09: Cancel discards changes
**Steps:**
1. Open BudgetEditModal for Food (400), change to 999, tap Cancel
**Expected:** Discard confirmation dialog appears (due to dirty state); if "Discard" selected, modal closes; Food row still shows 400; no DB write

### Scenario 29-10: Negative amount validation
**Steps:**
1. Open BudgetEditModal
2. Type "-50" (input formatter allows only digits and "."; "-" is filtered)
**Expected:** "-" character is not entered; Save remains disabled/error shown only if empty

*Note: See BUG-004 — input formatter prevents "-" but validation error text says "greater than zero" even for 0.00 which the AC says should be valid.*

### Scenario 29-11: Setting budget to 0.00 clears budget
**Steps:**
1. Open modal for Food with existing 400
2. Enter "0" and tap Save
**Expected:** Error "Amount must be greater than zero" shown; 0 is not saved

*Note: AC says 0.00 should be valid and "clears" the budget — but implementation rejects value <= 0. See BUG-004.*

### Scenario 29-12: Period W toggle
**Steps:**
1. Tap "M ▼" period selector
**Expected:** Coming-soon snackbar (same as Stats screen — period switching not yet implemented)

### Scenario 29-13: Income mode
**Steps:**
1. Look for Income/Expense toggle in BudgetSettingScreen
**Expected:** No Income/Expense toggle exists in BudgetSettingScreen — only expense categories shown

*Note: AC requires Income/Expense toggle in BudgetSettingScreen — not implemented. See BUG-007.*

### Scenario 29-14: Month navigation updates category list
**Steps:**
1. Navigate to prior month
**Expected:** Category budget amounts reflect that month's active budgets

---

## US-030 — NoteView

### Scenario 30-01: Note groups displayed with correct counts and amounts (iOS)
**Preconditions:** April 2026 expense transactions: "Gym" x2 = 59.98, "O2" x1 = 14.11, no-note x2 = 65.95
**Steps:**
1. Navigate to Stats → Note sub-tab
**Expected:** Header row with "Note" | sort icon | "Amount"; named groups: "Gym" (2) 59.98, "O2" (1) 14.11; "(no note)" group (2) 65.95 at the bottom

### Scenario 30-02: Same as 30-01 on Android

### Scenario 30-03: Default sort — amount descending, "(no note)" pinned last
**Expected:** Named groups sorted by totalAmount descending; "(no note)" always last regardless of amount

*Note: AC states "(no note)" appears at the TOP — implementation pins it LAST. See BUG-008.*

### Scenario 30-04: Sort toggle — count
**Steps:**
1. Tap sort icon in header
**Expected:** List re-orders to count descending (secondary: alphabetical by note); sort icon reflects new direction ("count" label); tap again to revert to amount

### Scenario 30-05: Tapping a note group row expands/collapses transaction detail
**Steps:**
1. Tap the "Gym" group row
**Expected:** Row expands (AnimatedSize) to show individual transactions; each row shows date, amount; swipe-to-delete available

*Note: AC says tapping opens a "detail view or bottom sheet" — implementation uses inline expand/collapse. This is an acceptable implementation variant.*

### Scenario 30-06: Income toggle filters note list
**Steps:**
1. Tap "Income" toggle (shared across all sub-tabs in StatsScreen)
**Expected:** NoteView re-renders with only income transactions grouped by note; amount color changes to income color (blue)

### Scenario 30-07: Month navigation updates note list
**Steps:**
1. Tap "<" in MonthNavigator
**Expected:** NoteView re-renders with prior month transaction notes

### Scenario 30-08: Empty state — no transactions in period
**Steps:**
1. Navigate to a month with no transactions
**Expected:** Centered empty-state icon (note_alt_outlined), "No notes" title, subtitle text; no list rows

### Scenario 30-09: Transactions without notes grouped as "(no note)"
**Expected:** Transactions with null or whitespace-only description are grouped under the "(no note)" italic row; whitespace trimming confirmed in provider code

### Scenario 30-10: Long note text — truncated with ellipsis
**Steps:**
1. Add a transaction with a 100-character note
**Expected:** Group header row shows text truncated (maxLines: 1, overflow: ellipsis)

### Scenario 30-11: Case-sensitive grouping
**Steps:**
1. Add transactions with notes "Gym" and "gym"
**Expected:** Two separate group rows appear

### Scenario 30-12: Swipe-to-delete transaction in expanded group
**Steps:**
1. Expand a note group; swipe left on a transaction row
**Expected:** Delete confirmation dialog appears; on confirm, transaction is deleted and group updates reactively

---

## Regression Checks (Sprint 4 features must not break)

- [ ] Transactions tab: add expense, income, transfer — balances update correctly
- [ ] Calendar view renders without crash
- [ ] More tab and Settings screen open correctly
- [ ] Category management screen accessible and functional
- [ ] App startup < 2 s on both platforms
- [ ] 60 FPS scroll on transaction list with 50+ entries
- [ ] Dark / Light theme toggle persists across app restart

---

## Sprint Goal Acceptance Criteria — Verification Checklist

| # | Sprint Goal Item | Scenario Covered | Expected |
|---|-----------------|-----------------|---------|
| 1 | Stats tab opens to Stats sub-tab by default | 26-01 | Pass |
| 2 | Three-sub-tab control visible and tappable | 26-02 | Pass |
| 3 | Period selector opens picker | 26-09 | Partial (snackbar placeholder) |
| 4 | Month/Year navigator retreats and advances | 26-05, 26-06 | Pass |
| 5 | Income/Expense toggle works across all sub-tabs | 26-04, 30-06 | Pass |
| 6 | Stats sub-tab: donut pie chart rendered | 26-03 | Pass |
| 7 | Stats sub-tab: tapping segment navigates | 26-08 | Fail (snackbar placeholder) |
| 8 | Stats sub-tab: empty state | 26-07 | Pass |
| 9 | Budget sub-tab: summary card | 28-01 | Pass |
| 10 | Budget sub-tab: "Budget Setting >" link | 28-07 | Pass |
| 11 | Budget sub-tab: progress bar threshold colors | 28-03 | Pass |
| 12 | Budget sub-tab: carry-over applied | 28-06 | Partial (always-on, no flag) |
| 13 | Note sub-tab: grouped by note, sorted | 30-01 | Pass with caveat (no-note position) |
| 14 | Note sub-tab: tapping row opens detail | 30-05 | Pass (inline expand) |
| 15 | BudgetSettingScreen reachable from More tab | 29-01 | Pass |
| 16 | BudgetSettingScreen: category list with TOTAL first | 29-04 | Pass |
| 17 | BudgetEditModal: save with/without "Only this month" | 29-07, 29-08 | Pass |
| 18 | Budget DB: migration adds budgets table cleanly | 27-09 | Pass |
| 19 | Carry-over: negative clamped to 0 | 27-05 | Pass |
| 20 | Monetary values: no float artifacts | 26-03, 28-01 | Pass |
| 21 | flutter analyze passes zero warnings | static | Pass |
| 22 | All unit/widget tests pass | automated | Partial (7 pre-existing encryption test failures unrelated to Sprint 5) |
