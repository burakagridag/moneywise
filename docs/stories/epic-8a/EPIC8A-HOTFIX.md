# Epic 8a Hotfix Stories — EPIC8A-HF01 through EPIC8A-HF05

**Source:** Product Sponsor visual review, Phase 2 demo session (2026-05-01)
**Total estimate:** 5 points (1 point each)
**Phase:** 2.5 — must be completed and merged before Phase 3 begins
**Assigned to:** Flutter Engineer (implementation), UX Designer (acceptance sign-off on mockup comparisons where noted)

> These hotfixes address visual defects identified by the Sponsor during the Phase 2 demo.
> All five items are blocking Phase 3 start. No new Phase 3 story may begin until
> EPIC8A-HF01 through EPIC8A-HF05 are merged and accepted.

---

## EPIC8A-HF01: TotalBalanceCard Typography Hierarchy

### Description
The "TOTAL BALANCE" label renders too heavy and the balance number is oversized, creating
a flat visual hierarchy. The Sponsor identified this as a polish regression from the
reference mockup.

### Fix Details
- **Label ("TOTAL BALANCE"):** 11pt, weight 400, opacity 0.7, letter-spacing 0.5px, uppercase
- **Balance amount:** 30pt, weight 600 — strictly weight 600; do NOT use 600+ or 700
- No other typography tokens on this card may change as part of this fix

### Acceptance Criteria

```gherkin
Scenario: TotalBalanceCard label renders at correct weight and size
  Given the Home tab is visible
  And TotalBalanceCard is rendered with a non-zero balance
  When I inspect the "TOTAL BALANCE" label
  Then the label font size is 11pt
  And the label font weight is 400
  And the label opacity is 0.7
  And the label letter-spacing is 0.5px
  And the label is uppercase

Scenario: Balance amount renders at correct weight and size
  Given the Home tab is visible
  And TotalBalanceCard is rendered with a non-zero balance
  When I inspect the balance amount text
  Then the font size is 30pt
  And the font weight is exactly 600 (not 700, not 650)

Scenario: PR contains side-by-side mockup comparison
  Given the pull request for EPIC8A-HF01 is open
  When I review the PR description
  Then it contains a side-by-side screenshot: reference mockup vs implementation
  And both iOS and Android screenshots are present
```

### Out of Scope
- Changes to any other card's typography
- Changes to the balance amount color or currency symbol styling
- Dark/light mode color changes (handled separately in EPIC8A-HF05 if applicable)

### Estimate
1 point

---

## EPIC8A-HF02: Sparkline Data Pattern + Gradient Fill

### Description
The demo sparkline displays extreme day-to-day volatility that does not reflect realistic
net worth growth, and the gradient fill area below the curve is absent. Both issues
diminish the perceived quality of the card.

### Fix Details
- **Demo data pattern:** Replace current demo data with a smooth net worth growth curve
  using 7–8 control points. Daily variation must not exceed ±2–3% between adjacent points.
  The overall trend should be gently upward to represent realistic net worth growth.
- **Gradient fill:** Apply a gradient fill below the curve using `fl_chart`'s
  `belowBarData` with `AreaTouch` / `BarAreaData`. Start color: rgba(255, 255, 255, 0.10);
  end color: fully transparent. The gradient must be visible against both light and dark
  card backgrounds.
- The `belowBarData` area must be visible in the rendered widget — not hidden, clipped,
  or set to zero opacity.

### Acceptance Criteria

