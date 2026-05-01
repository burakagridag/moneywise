# Recent Transactions — Component Spec

**Component:** RecentTransactionsList
**Epic:** Epic 8A — Home Tab Redesign
**Related story:** EPIC8A-UX

---

## Purpose

Give the user quick visual confirmation of the last two transactions without navigating away from Home. NOT a full list — max 2 rows always. The "All →" link handles overflow.

---

## Layout

```
RECENT                                  All →    ← section header row
┌────────────────────────────────────────────┐
│  ┌──────┐  Rent                 −500,00 €  │  row 1, 56dp height
│  │ icon │                                  │
│  └──────┘─────────────────────────────────   ← inset divider starts at 54dp
│  ┌──────┐  Salary            +1.000,00 €  │  row 2, 56dp height
│  │ icon │                                  │
└────────────────────────────────────────────┘
margin: 0 16dp
```

---

## Section Header

- Layout: Row, space-between, vertically centered
- Left: "RECENT" — uppercase string, `caption2` (11pt/400/ls0.4), `textSecondaryLight` / `textSecondary`
- Right: "All →" — `caption1` (12pt/400), `brandPrimary` color, tappable
- Margin: 18dp top, 10dp bottom, 16dp horizontal
- "All →" tap target: minimum 44×44 dp (extend padding inward)
- "All →" action: `onSeeAllTap` callback → navigates to `/transactions`

---

## List Container

