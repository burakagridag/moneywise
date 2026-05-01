# Story EPIC8A-06 — NetWorthCard (Total Balance + Sparkline)

**Assigned to:** Flutter Engineer
**Estimated effort:** 3 points
**Dependencies:** EPIC8A-03, EPIC8A-04, EPIC8A-UX
**Phase:** 2

## Description

Implement the `NetWorthCard` widget — the most prominent element on the Home tab. The card displays the user's total balance across all included accounts, a trend chip showing the change since last month, and a 30-day sparkline chart rendered with `fl_chart`.

The card has a gradient background (distinct values for light and dark mode per the epic spec). The balance is displayed in 30pt/600 tabular-numeral text. The trend chip shows `↑ 412 €` or `↓ 412 €` with a "since last month" label; it is hidden when the previous balance is zero or null. The sparkline is a smooth Bezier curve with a fill gradient below the line; it animates on first paint (300ms, easeInOutCubic). When `sparklineData` is empty, a flat horizontal line is shown without animation.

The label used is "Total Balance" (EN) / "Toplam Bakiye" (TR) — per Sponsor decision.

Data is sourced from `sparklineDataProvider` (ADR-012, `StreamProvider<List<DailyNet>>`) and an `accountsTotalProvider` (to be created in this story) that sums balances across accounts where `includeInTotals = true`. The `AsyncValue` loading state shows a shimmer placeholder; the error state shows a non-blocking inline error chip.

**V2 note:** The `accounts` prop is accepted but only rendered if `accounts.length > 1` — no sub-card UI is implemented. This is a clean V1 with the interface ready; no commented-out code.

## Inputs (agent must read)

- `docs/designs/home-tab/spec.md` — NetWorthCard section
- `docs/designs/home-tab/redlines.md` — gradient hex values, spacing, typography tokens
- `docs/designs/home-tab/mockup-light.html` and `mockup-dark.html`
- `docs/decisions/ADR-012-sparkline-data-flow.md` — full spec: `watchDailyNetAmounts`, `DailyNet`, gap-filling, `sparklineDataProvider`, fl_chart x-axis note
- `lib/data/local/daos/transaction_dao.dart` — `watchDailyTotals` pattern to follow; add `DailyNet` and `watchDailyNetAmounts` here
- `lib/features/accounts/` — account repository and entities for balance sum
- `lib/core/utils/currency_formatter.dart` — for balance display
- `lib/l10n/app_en.arb` and `app_tr.arb` — "Total Balance" / "Toplam Bakiye" keys
- `EPIC_home_tab_redesign_v2.md` Section "NetWorthCard" — exact component spec

## Outputs (agent must produce)

- `lib/data/local/daos/transaction_dao.dart` — `DailyNet` class and `watchDailyNetAmounts` method added (per ADR-012 exact signature and gap-filling algorithm)
- `lib/features/home/presentation/providers/sparkline_provider.dart` — `sparklineDataProvider` (`@riverpod Stream<List<DailyNet>>`) per ADR-012
- `lib/features/home/presentation/providers/net_worth_provider.dart` — `accountsTotalProvider` (current month total) and `previousMonthTotalProvider` (one-shot Future)
- `lib/features/home/presentation/widgets/net_worth_card.dart` — `NetWorthCard` widget
- `lib/features/home/presentation/screens/home_screen.dart` — NetWorthCard slot filled
- `lib/l10n/app_en.arb` — `homeTotalBalance` key ("Total Balance")
- `lib/l10n/app_tr.arb` — `homeTotalBalance` key ("Toplam Bakiye")
- `test/features/home/widgets/net_worth_card_test.dart` — widget tests (see Acceptance Criteria)
- `test/data/daos/transaction_dao_sparkline_test.dart` — unit tests for `watchDailyNetAmounts`
- `docs/prs/epic8a-06.md`

## Acceptance Criteria

- [ ] Label reads "Total Balance" in EN locale, "Toplam Bakiye" in TR locale
- [ ] Balance renders with correct currency symbol in 30pt tabular-numeral text
- [ ] Balance = 0 renders as `0,00 €` (not blank, not error)
- [ ] Trend chip hidden when `previousBalance` is null or 0
- [ ] Trend chip shows `↑` for positive delta, `↓` for negative delta, with correct EUR-formatted amount
- [ ] Sparkline renders exactly 30 data points; days with no transactions show `0.0`
- [ ] `watchDailyNetAmounts` with empty transaction table emits 30 `DailyNet` objects all with `netAmount = 0.0`
- [ ] Sparkline uses list index (0.0–29.0) as x-axis values, not epoch millis (per ADR-012)
- [ ] Transfer transactions are excluded from `watchDailyNetAmounts` calculations
- [ ] Accounts with `includeInTotals = false` are excluded from balance and sparkline
- [ ] Gradient background matches spec: light `#3D5A99 → #2E4A87`, dark `#4F46E5 → #3D5A99`, 135deg
- [ ] `AsyncValue.loading` shows shimmer placeholder; `AsyncValue.error` shows inline error chip (not full-screen error)
- [ ] Sparkline animates on first paint (300ms, easeInOutCubic); flat line when data is all zeros
- [ ] No V2 account sub-card UI rendered; `accounts` prop accepted silently
- [ ] All unit and widget tests pass; `flutter analyze` and `dart format` pass

## Out of Scope

- Account sub-cards (V2)
- Multi-currency net worth aggregation (V2 — ADR-010 addendum)
- Tapping the sparkline for a detailed chart (V2)
- `watchDailyNetAmounts` SQL aggregation optimisation (deferred per ADR-012)

## Quality Bar

The `watchDailyNetAmounts` unit tests must use a fixed `referenceDate` — never `DateTime.now()`. Tests must cover: empty DB, single income transaction, single expense transaction, one transfer (must be excluded), mixed 30-day window with gap days, and the integer-cent accumulation guard (two transactions same day must not produce float drift).
