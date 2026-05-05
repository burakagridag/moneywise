# EPIC8D-01 QA Acceptance Gate Report

**Branch:** sprint/8d-transactions-redesign
**Date:** 2026-05-05
**QA Engineer:** qa-agent
**Status:** PASS — Ready for PR and DevOps deploy

---

## Acceptance Criteria Results

| # | Criterion | Status | Notes |
|---|-----------|--------|-------|
| 1 | Header: search + bookmark + filter icons present | PASS | Search icon in AppBar `leading`, `bookmark_outline` + `tune` icons in `actions`. All wrapped in `Semantics` with ARB labels. |
| 2 | Tab bar: 3 tabs (Liste/Takvim/Özet), slate-blue underline indicator | PASS | `TabController(length: kTabCount)` where `kTabCount = 3`. `indicatorColor: AppColors.brandPrimary` (#3D5A99). `isScrollable: false`. Tab labels from `transactionsTabList/Calendar/Summary` ARB keys. |
| 3 | Summary strip: 3 columns (Income/Expense/Net) present and uses ARB keys | PASS | Strip renders correctly using `transactionsStripIncome/Expense/Net`. Positioned above `TabBarView` — visible on all 3 tabs. Net positive renders in `textPrimary` (neutral per SPEC-021 §4). |
| 4 | Liste tab: day-grouped cards with ADR-015 decoration, income green / expense red | PASS | `_DayCard` applies exact canonical ADR-015 pattern: `bgElevatedLight`/`bgSecondary`, `borderLight`/`border`, `BoxShadow(alpha:0.04, blurRadius:8, offset:Offset(0,2))` light-only. `context.incomeColor` / `context.expenseColor` used throughout `TransactionRow`. |
| 5 | Takvim tab: 2-letter weekday header, no weekend coloring, cell indicators, today marker, day tap → Liste | PASS | 2-letter weekdays confirmed (Mo/Tu/We/Th/Fr/Sa/Su EN; Pt/Sa/Ça/Pe/Cu/Ct/Pa TR). No weekend coloring confirmed. Amount indicators confirmed. Today marker = transparent-fill brand ring. Selected day = solid filled brandPrimary circle. Empty day tap is no-op. Day tap with transactions → switches to Liste tab. |
| 6 | Özet tab: hero card (brand gradient), top categories section, week trend bars | PASS | Hero card gradient (#3D5A99→#2E4A87 light, #4F46E5→#3D5A99 dark) confirmed. Week trend bars use net magnitude (income−expense) for height and busiest-week selection. Top categories with ADR-015 decoration confirmed. |
| 7 | Empty state: illustration + headline + subtitle + brand CTA, renders WITHOUT tab bar | PASS | `TransactionsEmptyState` returned before `_PeriodTabBar` is built in `TransactionsView`. Tab bar absent from widget tree. Brand-tinted circle icon, `transactionsEmptyTitle/Subtitle/CTA` ARB keys used. `FilledButton` with `AppColors.brandPrimary`. |
| 8 | Income color: `AppColors.income = 0xFF047857`, `AppColors.incomeDark = 0xFF34D399` | PASS | Confirmed in `app_colors.dart`. Source comment documents migration from legacy teal `0xFF2E86AB`. Both ADR-015 tokens present. |
| 9 | `context.incomeColor` used in transaction rows (dark-mode adaptive) | PASS | `app_colors_ext.dart` extension returns `incomeDark` in dark mode, `income` in light. Used in `TransactionRow._amountColor()`, `_DayHeaderRow`, `TransactionsSummaryStrip`, and calendar cell text. |
| 10 | All 38 ARB keys present in app_en.arb and app_tr.arb | PASS | All 38 EPIC8D-01 content keys present and consistent across EN/TR. P3 key naming note: `transactionsCalendarTodayLabel` (impl) vs `transactionsCalendarTodayMarker` (spec) — deferred to sponsor. |
| 11 | ICU pluralization on `transactionsSummarySingleCategoryHint` in EN | PASS | EN ARB: `"{n, plural, one{Only # category with spending} other{Only # categories with spending}}"`. TR uses non-plural form (acceptable for TR grammar). |
| 12 | Card surface parity with Home + Budget screens (ADR-015, Bulgu #6 prevention) | PASS | `_DayCard`, `_TopCategoriesSection`, and `_WeekTrendSection` all use canonical ADR-015 decoration block. Tokens match exactly. |
| 13 | `flutter analyze`: 0 issues | PASS | `No issues found! (ran in 5.6s)` |
| 14 | `flutter test`: all passing | PASS | 841/841 tests pass. |

---

## Edge Case Verification

| Edge Case | Status | Notes |
|-----------|--------|-------|
| Week trend bars show net (income − expense), not raw expense | PASS | Bar height uses `(income - expense).abs() / maxNet`. Busiest week selected by highest net magnitude. |
| Calendar selected day shows filled brand circle | PASS | `isSelected && isCurrentMonth` → solid `AppColors.brandPrimary` circle with white day number. |
| Empty state hides tab bar | PASS | `TransactionsView.build()` returns `TransactionsEmptyState()` before constructing `_PeriodTabBar`. |
| `tx.transactionType` enum used (not string `tx.type`) in category filtering | PASS | New EPIC8D-01 widgets use `tx.transactionType == TransactionType.expense/income`. |
| Net positive shown in text-primary (not income green) | PASS | `net < 0 ? context.expenseColor : context.textPrimary` in `TransactionsSummaryStrip`. |
| Empty day tap on Takvim is no-op | PASS | `onTap` only fires when `dayTotals.containsKey(key)`. |
| Today marker is transparent-fill ring (not filled circle) | PASS | `isToday && !isSelected` → `Colors.transparent` fill + `Border.all(brandPrimary, 1.5)` + brandPrimary text. |

---

## Test Results

- `flutter analyze`: 0 issues
- `flutter test`: 841/841 passing

---

## Bugs Found

### BUG-EPIC8D-01-001 — Today Marker Filled Instead of Ring
**Severity:** P2 | **Resolution:** FIXED in commit `119f9be`

`_CalendarDayCell.build()` fixed with 3-way if/else: `isSelected` → solid fill; `isToday && !isSelected` → transparent fill + 1.5px brand ring; otherwise → plain text.

---

### BUG-EPIC8D-01-002 — ARB Key Named `transactionsCalendarTodayLabel` vs Spec `transactionsCalendarTodayMarker`
**Severity:** P3 (cosmetic, no functional impact) | **Resolution:** DEFERRED — Sponsor to decide: rename key to match SPEC-021, or update spec to match implementation. Key is unused in any widget (today marker is visual-only, not text-based).

---

### BUG-EPIC8D-01-003 — Calendar Empty Day Tap Switches Tab
**Severity:** P2 | **Resolution:** FIXED in commit `119f9be`

`onTap` condition changed to `(entry.isCurrentMonth && dayTotals.containsKey(key))`. Empty days are non-interactive.

---

### BUG-EPIC8D-01-004 — Week Trend Bars Use Raw Expense Instead of Net
**Severity:** P1 | **Resolution:** FIXED in commit `119f9be`

Both bar height (`weekNet / maxNet`) and busiest-week selection (`max net magnitude`) updated to use `(income - expense).abs()`.

---

### BUG-EPIC8D-01-005 — Net Positive Strip Color Is Income Green Instead of Text-Primary
**Severity:** P2 | **Resolution:** FIXED in commit `119f9be`

Color expression changed to `net < 0 ? context.expenseColor : context.textPrimary` per SPEC-021 §4 "Total Positive: #1A1C24 — nötr siyah".

---

## Defect Summary

| Bug | Severity | Status |
|-----|----------|--------|
| BUG-EPIC8D-01-001: Today marker filled (not ring) | P2 | ✅ FIXED `119f9be` |
| BUG-EPIC8D-01-002: ARB key naming deviation | P3 | ⏳ DEFERRED (sponsor decision) |
| BUG-EPIC8D-01-003: Empty day tap switches tab | P2 | ✅ FIXED `119f9be` |
| BUG-EPIC8D-01-004: Week trend uses expense not net | P1 | ✅ FIXED `119f9be` |
| BUG-EPIC8D-01-005: Net positive color green not neutral | P2 | ✅ FIXED `119f9be` |

---

## QA Final Sign-Off

| Item | Result |
|------|--------|
| `flutter analyze` | 0 issues |
| `flutter test` | 841/841 PASS |
| All P1 bugs | ✅ FIXED |
| All P2 bugs | ✅ FIXED |
| P3 bug (key naming) | ⏳ DEFERRED to sponsor |
| Spec acceptance criteria | 14/14 PASS |
| Architecture (ADR-015) | COMPLIANT |

**QA Verdict: READY FOR PR AND DEVOPS DEPLOY ✅ YES**

*Date: 2026-05-05*
