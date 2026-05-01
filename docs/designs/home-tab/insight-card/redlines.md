# Insight Card — Engineer Redlines

**Reads:** `spec.md`, `tokens.json`, `ADR-011-insight-provider-interface.md`
**Target widget:** `lib/features/home/presentation/widgets/insight_card.dart`

---

## Widget-Local Color Constants

Define these at the top of `insight_card.dart`. Do NOT add to `AppColors`.

```
// Warning severity icon colors
static const Color _warningIconLight = Color(0xFFC2410C);
static const Color _warningIconDark  = Color(0xFFFB923C);

// Warning icon backgrounds (AppColors.warning = 0xFFFFA726)
// Light: warning at 15% opacity on white
static const Color _warningBgLight = Color(0x26FFA726);
// Dark: warning at 20% opacity
static const Color _warningBgDark  = Color(0x33FFA726);

// Info severity icon background (light only — dark uses AppColors.brandSurface)
static const Color _infoIconBgLight = Color(0xFFD6DCF0);

// Success severity icon colors
static const Color _successIconBgLight      = Color(0xFFDCFCE7);
static const Color _successIconBgDark       = Color(0xFF14532D);
static const Color _successIconStrokeLight  = Color(0xFF15803D);
// Dark stroke: AppColors.success (#4CAF50) — no local const needed
```

---

## Dimension Map

| Visual element | Value | Token / constant |
|----------------|-------|-----------------|
| Card border radius | 14dp | `AppRadius.lg` |
| Card border width | 1dp | explicit 1 |
| Card padding vertical | 12dp | `AppSpacing.md` |
| Card padding horizontal | 14dp | explicit 14 |
| Card bottom margin | 8dp | `AppSpacing.sm` |
| Card horizontal margin | 16dp | `AppSpacing.lg` |
| Icon container size | 36×36dp | explicit 36 |
| Icon container radius | 10dp | `AppRadius.md` |
| Icon size | 18×18dp | explicit 18 |
| Icon → text gap | 12dp | `AppSpacing.md` |
| Title → subtitle gap | 2dp | explicit 2 |

---

## Color Map

| Element | Light | Dark |
|---------|-------|------|
| Card background | `AppColors.bgElevatedLight` | `AppColors.bgSecondary` |
| Card border | `AppColors.borderLight` | `AppColors.border` |
| Title | `AppColors.textPrimaryLight` | `AppColors.textPrimary` |
| Subtitle | `AppColors.textSecondaryLight` | `AppColors.textSecondary` |
| InkWell ripple | `AppColors.brandPrimaryGlow` | `AppColors.brandPrimaryGlow` |
| Warning icon bg | `_warningBgLight` | `_warningBgDark` |
| Warning icon stroke | `_warningIconLight` | `_warningIconDark` |
| Info icon bg | `_infoIconBgLight` | `AppColors.brandSurface` |
| Info icon stroke | `AppColors.brandPrimary` | `AppColors.brandPrimary` |
| Success icon bg | `_successIconBgLight` | `_successIconBgDark` |
| Success icon stroke | `_successIconStrokeLight` | `AppColors.success` |

---

## Typography Map

| Element | AppTypography | Override |
|---------|--------------|---------|
| Section header "THIS WEEK" | `AppTypography.caption2` | none; apply `.toUpperCase()` to string |
| Title | `AppTypography.bodyMedium` | none |
| Subtitle | `AppTypography.caption1` | none |

---

## Layout Structure

```
Material(                            // needed for InkWell ripple
  color: cardBackground,
  borderRadius: BorderRadius.circular(AppRadius.lg),
  child: InkWell(                    // only if onTap != null
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    splashColor: AppColors.brandPrimaryGlow,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: isDark ? [] : [BoxShadow(...)],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(child: Icon(iconData, size: 18, color: iconColor)),
          ),
          SizedBox(width: AppSpacing.md),
          // Text column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: AppTypography.bodyMedium.copyWith(color: titleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(subtitle,
                  style: AppTypography.caption1.copyWith(color: subtitleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
)
```

When `onTap == null`, omit the `InkWell` wrapper — use plain `Container`.

---

## Section Header

Rendered by the parent `HomeScreen`, not inside `InsightCard`:

```
Padding(
  padding: EdgeInsets.only(top: 18, bottom: 10, left: AppSpacing.lg, right: AppSpacing.lg),
  child: Text(
    'THIS WEEK',
    style: AppTypography.caption2.copyWith(
      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
      letterSpacing: 0.5,
    ),
  ),
)
```

---

## Severity → Icon Mapping (V1 rules)

| Rule | Severity | Icon (Lucide) | Light bg | Light stroke | Dark bg | Dark stroke |
|------|----------|--------------|----------|-------------|---------|------------|
| Concentration | warning | `Icons.trending_up` or Lucide trending_up | `_warningBgLight` | `_warningIconLight` | `_warningBgDark` | `_warningIconDark` |
| Savings Goal | success | bar_chart_3 / Lucide bar_chart | `_successIconBgLight` | `_successIconStrokeLight` | `_successIconBgDark` | `AppColors.success` |
| Daily Overpacing | warning | `Icons.bolt` / Lucide zap | `_warningBgLight` | `_warningIconLight` | `_warningBgDark` | `_warningIconDark` |
| Big Transaction | warning | `Icons.warning_amber` / Lucide alert_circle | `_warningBgLight` | `_warningIconLight` | `_warningBgDark` | `_warningIconDark` |

The `Insight` model carries `iconData`, `iconColor`, `iconBackgroundColor` — the widget does NOT switch on `InsightSeverity` to determine colors. The provider layer sets these fields. The widget is purely presentational.

---

## Accessibility

```
Semantics(
  label: onTap != null
    ? '$title. $subtitle. Tap for details.'
    : '$title. $subtitle.',
  button: onTap != null,
  child: ExcludeSemantics(child: cardContent),
)
```

---

## Light Shadow

```
BoxShadow(
  color: Colors.black.withOpacity(0.04),
  blurRadius: 8,
  offset: Offset(0, 2),
)
```

Apply only when `!isDark`.

---

## No New AppColors Tokens Required

All widget-local color constants are documented above. The `AppColors` file must not be modified.
