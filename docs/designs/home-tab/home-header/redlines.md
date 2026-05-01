# HomeHeader — Engineer Redlines

**Reads:** `spec.md`, `tokens.json`
**Target widget:** `lib/features/home/presentation/widgets/home_header.dart`

---

## Dimension Map

| Visual element | Value | Token / constant |
|----------------|-------|-----------------|
| Widget horizontal padding (left + right) | 16dp each side | `AppSpacing.lg` |
| Widget top margin | 8dp | `AppSpacing.sm` |
| Widget bottom margin | 20dp | `AppSpacing.xl` |
| Avatar diameter | 36dp | hardcoded 36 (no token; closest is `AppSpacing.xxxl` at 32 — use 36 explicitly) |
| Avatar border width | 1dp | hardcoded 1 |
| Avatar border radius | circular | `AppRadius.pill` or `BorderRadius.circular(18)` |
| Avatar font size | 13pt | no AppTypography match — use `FontSize: 13`, weight `FontWeight.w600` |
| Avatar minimum tap area | 44dp | `AppHeights.listItem - 16` → use explicit `SizedBox(width:44, height:44)` wrapping avatar |
| Date-greeting vertical gap | 2dp | `AppSpacing.xs / 2` → use `SizedBox(height:2)` |

---

## Color Map

Use `Theme.of(context).brightness == Brightness.dark` to switch between dark and light tokens.

| Element | Light token | Dark token | Hex (light / dark) |
|---------|-------------|------------|---------------------|
| Date text | `AppColors.textSecondaryLight` | `AppColors.textSecondary` | #5C5E6B / #8A90A8 |
| Greeting text | `AppColors.textPrimaryLight` | `AppColors.textPrimary` | #1A1C24 / #F0F2F8 |
| Avatar background | `AppColors.bgSecondaryLight` | `AppColors.bgSecondary` | #EEECEA / #181C27 |
| Avatar border | `AppColors.borderLight` | `AppColors.border` | #C8C4BC / #2E3453 |
| Avatar initial text | `AppColors.textSecondaryLight` | `AppColors.textSecondary` | #5C5E6B / #8A90A8 |

> Note: `bgSecondaryLight` in `AppColors` resolves to `#EEECEA`. The reference mockup shows `#EEECEA` for the avatar background in light mode — this matches.

---

## Typography Map

| Element | AppTypography style | Notes |
|---------|--------------------|----|
| Date | `AppTypography.caption1` | 12pt, weight 400, ls 0.3 — do not override |
| Greeting | `AppTypography.headline` | 17pt, weight 600, ls 0.1 — do not override |
| Avatar initial | Custom: `FontSize 13, FontWeight.w600` | No matching AppTypography style; specify inline |

---

## Layout Instructions

```
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dateString, style: caption1 + dateColor),
        SizedBox(height: 2),
        Text(greetingString, style: headline + greetingColor),
      ],
    ),
    GestureDetector(
      onTap: navigateToMore,
      child: SizedBox(
        width: 44, height: 44,
        child: Center(
          child: Avatar(diameter: 36),
        ),
      ),
    ),
  ],
)
```

---

## Greeting Logic (state-based, no new token needed)

```
final hour = DateTime.now().hour;
final greeting = hour >= 5 && hour < 12
    ? 'Good morning'
    : hour >= 12 && hour < 18
        ? 'Good afternoon'
        : 'Good evening';
final displayGreeting = userName?.isNotEmpty == true
    ? '$greeting, $userName'
    : greeting;
```

---

## Date Formatting

```
// Use intl package — already a dependency
final dateFormat = DateFormat('EEEE, d MMMM', Localizations.localeOf(context).toString());
final dateString = dateFormat.format(DateTime.now());
```

---

## No New Tokens Required

All values are covered by existing `AppColors`, `AppTypography`, `AppSpacing`, and `AppRadius` tokens. The 36dp avatar size and 2dp gap are hardcoded explicit values with no suitable token — this is acceptable per design system rules (tokens cover standard steps; custom sizes are allowed inline).
