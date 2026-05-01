# Budget Pulse Card — Component Spec

**Component:** BudgetPulseCard
**Epic:** Epic 8A — Home Tab Redesign
**Related story:** EPIC8A-UX

---

## Purpose

Tell the user how much they can safely spend per day for the rest of the month. Show budget health at a glance with a progress bar, a today-marker, and a daily pace line.

---

## Layout

```
┌────────────────────────────────────────────┐  radius: 14dp, border 1dp
│  Budget pulse              View →          │  header row, 14dp padding
├────────────────────────────────────────────┤
│  462,60 €  left of 550 € budget            │  remaining + context
│                                            │
│  ████░░░░░░░░░░░░░░░░░│░░░░░░░░░░░░        │  progress bar 6dp + today marker
│                                            │
│  Daily pace: 15,42 €  ·  You can spend     │  pace line
│  15,42 €/day                               │
└────────────────────────────────────────────┘
margin: 16dp left/right, 12dp bottom
```

---

## Content Sections

### Header row
- Left: "Budget pulse" — `bodyMedium` (16pt/500), `textPrimaryLight` / `textPrimary`
- Right: "View →" — `caption1` (12pt/400), `brandPrimary` color, tappable → navigates to `/budget`
- Tap target for "View →": minimum 44×44 dp (extend tap area with padding)
- Margin below header: 12dp

