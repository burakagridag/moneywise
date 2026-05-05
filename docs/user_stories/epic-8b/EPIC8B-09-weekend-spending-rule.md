# EPIC8B-09: WeekendSpendingRule — Mini-Spec

**Status: Sponsor approved — ready for Sprint 8c implementation**

**Sprint:** 8c
**Stable ID:** `'weekend_spending'`
**Severity:** `warning`
**Replaces stub:** `FifthRulePlaceholder`
**Status:** Sponsor approved 2026-05-07

---

## Overview

WeekendSpendingRule is the fifth insight rule in the InsightProvider pipeline. It detects months where the user's weekend daily spending average materially exceeds their weekday daily average — a pattern that often indicates impulse spending on leisure and dining that is invisible in monthly totals alone.

---

## Trigger Condition

Weekend (Saturday + Sunday) daily average exceeds weekday (Monday–Friday) daily average by more than the configured threshold in the current month.

```
weekendDailyAvg = totalWeekendSpend / weekendDayCount
weekdayDailyAvg = totalWeekdaySpend / weekdayDayCount

fires when: weekendDailyAvg > weekdayDailyAvg * threshold
```

**Proposed threshold: `2.0` (200%)** — weekend daily average is more than 2x the weekday daily average. ✅ Sponsor approved 2026-05-07

Rationale: A threshold of 1.5x fires frequently for normal weekend behavior (restaurant meals, leisure activities). A threshold of 2.5x fires only for extreme outliers. 2.0x targets genuinely unusual weekend-heavy patterns while keeping false-positive rates low.

---

## Suppression Guards

The rule returns `null` (no card emitted) under any of the following conditions:

| # | Condition | Rationale |
|---|-----------|-----------|
| 1 | `totalMonthlyIncome == 0` | No income data — same guard applied by SavingsGoalRule |
| 2 | `weekendDayCount < 2` | Fewer than 2 weekend days elapsed; need at least one full weekend for a meaningful signal |
| 3 | `weekdayDayCount < 3` | Fewer than 3 weekday days elapsed; ratio is noisy on days 1–2 of the month |
| 4 | `weekdayDailyAvg <= 0` | No weekday spending recorded; division guard |
| 5 | `weekendDailyAvg <= weekdayDailyAvg * threshold` | Condition not met; no card |

---

## Wording

| Field | English | Turkish |
|-------|---------|---------|
| Headline | `"Weekend spending high"` | `"Hafta sonu harcaması yüksek"` |
| Body | `"Weekend {pct}% above weekday."` | `"Hafta sonu hafta içinden %{pct} yüksek."` |

`pct` = `((weekendDailyAvg / weekdayDailyAvg) - 1) * 100`, rounded to nearest integer.

Example: weekendDailyAvg = 180, weekdayDailyAvg = 60 → `pct = 200` → "Weekend 200% above weekday."

**Body wording revised 2026-05-07 (Sponsor-approved):** Shortened to fit InsightCard `maxLines=1` constraint.
Original approved body was `"Weekend daily average {pct}% above weekday."` / `"Hafta sonu ortalaması hafta içinden %{pct} yüksek."` — truncated at high pct values (e.g. %338 → 49 chars). Revised to stay under ~40 chars at any pct value.

ARB keys to add: `insightWeekendSpendingTitle`, `insightWeekendSpendingBody` (EN + TR).

---

## InsightContext Additions Required

Four new computed properties on `InsightContext` (no schema changes, no provider changes):

| Property | Type | Description |
|----------|------|-------------|
| `weekendDailyAvg` | `double` | Total expense spend on Sat/Sun days elapsed this month ÷ `weekendDayCount` |
| `weekdayDailyAvg` | `double` | Total expense spend on Mon–Fri days elapsed this month ÷ `weekdayDayCount` |
| `weekendDayCount` | `int` | Count of Sat/Sun calendar days elapsed in current month up to `referenceDate` |
| `weekdayDayCount` | `int` | Count of Mon–Fri calendar days elapsed in current month up to `referenceDate` |

Filters applied to all four: expense transactions only, non-excluded, non-deleted, within current month, partitioned by `referenceDate` day-of-week using the device locale calendar.

---

## Effort Estimate

**2pt (S–M)**

- `InsightContext` additions: 4 computed properties
- `WeekendSpendingRule` implementation: ~30 lines
- Unit tests: 8–10 cases (threshold boundary, each suppression guard, pct rounding)
- Mapper localization: `insightWeekendSpendingTitle` + `insightWeekendSpendingBody`
- ARB keys: EN + TR (4 strings total)
- No schema changes. No provider changes beyond `InsightContext`.

---

## Open Questions for Sponsor

1. **Threshold** — Proposed `2.0` (200%). Approve, or adjust? Lower (1.5) = more sensitive, fires on normal weekends. Higher (2.5) = fires only in extreme cases.
2. **Wording** — Headline and body copy above: approve as-is, or revise?
3. **Income exclusion** — Should income transactions be excluded from the weekend/weekday averages? Recommended: yes (expense transactions only, consistent with all other rules). ✅ Sponsor approved 2026-05-07

---

## Sponsor Sign-off

| Decision | Options | Sponsor Choice |
|----------|---------|----------------|
| Threshold | 1.5 / **2.0** / 2.5 / other | 2.0 ✅ Sponsor approved 2026-05-07 |
| Wording (EN) | Approve as-is / Revise | Approve as-is ✅ Sponsor approved 2026-05-07 |
| Wording (TR) | Approve as-is / Revise | Revised — "Hafta sonu ortalaması hafta içinden %{pct} yüksek." ✅ Sponsor approved 2026-05-07 |
| Income exclusion | **Yes — expense only** (recommended) / No — all transactions | Yes — expense only ✅ Sponsor approved 2026-05-07 |

**Approved by:** burakagridag@gmail.com **Date:** 2026-05-07
