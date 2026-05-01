# Total Balance Card — Engineer Redlines

**Reads:** `spec.md`, `tokens.json`
**Target widget:** `lib/features/home/presentation/widgets/total_balance_card.dart`

---

## Critical: Dark Mode Gradient Start Color

The dark mode gradient start `#4F46E5` is NOT in `AppColors`. This is approved by the Sponsor (see EPIC_home_tab_redesign_v2.md). Define as a widget-local private constant:

```
static const Color _darkGradientStart = Color(0xFF4F46E5);
```

Do NOT add to `AppColors`. This is intentionally scoped to this widget.

---

## Dimension Map

| Visual element | Value | Token / constant |
|----------------|-------|-----------------|
| Card border radius | 20dp | `AppRadius.xl` |
| Card padding (all sides) | 18dp | explicit 18 (AppSpacing.xl = 20, not exact) |
| Card horizontal margin | 16dp | `AppSpacing.lg` |
| Card bottom margin | 12dp | `AppSpacing.md` |
| Label → balance gap | 6dp | `AppSpacing.xs + 2` → use explicit 6 |
| Balance → trend row gap | 8dp | `AppSpacing.sm` |
| Trend chip padding V | 3dp | explicit 3 |
| Trend chip padding H | 10dp | explicit 10 |
| Trend chip → label gap | 6dp | `AppSpacing.xs + 2` → use explicit 6 |
| Trend row → sparkline gap | 12dp | `AppSpacing.md` |
| Sparkline container height | 36dp | explicit 36 |
| Sparkline stroke width | 1.5dp | explicit 1.5 |

---

## Color Map

| Element | Value | How to express in Dart |
|---------|-------|------------------------|
| Gradient start (light) | #3D5A99 | `AppColors.brandPrimary` |
| Gradient end (light) | #2E4A87 | `AppColors.brandPrimaryDim` |
| Gradient start (dark) | #4F46E5 | `_darkGradientStart` (widget-local const) |
| Gradient end (dark) | #3D5A99 | `AppColors.brandPrimary` |
| Label text | white 70% | `Colors.white.withOpacity(0.70)` |
| Balance text | white | `AppColors.textOnBrand` |
| Trend chip background | white 18% | `Colors.white.withOpacity(0.18)` |
| Trend chip text | white | `AppColors.textOnBrand` |
| Trend label text | white 85% | `Colors.white.withOpacity(0.85)` |
| Sparkline stroke | white 50% | `Colors.white.withOpacity(0.50)` |
| Sparkline fill top | white 10% | `Colors.white.withOpacity(0.10)` |
| Sparkline fill bottom | transparent | `Colors.white.withOpacity(0.00)` |

---

## Typography Map

| Element | AppTypography style | Notes |
|---------|--------------------|----|
| "TOTAL BALANCE" label | `AppTypography.caption2` | 11pt, weight 400, ls 0.4 — add `textTransform` via `toUpperCase()` on string |
| Balance value | `AppTypography.moneyLarge` | 32pt, weight 700, ls -1.0, tabular figures via `FontFeature.tabularFigures()` |
| Trend chip text | Custom: caption2 + weight 500 | Use `AppTypography.caption2.copyWith(fontWeight: FontWeight.w500)` |
| Trend label | `AppTypography.caption1` | 12pt, weight 400, ls 0.3 |

---

## Gradient Decoration

```
BoxDecoration(
  borderRadius: BorderRadius.circular(AppRadius.xl),
  gradient: LinearGradient(
    begin: Alignment.topLeft,      // 135deg
    end: Alignment.bottomRight,
    colors: isDark
      ? [_darkGradientStart, AppColors.brandPrimary]
      : [AppColors.brandPrimary, AppColors.brandPrimaryDim],
  ),
)
```

---

## Trend Arrow Logic

```
final delta = balance - previousBalance;
final arrowChar = delta >= 0 ? '↑' : '↓';
final formattedDelta = currencyFormatter.format(delta.abs());
final chipText = '$arrowChar $formattedDelta';
```

Show trend row only when `previousBalance != null && previousBalance != Decimal.zero`.

---

## Sparkline (fl_chart)

```
LineChartData(
  lineBarsData: [
    LineChartBarData(
      spots: dataPoints,          // List<FlSpot>
      isCurved: true,
      color: Colors.white.withOpacity(0.50),
      barWidth: 1.5,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.00),
          ],
        ),
      ),
    ),
  ],
  titlesData: FlTitlesData(show: false),
  gridData: FlGridData(show: false),
  borderData: FlBorderData(show: false),
  lineTouchData: LineTouchData(enabled: false),
)
```

For the draw animation: wrap in `TweenAnimationBuilder<double>` driving `maxX` from 0 to full range over 300ms with `Curves.easeInOutCubic`. Only animate on first build (use `initState` flag).

---

## Shimmer State

When loading, render the same card container (gradient background preserved) with shimmer overlays:

| Area | Shimmer bar size |
|------|-----------------|
| Label | 80dp × 10dp |
| Balance | 180dp × 28dp |
| Trend row | 120dp × 14dp |
| Sparkline | full-width × 36dp |

Shimmer color: `Colors.white.withOpacity(0.15)` base, `Colors.white.withOpacity(0.25)` highlight sweep. Use `shimmer` package or manual `AnimatedBuilder` with gradient shift.

---

## Accessibility

Wrap the card in `Semantics`:

```
Semantics(
  label: _buildSemanticLabel(balance, delta, previousBalance),
  child: ExcludeSemantics(
    child: cardContent,
  ),
)
```

`_buildSemanticLabel` returns: `"Total balance: {balance}. {Up/Down} {delta} since last month."` or `"Total balance: {balance}."` when no trend.

Sparkline uses `ExcludeSemantics` — decorative only.

---

## No Additional AppColors Token Required

The only non-token value is `#4F46E5` (dark gradient start), handled as widget-local const. All other values map to existing tokens or explicit `Colors.white.withOpacity()` calls.