```gherkin
Scenario: Sparkline demo data shows smooth growth pattern
  Given the Home tab is visible
  And TotalBalanceCard is in demo / empty-accounts state
  When I observe the sparkline curve
  Then the curve has 7 or 8 data points
  And no single adjacent-point variation exceeds ±3%
  And the overall direction of the curve trends upward

Scenario: Gradient fill is visible below the sparkline curve
  Given the Home tab is visible
  And TotalBalanceCard is rendered (demo or real data)
  When I observe the area below the sparkline curve
  Then a gradient fill is visible
  And the fill fades from semi-transparent white (opacity ~0.10) at the curve
  And the fill fades to fully transparent at the bottom of the chart area
  And the gradient is visible in both light and dark mode

Scenario: Visual quality matches sparkline reference mockup
  Given the pull request for EPIC8A-HF02 is open
  When I review the PR description
  Then it contains a screenshot comparison against the UX reference mockup
  And the gradient and data smoothness are visually consistent with the reference
```

### Out of Scope
- Changes to real transaction data aggregation logic (sparkline_provider.dart)
- Changing the sparkline line color or stroke width
- Animating the gradient fill (static fill only)

### Estimate
1 point

---

## EPIC8A-HF03: BudgetPulseCard Today Marker

### Description
The progress bar on BudgetPulseCard has no indicator showing the current day's position
within the month. Without this marker users cannot visually compare actual spend pace
against expected pace at today's date.

### Fix Details
- **Position:** Vertical line placed at `(currentDay / daysInMonth) * 100%` along the
  progress bar's horizontal axis
- **Color:** Use `textSecondary` token in light mode; use `textTertiary` token in dark mode
- **Dimensions:** Width 1.5 logical pixels; height extends 3 logical pixels above the top
  edge of the progress bar and 3 logical pixels below the bottom edge
- The marker must be rendered on top of the progress bar (not behind it)

### Acceptance Criteria

```gherkin
Scenario: Today marker appears on BudgetPulseCard progress bar
  Given the Home tab is visible
  And BudgetPulseCard is rendered in within-budget state
  When I observe the progress bar
  Then a vertical line is visible on the progress bar
  And its horizontal position equals (currentDay / daysInMonth) * the bar's total width

Scenario: Today marker uses correct color tokens per theme
  Given BudgetPulseCard is visible in light mode
  When I inspect the today marker color
  Then it uses the textSecondary design token

  Given BudgetPulseCard is visible in dark mode
  When I inspect the today marker color
  Then it uses the textTertiary design token

Scenario: Today marker dimensions are correct
  Given BudgetPulseCard is visible
  When I inspect the today marker
  Then its stroke width is 1.5 logical pixels
  And it extends 3 logical pixels above the progress bar's top edge
  And it extends 3 logical pixels below the progress bar's bottom edge

Scenario: Today marker is visible on day 1 and day 28+
  Given today is the 1st day of the month
  When I observe the progress bar
  Then the today marker appears near the left edge of the bar

  Given today is the last day of the month
  When I observe the progress bar
  Then the today marker appears near the right edge of the bar
```

### Out of Scope
- Over-budget state styling of the today marker (same tokens apply regardless of budget state)
- Tooltip or tap interaction on the today marker
- Animation of the marker position

### Estimate
1 point

---

## EPIC8A-HF04: TotalBalanceCard Empty State — Flat Sparkline

### Description
When total balance is 0.00 the sparkline area is absent, leaving approximately 70% of
the card as an empty gradient. The Sponsor selected Option B: render a flat sparkline at
low opacity so the card's layout remains stable and no layout shift occurs when the
first transaction is added.

### Fix Details
- When all account balances sum to 0.00 (or no accounts exist), render the sparkline
  widget with a flat horizontal line at the vertical midpoint of the chart area