- Background: `bgElevatedLight` (#FFFFFF light) / `bgSecondary` (#181C27 dark)
- Border: 1dp, `borderLight` / `border`
- Border radius: `AppRadius.lg` (14dp)
- Overflow: hidden (so rows don't bleed outside radius)
- Shadow (light only): 0 2dp 8dp rgba(0,0,0,0.04)
- Horizontal margin: `AppSpacing.lg` (16dp)
- No bottom margin (last item in scroll; parent adds padding)

---

## Transaction Row

Each row renders one transaction. Maximum 2 rows rendered.

### Row layout
- Height: `AppHeights.listItem` (60dp) — matches existing list item height constant
- Padding: 12dp vertical, 14dp horizontal
- Layout: icon container | flex text | amount, all horizontally, vertically centered

### Category icon container
- Size: 32×32 dp
- Border radius: `AppRadius.sm` (6dp) — matches reference mockup square shape
- Background: category-specific tint color (passed in from transaction data)
- Icon: 16×16 dp SVG, category-specific stroke color
- The icon and background colors come from the existing category color system — RecentTransactionsList does NOT define them

### Text section
- Flex: 1, min-width 0
- Transaction name: `AppTypography.bodyMedium` (16pt/500), `textPrimaryLight` / `textPrimary`, 1 line ellipsis
- No subtext in this compact variant (date/account shown in full TransactionRow — omitted here)

### Amount
- Typography: `AppTypography.moneySmall` (17pt/600/ls0.0) with tabular figures
- Income (positive): `AppColors.income` (#2E86AB) — both themes
- Expense (negative): `AppColors.expense` (#C0392B light) / `AppColors.expenseDark` (#E55A4E dark)
- Transfer: `AppColors.transfer` (#7B8DB0) — both themes
- Prefix: `+` for income, `−` for expense (use minus sign U+2212, not hyphen), no prefix for transfer
- Always show 2 decimal places, locale-aware formatting (e.g., `+1.000,00 €`)

### Inset divider
- Between row 1 and row 2 only (not after last row)
- Height: 1dp
- Color: `bgTertiaryLight` (#E3E1DD light) / `divider` (#1E2235 dark)
- Left inset: 54dp (aligns with text column start: 14dp padding + 32dp icon + 8dp gap)
- Right edge: flush with card right padding end (no right inset)

### Row tap
- Full row tappable: `InkWell` with ripple
- Ripple color: `AppColors.brandPrimaryGlow`
- Action: open existing transaction detail bottom sheet
- Tap target: full 60dp row height satisfies minimum

---

## Spacing Detail

```
[14dp] [32dp icon] [8dp gap] [flex name] [8dp gap] [amount] [14dp]
```

Gap between icon and name: 8dp (`AppSpacing.sm`) — note this differs from InsightCard's 12dp gap. RecentTransactionsList is more compact.

---

## States

### Default (1–2 transactions)
- Render 1 or 2 rows as described
- 1 row: no divider, no empty second row
- 2 rows: inset divider between them

### Default (0 transactions)
- Section is hidden entirely — no header, no container
- Empty state is handled by the parent HomeScreen's EmptyState section
- RecentTransactionsList renders nothing (`return SizedBox.shrink()`)

### Loading (shimmer)
- Section header: shimmer bars for "RECENT" (50dp×10dp) and "All →" (28dp×10dp)
- Container: card shape visible, two shimmer rows inside
  - Each shimmer row: icon square (32×32, radius 6dp) + name bar (120dp×14dp) + amount bar (70dp×14dp)
  - Inset divider between rows: shimmer 1dp bar
- Shimmer colors: `bgTertiaryLight` / `bgTertiary` base, `bgSecondaryLight` / `bgSecondary` highlight

### Error
- Section header visible
- Container shows single centered text: "Could not load transactions" — `caption1`, `textSecondaryLight` / `textSecondary`
- No retry button (pull-to-refresh on parent HomeScreen handles retry)

---

## Tokens

| Element | Light | Dark |
|---------|-------|------|
| Container background | `bgElevatedLight` (#FFFFFF) | `bgSecondary` (#181C27) |
| Container border | `borderLight` (#C8C4BC) | `border` (#2E3453) |
| Container radius | `AppRadius.lg` (14dp) | `AppRadius.lg` (14dp) |
| Container shadow | 0 2dp 8dp rgba(0,0,0,0.04) | none |
| Section header left | `textSecondaryLight` | `textSecondary` |
| Section header right (link) | `brandPrimary` | `brandPrimary` |
| Row height | `AppHeights.listItem` (60dp) | `AppHeights.listItem` (60dp) |
| Icon container size | 32×32dp | 32×32dp |
| Icon container radius | `AppRadius.sm` (6dp) | `AppRadius.sm` (6dp) |
| Icon size | 16×16dp | 16×16dp |
| Name typography | `bodyMedium` (16pt/500) | `bodyMedium` (16pt/500) |
| Name color | `textPrimaryLight` | `textPrimary` |
| Amount typography | `moneySmall` (17pt/600) | `moneySmall` (17pt/600) |
| Amount income | `income` (#2E86AB) | `income` (#2E86AB) |
| Amount expense light | `expense` (#C0392B) | `expenseDark` (#E55A4E) |
| Amount transfer | `transfer` (#7B8DB0) | `transfer` (#7B8DB0) |
| Divider color | `bgTertiaryLight` (#E3E1DD) | `divider` (#1E2235) |
| Divider left inset | 54dp | 54dp |
| Horizontal margin | `AppSpacing.lg` (16dp) | `AppSpacing.lg` (16dp) |

---

## Interactions

- "All →" tap → `onSeeAllTap()` → navigate to `/transactions`
- Row tap → open transaction detail bottom sheet (existing `TransactionDetailSheet`)
- No swipe-to-delete in this compact Home view (full swipe-to-delete exists in `/transactions`)
- No long-press action

---

## Accessibility

- Section container semantic label: "Recent transactions. {count} shown."
- "All →" link: semantic label "View all transactions", `button: true`
- Each row: semantic label "{name}. {signed amount}. {type}." e.g. "Rent. Minus 500 euros. Expense. Tap for details."
- Divider: `excludeSemantics: true`
- Icon containers: `excludeSemantics: true` — decorative
- Focus order: section header → "All" link → row 1 → row 2

---

## Reuse Note

The epic spec mentions reusing `TransactionRow` with a `compact: true` prop if it exists. Check `lib/features/transactions/presentation/widgets/transaction_row.dart` before implementing a new widget. If `TransactionRow` supports a compact variant, use it and pass `compact: true`. If not, create `RecentTransactionRow` as a new widget local to the home feature — do not modify the existing `TransactionRow`.

---

## Edge Cases

| Case | Behavior |
|------|----------|
| 0 transactions | Hide entire section (SizedBox.shrink) |
| 1 transaction | Show 1 row, no divider |
| 3+ transactions passed in | Render only first 2 (most recent first) |
| Transaction name empty | Show category name as fallback |
| Amount = 0 | Show "0,00 €" with no prefix, income color |
| Very long transaction name | 1 line, ellipsis, amount never truncated |
| Amount > 6 digits | moneySmall at 17pt will fit up to ~8 digits + symbol on 375px at 16dp margins |
