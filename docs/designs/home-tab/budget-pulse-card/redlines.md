# Budget Pulse Card — Engineer Redlines

**Reads:** `spec.md`, `tokens.json`
**Target widget:** `lib/features/home/presentation/widgets/budget_pulse_card.dart`

---

## Dimension Map

| Visual element | Value | Token / constant |
|----------------|-------|-----------------|
| Card border radius | 14dp | `AppRadius.lg` |
| Card border width | 1dp | explicit 1 |
| Card padding (all sides) | 14dp | explicit 14 (between AppSpacing.md=12 and AppSpacing.lg=16) |
| Card horizontal margin | 16dp | `AppSpacing.lg` |
| Card bottom margin | 12dp | `AppSpacing.md` |
| Header row → remaining row gap | 12dp | `AppSpacing.md` |
| Remaining row → progress gap | 10dp | explicit 10 |
| Progress bar → pace line gap | 10dp | explicit 10 |
| Remaining number → subtext gap | 6dp | `AppSpacing.xs + 2` → explicit 6 |
| Progress bar height | 6dp | explicit 6 |
| Progress bar border radius | 3dp | explicit 3 |
| Today marker width | 1.5dp | explicit 1.5 |
| Today marker height | 12dp | explicit 12 |
| Today marker vertical offset | −3dp | explicit -3 (positioned above bar) |

---

## Color Map

| Element | Light | Dark |
|---------|-------|------|
| Card background | `AppColors.bgElevatedLight` (#FFFFFF) | `AppColors.bgSecondary` (#181C27) |
| Card border | `AppColors.borderLight` (#C8C4BC) | `AppColors.border` (#2E3453) |
| Title text | `AppColors.textPrimaryLight` | `AppColors.textPrimary` |
| "View →" link | `AppColors.brandPrimary` | `AppColors.brandPrimary` |
| Remaining (normal) | `AppColors.textPrimaryLight` | `AppColors.textPrimary` |
| Remaining (over-budget) | `AppColors.expense` | `AppColors.expenseDark` |
| Subtext | `AppColors.textSecondaryLight` | `AppColors.textSecondary` |
| Progress background | `AppColors.bgTertiaryLight` | `AppColors.bgTertiary` |
| Progress fill (normal) | `AppColors.brandPrimary` | `AppColors.brandPrimary` |
| Progress fill (over-budget) | `AppColors.expense` | `AppColors.expenseDark` |
| Today marker | `AppColors.textSecondaryLight` | `AppColors.textTertiary` |
| Pace base text | `AppColors.textSecondaryLight` | `AppColors.textSecondary` |
| Pace number emphasis | `AppColors.textPrimaryLight` | `AppColors.textPrimary` |
| Safe amount (OK) | `AppColors.success` | `AppColors.success` |
| Safe amount (over-budget) | `AppColors.expense` | `AppColors.expenseDark` |
| Pace number (warning) | `AppColors.warning` | `AppColors.warning` |

---

## Typography Map

| Element | AppTypography | Override |
|---------|--------------|---------|
| "Budget pulse" title | `AppTypography.bodyMedium` | none |
| "View →" link | `AppTypography.caption1` | none |
| Remaining value | `AppTypography.moneyMedium` | none (already tabular, ls -0.5) |
| Subtext "left of…" | `AppTypography.caption1` | none |
| Pace line | `AppTypography.caption2` | none |
| Pace number inline | `AppTypography.caption2.copyWith(fontWeight: FontWeight.w500, color: ...)` | weight override |
| Safe amount inline | `AppTypography.caption2.copyWith(fontWeight: FontWeight.w600, color: ...)` | weight w600 for contrast |

---

## Today Marker Implementation

Use a `Stack` with the progress bar and marker as children:

```
Stack(
  clipBehavior: Clip.none,
  children: [
    // Background bar
    Container(
      height: 6,
      decoration: BoxDecoration(
        color: progressBackground,
        borderRadius: BorderRadius.circular(3),
      ),
    ),
    // Fill bar
    FractionallySizedBox(
      widthFactor: fillFraction.clamp(0.0, 1.0),
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    ),
    // Today marker
    Positioned(
      left: markerFraction * totalBarWidth,   // calculate in LayoutBuilder
      top: -3,
      child: Container(
        width: 1.5,
        height: 12,
        color: todayMarkerColor,
      ),
    ),
  ],
)
```

Use `LayoutBuilder` to obtain `totalBarWidth` for today marker pixel positioning.

---

## Pace Line Construction

Build the pace line as a `RichText` / `Text.rich` to apply inline color and weight overrides:

```
Text.rich(TextSpan(children: [
  TextSpan(text: 'Daily pace: ', style: caption2 + paceBaseColor),
  TextSpan(text: formattedPace, style: caption2 + paceNumberColor + w500),
  TextSpan(text: '  ·  You can spend ', style: caption2 + paceBaseColor),
  TextSpan(text: safeAmountText, style: caption2 + safeColor + w600),
]))
```

When over-budget, replace the last two spans with:
```
TextSpan(text: '  ·  ', style: caption2 + paceBaseColor),
TextSpan(text: 'Over budget', style: caption2 + expenseColor + w600),
```

---

## Business Logic Formulas

```
remaining = budget - spent
fillFraction = (spent / budget).clamp(0.0, 1.0)   // guard: budget > 0
markerFraction = currentDay / daysInMonth
actualDailyPace = currentDay > 0 ? spent / currentDay : Decimal.zero
remainingDays = max(daysInMonth - currentDay + 1, 1)   // min 1 — avoid divide-by-zero
safeDailyAmount = remaining > 0 ? remaining / remainingDays : Decimal.zero

isOverBudget = remaining < 0 || remaining == 0
isWarning = actualDailyPace > safeDailyAmount * Decimal.fromInt(15) / Decimal.fromInt(10)
            && currentDay > 5
            && !isOverBudget
```

---

## Light Shadow

Apply only in light mode:

```
BoxDecoration(
  boxShadow: isDark ? [] : [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ],
)
```

---

## No-Budget CTA State

When `budget == null || budget == Decimal.zero`, render a simplified card:

- Same container (shape, border, padding, shadow)
- Title: "Budget pulse" — same `bodyMedium` style, no "View →" link
- Body: `Column` with:
  - "Set a monthly budget" — `AppTypography.bodyMedium`, `textPrimaryLight` / `textPrimary`
  - gap 4dp
  - "Stay on top of your spending" — `AppTypography.caption1`, `textSecondaryLight` / `textSecondary`
  - gap 12dp
  - TextButton: "Set budget" — `AppColors.brandPrimary`, `AppTypography.bodyMedium`, `FontWeight.w500`
    - onTap: `context.go('/budget')`

---

## Accessibility

```
Semantics(
  label: _buildSemanticLabel(remaining, budget, pace, safe, isOverBudget),
  child: ExcludeSemantics(child: cardContent),
)
```

"View →" must be a separate `Semantics` node with label `'View budget details'` and `button: true`.

---

## No New Tokens Required

All values map to existing AppColors, AppTypography, AppRadius, AppSpacing tokens. The 14dp padding and 10dp gaps are explicit values — no new AppSpacing entries needed.