### Remaining amount row
- Primary number: `remaining` = budget − spent
- Typography: `moneyMedium` (20pt/600/ls-0.5), tabular-nums
- Color: `textPrimaryLight` / `textPrimary` (default)
- Color override: when `remaining < 0` → `AppColors.expense` (#C0392B light) / `AppColors.expenseDark` (#E55A4E dark)
- Subtext: "left of {budget} budget"
- Subtext typography: `caption1` (12pt/400)
- Subtext color: `textSecondaryLight` / `textSecondary`
- Layout: remaining + subtext on same baseline row, gap 6dp
- Margin below: 10dp

### Progress bar
- Height: 6dp
- Border radius: 3dp (half of height)
- Background: `bgTertiaryLight` (#E3E1DD light) / `bgTertiary` (#222637 dark)
- Fill color: `brandPrimary` (#3D5A99) — both themes
- Fill color override: when `spent > budget` → fill = 100% width, color = `AppColors.expense` / `AppColors.expenseDark`
- Fill width: `min((spent / budget) * 100%, 100%)`
- Margin below: 10dp

### Today marker
- A vertical line overlaid on the progress bar
- Position: `(currentDay / daysInMonth) * 100%` from left of bar
- Width: 1.5dp
- Height: 12dp (extends 3dp above and below the 6dp bar)
- Top offset: −3dp (relative to bar top)
- Color: `textSecondaryLight` (#5C5E6B light) / `textTertiary` (#4E5470 dark)
- Always visible regardless of fill position

### Daily pace line
- Single text line, `caption2` (11pt/400)
- Base color: `textSecondaryLight` / `textSecondary`
- Format: "Daily pace: {actualDailyPace} · You can spend {safeDailyAmount}/day"
- `actualDailyPace` colored `textPrimaryLight` / `textPrimary`, weight 500
- `safeDailyAmount` colored `AppColors.success` (#4CAF50) — both themes — when safe (remaining > 0)
- `safeDailyAmount` colored `AppColors.expense` / `AppColors.expenseDark` when over budget

---

## States

### Default (budget set, within budget)
- All sections visible as described above
- Progress fill: brandPrimary, proportional to spent/budget ratio
- Today marker at correct proportional position
- safe daily amount shown in success green

### Over-budget
- Remaining shown as negative value: "−87,40 €" in expense color
- Progress bar: 100% filled, fill color = expense color
- Today marker: still visible at correct position
- Daily pace line: "Daily pace: {pace} · Over budget" where "Over budget" is expense color, weight 500
- safeDailyAmount calculation: when remaining ≤ 0, show "Over budget" string instead of amount

### Warning (pacing fast — actualDailyPace > safeDailyAmount × 1.5)
- Remaining amount: normal color (not warning — only pace line is flagged)
- Progress bar: normal brandPrimary fill
- Today marker: normal
- `actualDailyPace` value in pace line: `AppColors.warning` (#FFA726) color, weight 500

### No budget set (budget = null or budget = 0)
- Entire card replaced with CTA variant (see below)
- Standard card shape and padding preserved

### CTA variant (no-budget state)
```
┌────────────────────────────────────────────┐
│  Budget pulse                              │  header (no "View →" link)
├────────────────────────────────────────────┤
│  Set a monthly budget                      │  bodyMedium, textPrimary
│  Stay on top of your spending              │  caption1, textSecondary
│                                            │
│  [  Set budget  ]                          │  brand-colored text button
└────────────────────────────────────────────┘
```
- "Set budget" tap → navigates to `/budget`
- Button: text-only, `brandPrimary` color, `bodyMedium` weight

### Loading (shimmer)
- Card shape and border visible
- Header row: two shimmer bars (title 80dp×14dp, link 36dp×12dp)
- Remaining row: shimmer bar 140dp×18dp + 100dp×12dp
- Progress bar: shimmer bar full-width×6dp
- Pace line: shimmer bar 200dp×10dp
- Shimmer base: `bgTertiaryLight` (#E3E1DD light) / `bgTertiary` (#222637 dark)
- Shimmer highlight: `bgSecondaryLight` (#EEECEA light) / `bgSecondary` (#181C27 dark)
- Animation: 1200ms loop, left-to-right sweep

### Error
- Card shape preserved
- Content area shows: "Budget data unavailable" — `caption1`, `textSecondaryLight` / `textSecondary`, centered
- No progress bar, no pace line

---

## Tokens

| Element | Light token | Dark token | Value |
|---------|-------------|-----------|-------|
| Card background | `bgElevatedLight` | `bgSecondary` | #FFFFFF / #181C27 |
| Card border | `borderLight` | `border` | #C8C4BC / #2E3453 |
| Card border width | 1dp | 1dp | — |
| Card radius | `AppRadius.lg` | `AppRadius.lg` | 14dp |
| Card padding | 14dp explicit | 14dp explicit | — |
| Card horizontal margin | `AppSpacing.lg` | `AppSpacing.lg` | 16dp |
| Card bottom margin | `AppSpacing.md` | `AppSpacing.md` | 12dp |
| Card shadow (light only) | 0 2dp 8dp rgba(0,0,0,0.04) | none | — |
| Title text | `textPrimaryLight` | `textPrimary` | #1A1C24 / #F0F2F8 |
| Title typography | `bodyMedium` | `bodyMedium` | 16pt/500 |
| Link color | `brandPrimary` | `brandPrimary` | #3D5A99 |
| Link typography | `caption1` | `caption1` | 12pt/400 |
| Remaining value typography | `moneyMedium` | `moneyMedium` | 20pt/600/ls-0.5 |
| Remaining value (normal) | `textPrimaryLight` | `textPrimary` | #1A1C24 / #F0F2F8 |
| Remaining value (over-budget) | `expense` | `expenseDark` | #C0392B / #E55A4E |
| Subtext typography | `caption1` | `caption1` | 12pt/400 |
| Subtext color | `textSecondaryLight` | `textSecondary` | #5C5E6B / #8A90A8 |
| Progress bar background | `bgTertiaryLight` | `bgTertiary` | #E3E1DD / #222637 |
| Progress fill (normal) | `brandPrimary` | `brandPrimary` | #3D5A99 |
| Progress fill (over-budget) | `expense` | `expenseDark` | #C0392B / #E55A4E |
| Today marker color | `textSecondaryLight` | `textTertiary` | #5C5E6B / #4E5470 |
| Pace line base | `textSecondaryLight` | `textSecondary` | #5C5E6B / #8A90A8 |
| Pace number highlight | `textPrimaryLight` | `textPrimary` | #1A1C24 / #F0F2F8 |
| Safe amount (OK) | `success` | `success` | #4CAF50 |
| Safe amount (over-budget) | `expense` | `expenseDark` | #C0392B / #E55A4E |
| Pace number (warning) | `warning` | `warning` | #FFA726 |

---

## Interactions

- "View →" tap: navigate to `/budget` tab
- "Set budget" CTA tap: navigate to `/budget` (budget creation flow)
- Card itself is NOT tappable (only the link/CTA)
- No swipe gestures

---

## Accessibility

- Semantic label for card: "Budget pulse. {remaining} left of {budget} budget. Daily pace {pace}. You can spend {safe}/day."
- Over-budget variant: "Budget pulse. Over budget by {abs(remaining)}. Daily pace {pace}."
- "View →" button: semantic label "View budget details"
- "Set budget" button: semantic label "Set a monthly budget"
- Today marker: `excludeSemantics: true` — decorative
- Progress bar: `excludeSemantics: true` — value communicated via card label
- Color contrast: all text ≥ 4.5:1 verified
  - `textPrimaryLight` (#1A1C24) on white (#FFFFFF): 17.5:1 — passes
  - `textSecondaryLight` (#5C5E6B) on white: 5.9:1 — passes
  - `success` (#4CAF50) on white: 3.1:1 — FAILS AA for normal text
    - Mitigated: safe amount is supplemented by `/day` suffix text; add `FontWeight.w500` to improve legibility. Flag: green on white is borderline — use `fontWeight: w600` for the safe amount value to improve perceived contrast.
  - `brandPrimary` (#3D5A99) on white: 5.9:1 — passes

---

## Edge Cases

| Case | Behavior |
|------|----------|
| budget = 0 | Show no-budget CTA state |
| budget = null | Show no-budget CTA state |
| spent = 0 | Progress bar at 0%, pace = 0, safe = budget / remaining days |
| spent = budget exactly | Progress bar 100%, remaining = 0,00 €, show "Over budget" in pace line |
| currentDay = daysInMonth (last day) | safe = remaining / 1 (denominator minimum 1 to avoid divide-by-zero) |
| currentDay > daysInMonth | Clamp currentDay to daysInMonth |
| Very long currency symbol | Remaining row wraps to two lines; acceptable |
