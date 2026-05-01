# Total Balance Card — Component Spec

**Component:** TotalBalanceCard (formerly NetWorthCard — renamed per Sponsor decision)
**Epic:** Epic 8A — Home Tab Redesign
**Related story:** EPIC8A-UX

---

## Purpose

Surface the user's single most important number — their total balance across all accounts — at a glance. Secondary: communicate 30-day trend and trajectory via sparkline.

---

## Layout

```
┌────────────────────────────────────────────────┐  radius: 20dp
│  TOTAL BALANCE                          18dp p │  label: caption2, 70% white
│                                                │
│  8.450,00 €                                    │  balance: moneyLarge (32pt/700)
│                                                │
│  [↑ 412,60 €]  since last month               │  trend chip + label
│                                                │
│  ╌╌╌╌╌╌╌╮╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╯╌╌╌╌╌╌╌╌╌╌╌╌      │  sparkline SVG 36dp tall
└────────────────────────────────────────────────┘
margin: 16dp left/right, 12dp bottom
```

---

## Visual Design

### Gradient background
- Light mode: `linear-gradient(135deg, #3D5A99 0%, #2E4A87 100%)`
  - Start: `AppColors.brandPrimary` (#3D5A99)
  - End: `AppColors.brandPrimaryDim` (#2E4A87)
- Dark mode: `linear-gradient(135deg, #4F46E5 0%, #3D5A99 100%)`
  - Start: #4F46E5 (indigo — not in AppColors; see note below)
  - End: `AppColors.brandPrimary` (#3D5A99)

> Dark mode gradient start (#4F46E5) is not a named AppColors token. It is specified by the epic spec as approved by Sponsor. Flutter Engineer should define it as a local constant inside the widget file: `static const Color _darkGradientStart = Color(0xFF4F46E5);`. No new AppColors entry is required; this is widget-local.

### Card shape
- Border radius: 20dp (`AppRadius.xl`)
- No border, no shadow (gradient card is self-elevated)
- Padding: 18dp all sides (closest token: `AppSpacing.xl` = 20dp — use explicit 18dp)
- Horizontal margin: 16dp (`AppSpacing.lg`)
- Bottom margin: 12dp (`AppSpacing.md`)

---

## Content Sections (top to bottom)

### 1. Label row
- Text: "TOTAL BALANCE"
- Typography: `caption2` (11pt/400/ls0.4)
- Color: `rgba(255,255,255,0.70)` — white at 70% opacity
- Margin below: 6dp

### 2. Balance value
- Content: formatted currency string (e.g., `8.450,00 €`)
- Typography: `moneyLarge` (32pt/700/ls -1.0) with `font-variant-numeric: tabular-nums`
- Color: `AppColors.textOnBrand` (#FFFFFF)
- Margin below: 8dp

### 3. Trend row
- Visible only when `previousBalance` is non-null and non-zero
- Layout: chip + label text, horizontal, gap 6dp, vertical center aligned

**Trend chip:**
- Background: `rgba(255,255,255,0.18)`
- Border radius: `AppRadius.pill` (999dp)
- Padding: 3dp vertical, 10dp horizontal
- Text: arrow + formatted delta, e.g. `↑ 412,60 €` or `↓ 412,60 €`
- Typography: `caption2` (11pt/500)
- Color: white
- Arrow: `↑` when delta positive, `↓` when delta negative

**Trend label:**
- Text: "since last month"
- Typography: `caption1` (12pt/400)
- Color: `rgba(255,255,255,0.85)`

### 4. Sparkline
- Container height: 36dp
- Width: 100% of card interior (fills between paddings)
- Margin top: 12dp
- SVG path simulating 30-day balance history (smooth Bezier)
- Stroke: `rgba(255,255,255,0.50)`, stroke-width 1.5
- Fill area below curve: `rgba(255,255,255,0.10)` fading to `rgba(255,255,255,0.00)` via linear gradient (top to bottom)
- No axes, no labels, no grid lines
- Flutter implementation: `fl_chart` LineChart with `isCurved: true`, no `titlesData`, `gridData` disabled
- Animation: draw-on from left, 300ms, `easeInOutCubic` curve, on first paint only

---

## States

### Default (data loaded, balance > 0)
- All sections visible
- Trend chip visible if delta available
- Sparkline shows real data path

### Default (balance = 0)
- Label: "TOTAL BALANCE"
- Balance: `0,00 €`
- Trend chip: hidden (no previous balance comparison)
- Sparkline: flat horizontal line at vertical center of container
- No animation on flat line

### Default (balance negative)
- Balance value shown in full with minus sign: e.g., `−1.200,00 €`
- Color remains white (no red override — on gradient background, semantic color is inappropriate)
- Trend chip: shown normally (delta color not applicable — chip is always white on gradient)

### Loading (shimmer)
- Card gradient background is shown (so the card shape is visible)
- Label area: shimmer bar 80dp × 10dp, `rgba(255,255,255,0.15)` base, `rgba(255,255,255,0.25)` highlight
- Balance area: shimmer bar 180dp × 28dp, same opacity range
- Trend row: shimmer bar 120dp × 14dp
- Sparkline area: shimmer bar full-width × 36dp
- Shimmer animates left-to-right, 1200ms loop

### Error
- Card gradient background preserved
- Balance replaced with: "— €" in white
- Trend chip hidden
- Sparkline area hidden
- No error icon (card is not an interactive error state — parent screen handles retry)

---

## Interactions

- Card itself is NOT tappable in V1 (no onTap)
- Sparkline is NOT tappable in V1
- V2 note: tapping card will navigate to account breakdown detail screen

---

## Accessibility

- Semantic label for entire card: "Total balance: {formattedBalance}. {trendDescription}"
  - trendDescription when chip visible: "Up {delta} since last month" or "Down {delta} since last month"
  - trendDescription when chip hidden: "" (empty)
- Sparkline: `excludeSemantics: true` — decorative only
- Trend chip: included in parent card semantic label; do not announce separately
- Color contrast: all text is white on dark blue gradient. Contrast ratio: white (#FFFFFF) on #3D5A99 = 5.9:1 — passes WCAG AA

---

## Edge Cases

| Case | Behavior |
|------|----------|
| `previousBalance` = null | Hide trend chip entirely |
| `previousBalance` = 0 | Hide trend chip (division would be meaningless) |
| `sparklineData` empty or length < 2 | Show flat horizontal line, no animation |
| `sparklineData` all same value | Show flat horizontal line |
| Balance > 999,999 | Typography remains same; number wraps if needed (unlikely at 32pt on 375px — 7 digits + symbol fits) |
| Very large negative balance | Same as above with minus prefix |
| Currency symbol long (e.g., "TRY") | Flows after number; may push to two lines — acceptable |
