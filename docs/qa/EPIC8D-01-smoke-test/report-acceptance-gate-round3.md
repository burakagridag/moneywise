# EPIC8D-01 QA Acceptance Gate — Round 3

**Branch:** sprint/8d-transactions-redesign
**Commit verified:** `5ee8e40`
**Date:** 2026-05-05
**QA Engineer:** qa-agent
**Round:** 3 (mockup parity fixes D1–D8, D11–D12)
**Prior gate:** `report-acceptance-gate.md` (Round 2, commit `119f9be`)

---

## Summary

Round 3 addressed sponsor-raised mockup parity divergences D1–D8, D11–D12 identified
after the Round 2 acceptance gate. All 14 original acceptance criteria were re-verified
against the Round 3 commit. All P1 and P2 divergence fixes were confirmed via source
inspection and the 13/13 integration smoke test re-run.

---

## 1. 14 Original Acceptance Criteria — Re-Verification

All criteria re-verified against commit `5ee8e40`.

| # | Criterion | Round 3 Status | Evidence |
|---|-----------|----------------|----------|
| 1 | Header: search + bookmark + filter icons present | PASS | Unchanged. AppBar `leading` (search), `actions` (bookmark_outline + tune) confirmed. |
| 2 | Tab bar: 3 tabs (Liste/Takvim/Özet), slate-blue underline indicator | PASS | `kTabCount = 3`, `indicatorColor: AppColors.brandPrimary` (#3D5A99) unchanged. |
| 3 | Summary strip: 3 columns (Income/Expense/Net), uses ARB keys | PASS | Strip uses `transactionsStripIncome/Expense/Net`. Net positive renders in `context.textPrimary`. No regression. |
| 4 | Liste tab: day-grouped cards with ADR-015 decoration, income green / expense red | PASS | `_DayCard` ADR-015 decoration unchanged. `context.incomeColor` / `context.expenseColor` in `TransactionRow` confirmed. |
| 5 | Takvim tab: 2-letter weekday header, no weekend coloring, cell indicators, today marker, day tap → Liste | PASS | ARB weekday keys unchanged. D7 three-way cell state logic confirmed. Empty-day onTap guard confirmed. |
| 6 | Özet tab: hero card (brand gradient), top categories section, week trend bars | PASS | Hero gradient constants unchanged. `_TopCategoriesSection` and `_WeekTrendSection` confirmed. |
| 7 | Empty state: renders WITHOUT tab bar | PASS | `TransactionsEmptyState` returned before `_PeriodTabBar` — no regression. |
| 8 | Income color: `AppColors.income = 0xFF047857`, `AppColors.incomeDark = 0xFF34D399` | PASS | `app_colors_ext.dart` adaptive accessor unchanged. |
| 9 | `context.incomeColor` used in transaction rows (dark-mode adaptive) | PASS | Used in `TransactionRow`, calendar cell, and hero footer dot (D1). |
| 10 | All 38 ARB keys present in app_en.arb and app_tr.arb | PASS | All keys present including new D3 key `transactionsSummaryCategoryPercent` and corrected D12 `transactionsSummarySingleCategoryHint`. |
| 11 | ICU pluralization on `transactionsSummarySingleCategoryHint` in EN | PASS | EN ARB: `"{n, plural, one{Only {n} category has spending} other{Only {n} categories have spending}}"`. |
| 12 | Card surface parity with Home + Budget screens (ADR-015) | PASS | `_TopCategoriesSection` and `_WeekTrendSection` use canonical ADR-015 decoration block. No regression. |
| 13 | `flutter analyze`: 0 issues | PASS | `No issues found!` post-commit `5ee8e40`. |
| 14 | `flutter test`: all passing | PASS | 845/845 PASS (4 net new tests vs 841 in Round 2). |

**Result: 14/14 PASS — no regressions introduced by Round 3 fixes.**

---

## 2. Round 3 Divergence Fix Verification

### D1 — Hero footer dots

**Expected:** Income green dot + expense red dot (8×8 circle) before their respective amounts in hero footer row.

**Verified:** `transactions_summary_tab.dart` — two `Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle))` widgets placed before income/expense footer text. Income dot uses `context.incomeColor`, expense dot uses `context.expenseColor`. Dark-mode adaptive.

**Result: PASS**

---

### D2 — Category bar color palette

**Expected:** Brand-blue 3-tier palette: rank 0 = `#3D5A99`, rank 1 = `#6B82B6`, rank 2+ = `#99AAD0`.

**Verified:** `transactions_summary_tab.dart` — constants:
- `_catBar1 = AppColors.brandPrimary` (`#3D5A99`)
- `_catBar2 = Color(0xFF6B82B6)`
- `_catBar3 = Color(0xFF99AAD0)`

Helper `_categoryBarColor(rank)` applies by 0-based index.

**Result: PASS**

---

### D3 — Category percent label

**Expected:** EN displays `"{pct}% of exp."`; TR displays `"gid. %{pct}"`.

**Verified:**
- `app_en.arb`: `"transactionsSummaryCategoryPercent": "{pct}% of exp."`
- `app_tr.arb`: `"transactionsSummaryCategoryPercent": "gid. %{pct}"`
- Widget calls `l10n.transactionsSummaryCategoryPercent(pct)` in `_TopCategoriesSection`.

**Result: PASS**

---

### D4 — Week trend stacked bars

**Expected:** Income (green) segment stacked on top of expense (red) per week column. Busiest week at full opacity; others at 55%.

**Verified:** `transactions_summary_tab.dart` — income `AnimatedContainer` rendered first in `Column` (top); expense `AnimatedContainer` rendered second (bottom). Both use `isBusiest ? color : color.withValues(alpha: 0.55)`.

**Result: PASS**

---

### D5 — Week label format

**Expected:** Week-start date as `d.M` (e.g. `4.5` for 4 May).

**Verified:** `transactions_summary_tab.dart` — `DateFormat('d.M').format(e.key)`. Locale-invariant numeric pattern.

**Result: PASS**

---

### D6 — Busiest week label styling

**Expected:** Busiest week label = `AppColors.brandPrimary` + `FontWeight.w700`. Others = `context.textSecondary` + `FontWeight.w400`.

**Verified:** `transactions_summary_tab.dart`:
```dart
color: isBusiest ? AppColors.brandPrimary : context.textSecondary,
fontWeight: isBusiest ? FontWeight.w700 : FontWeight.w400,
```

**Result: PASS**

---

### D7 — Calendar today/selected cell styling

**Expected:**
- today-only: `context.calendarHighlight` background + `AppColors.brandPrimary` bold day text
- selected (incl. today+selected): solid brand fill + white bold day text
- selected wins over today-only

**Verified:** `transactions_calendar_tab.dart` — three-way priority:
1. `effectiveSelected` → `cellBg = AppColors.brandPrimary`, white bold day number
2. `isToday && isCurrentMonth && !effectiveSelected` → `cellBg = context.calendarHighlight` (light/dark adaptive via `app_colors_ext.dart`), `AppColors.brandPrimary` bold day number
3. Otherwise → no special background

`app_colors_ext.dart` — `calendarHighlight` accessor returns `calendarHighlightLight` in light, `calendarHighlightDark` in dark.

**Result: PASS**

---

### D8 — Multi-amount calendar cell

**Expected:** Days with both income and expense show two separate compact-formatted text lines.

**Verified:** `transactions_calendar_tab.dart` — two independent `if` guards render income `Text` and expense `Text` sequentially in a `Column`. No code change was required — implementation was already correct.

**Result: PASS (no code change required)**

---

### D11 — TR date format (week range)

**Expected:** Busiest-week range header uses locale-appropriate month abbreviations (e.g. "4 Mayıs – 10 Mayıs").

**Verified:** `transactions_summary_tab.dart` — `DateFormat('MMM d', locale)` where `locale = Localizations.localeOf(context).languageCode`. Already locale-aware — no code change required.

**Result: PASS (no code change required)**

---

### D12 — EN pluralization wording

**Expected:** `n=1` → `"Only 1 category has spending"`; `n>1` → `"Only {n} categories have spending"`.

**Verified:** `app_en.arb`:
```
"{n, plural, one{Only {n} category has spending} other{Only {n} categories have spending}}"
```
Subject-verb agreement correct. TR uses a single non-plural form — acceptable for Turkish grammar.

**Result: PASS**

---

## 3. Divergence Fix Summary Table

| Div. | Title | Severity | Fix Applied | Result |
|------|-------|----------|-------------|--------|
| D1 | Hero footer dots | P2 | Colored 8×8 circle dots before income/expense amounts | PASS |
| D2 | Category bar color palette | P1 | Brand-blue 3-tier palette (#3D5A99 / #6B82B6 / #99AAD0) | PASS |
| D3 | Category percent label | P2 | New ARB key `transactionsSummaryCategoryPercent` | PASS |
| D4 | Week trend stacked bars | P1 | Two-segment stacked bar (income top green + expense bottom red) | PASS |
| D5 | Week label format | P1 | `DateFormat('d.M')` locale-invariant numeric format | PASS |
| D6 | Busiest week label style | P2 | `brandPrimary` + `w700` for busiest; `textSecondary` + `w400` for others | PASS |
| D7 | Calendar today/selected | P1 | Three-way cell state: highlight-bg (today) vs solid-fill (selected) | PASS |
| D8 | Multi-amount cell | P3 | No change needed — already correct | PASS |
| D11 | TR date format | P3 | No change needed — already locale-aware | PASS |
| D12 | EN pluralization wording | P2 | "has spending" (one) / "have spending" (other) corrected in ARB | PASS |

P1 divergences: 4/4 fixed and verified.
P2 divergences: 4/4 fixed and verified.
P3 divergences: 2/2 confirmed correct, no code change.

---

## 4. Test Results

| Suite | Result |
|-------|--------|
| `flutter analyze` | 0 issues |
| `flutter test` (unit + widget) | 845/845 PASS |
| Integration smoke (iPhone 16 Pro Max simulator) | 13/13 PASS |

Round 3 screenshots saved to:
`docs/qa/EPIC8D-01-smoke-test/screenshots/round3/`

---

## 5. Deferred Items (do not block merge)

| Item | Deferred To | Reason |
|------|-------------|--------|
| D9: Calendar day-detail card design | Sprint 8e | Sponsor deferred scope. |
| D10: Liste tab day-header total format | Sprint 8e | Sponsor deferred scope. |
| BUG-EPIC8D-01-002: ARB key naming (`transactionsCalendarTodayLabel` vs spec `transactionsCalendarTodayMarker`) | Pending sponsor decision | P3 cosmetic. Key unused in rendering. No functional impact. |

---

## 6. QA Final Sign-Off

| Item | Round 2 | Round 3 |
|------|---------|---------|
| `flutter analyze` | 0 issues | 0 issues |
| `flutter test` | 841/841 PASS | 845/845 PASS |
| Integration smoke | 13/13 PASS | 13/13 PASS |
| Acceptance criteria (AC 1–14) | 14/14 PASS | 14/14 PASS |
| P1 divergences | — | 4/4 FIXED |
| P2 divergences | — | 4/4 FIXED |
| P3 divergences (inspection, no change) | — | 2/2 confirmed |
| BUG-EPIC8D-01-002 (ARB key naming) | DEFERRED | DEFERRED |
| ADR-015 card parity | COMPLIANT | COMPLIANT |

**QA Verdict: READY FOR MERGE ✅**

All acceptance criteria pass. All P1 and P2 mockup parity divergences are fixed and
verified. No regressions introduced by Round 3. Deferred items (D9, D10,
BUG-EPIC8D-01-002) are tracked and do not block merge.

*QA Engineer: qa-agent | Date: 2026-05-05 | Commit: 5ee8e40*