- Apply very low opacity to the flat line (Sponsor preference: visually recessive,
  exact value left to Flutter Engineer's discretion within range 0.15–0.25)
- The sparkline container dimensions must be identical to the non-empty state — no
  layout shift when transitioning from 0.00 to first non-zero balance
- Do NOT show a "No data" text label or placeholder copy inside the sparkline area

### Acceptance Criteria

```gherkin
Scenario: Flat sparkline visible when balance is 0.00
  Given the Home tab is visible
  And all accounts have a balance of 0.00 EUR (or no accounts exist)
  When I observe TotalBalanceCard
  Then a flat horizontal line is visible in the sparkline area
  And the line is visually recessive (low opacity, 0.15–0.25 range)
  And no "No data" or empty-state copy is shown inside the sparkline area

Scenario: No layout shift when first transaction is added
  Given TotalBalanceCard displays a 0.00 balance with flat sparkline
  When I add an income transaction of any amount
  Then the sparkline area height and width remain identical
  And the flat line transitions to the real sparkline data without reflow

Scenario: Sparkline container height is consistent across states
  Given TotalBalanceCard in empty state (0.00 balance)
  When I measure the sparkline container height
  Then it matches the sparkline container height in a non-empty state
```

### Out of Scope
- Changing the card's gradient background in the empty state
- Animating the transition from flat to real sparkline data
- Showing account creation CTAs inside the sparkline area (onboarding cards handle that — EPIC8A-10)

### Estimate
1 point

---

## EPIC8A-HF05: InsightCard Text Hierarchy

### Description
InsightCard subtitle text competes visually with the title, making both feel equal weight.
In dark mode the contrast difference is negligible. The fix enforces clear primary /
secondary hierarchy using design tokens rather than ad-hoc colors.

### Fix Details
- **Title:** Color token `textPrimary`, font size 14pt, font weight 500
- **Subtitle:** Color token `textSecondary`, font size 12pt, font weight 400
- Both light and dark mode must resolve to clearly differentiated visual levels — subtitle
  must read as clearly subordinate to the title
- Do not hard-code hex or ARGB values; use the existing design token references from
  `lib/core/constants/app_colors.dart` and `app_typography.dart`

### Acceptance Criteria

```gherkin
Scenario: InsightCard title uses correct typography in light mode
  Given InsightCard is visible in light mode
  When I inspect the title text
  Then the color is textPrimary token
  And the font size is 14pt
  And the font weight is 500

Scenario: InsightCard subtitle uses correct typography in light mode
  Given InsightCard is visible in light mode
  When I inspect the subtitle text
  Then the color is textSecondary token
  And the font size is 12pt
  And the font weight is 400

Scenario: InsightCard subtitle is clearly secondary in dark mode
  Given InsightCard is visible in dark mode
  When I visually compare the title and subtitle
  Then the subtitle is clearly less prominent than the title
  And the subtitle uses the textSecondary token (not textPrimary or a hard-coded color)

Scenario: No hard-coded color values used
  Given the InsightCard implementation
  When I review the widget source
  Then title and subtitle colors reference named design tokens only
  And no hex or ARGB literals appear for these text styles
```

### Out of Scope
- Changes to InsightCard icon color or size
- Changes to the card background or border in dark mode
- Modifying any other card's text hierarchy as part of this fix

### Estimate
1 point

---

## Hotfix Summary

| ID | Component | Issue | Fix | Points | Blocks Phase 3? |
|----|-----------|-------|-----|--------|-----------------|
| EPIC8A-HF01 | TotalBalanceCard | Typography too heavy | Label 11pt/400/0.7 opacity; balance 30pt/600 | 1 | Yes |
| EPIC8A-HF02 | Sparkline | Volatility + missing gradient fill | Smooth 7-8pt demo data; belowBarData gradient | 1 | Yes |
| EPIC8A-HF03 | BudgetPulseCard | No today marker on progress bar | Vertical line at currentDay/daysInMonth position | 1 | Yes |
| EPIC8A-HF04 | TotalBalanceCard | Empty state 70% blank | Flat sparkline at low opacity (Option B) | 1 | Yes |
| EPIC8A-HF05 | InsightCard | Subtitle competes with title in dark mode | Title 14pt/500/textPrimary; subtitle 12pt/400/textSecondary | 1 | Yes |
| **Total** | | | | **5** | |

> All five hotfixes must be merged to the sprint branch before Phase 3 stories
> (EPIC8A-10, EPIC8A-11, EPIC8A-12) may begin engineering work.
