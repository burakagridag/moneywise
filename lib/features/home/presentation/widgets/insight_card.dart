// InsightCard presentational widget — home feature (EPIC8A-08).
// Renders a single Insight observation: icon container, title, subtitle.
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

// ---------------------------------------------------------------------------
// Widget-local color constants (DO NOT add to AppColors — see redlines.md).
// These constants are referenced by Epic 8b severity-specific icon mapping;
// they are intentionally declared here to avoid future ADR changes to AppColors.
// ignore_for_file: unused_element
// ---------------------------------------------------------------------------

/// Warning severity icon stroke — light mode.
const Color _warningIconLight = Color(0xFFC2410C);

/// Warning severity icon stroke — dark mode.
const Color _warningIconDark = Color(0xFFFB923C);

/// Warning icon container background — light mode (AppColors.warning @15% on white).
const Color _warningBgLight = Color(0x26FFA726);

/// Warning icon container background — dark mode (AppColors.warning @20%).
const Color _warningBgDark = Color(0x33FFA726);

/// Info severity icon container background — light mode.
/// Dark mode uses AppColors.brandSurface.
const Color _infoIconBgLight = Color(0xFFD6DCF0);

/// Success severity icon container background — light mode.
const Color _successIconBgLight = Color(0xFFDCFCE7);

/// Success severity icon container background — dark mode.
const Color _successIconBgDark = Color(0xFF14532D);

/// Success severity icon stroke — light mode.
const Color _successIconStrokeLight = Color(0xFF15803D);
// Dark stroke: AppColors.success (#4CAF50) — no local const needed.

// ---------------------------------------------------------------------------
// InsightCard
// ---------------------------------------------------------------------------

/// Presentational card displaying a single [Insight] observation.
///
/// The widget is purely presentational — it does not read from any Riverpod
/// provider. All data is injected via constructor parameters so the widget is
/// fully testable with mock data.
///
/// Layout:
/// ```
/// ┌────────────────────────────────────────────┐
/// │  ┌──────┐  [headline — 1 line ellipsis]    │
/// │  │ icon │  [body — 1 line ellipsis]        │
/// │  └──────┘                                  │
/// └────────────────────────────────────────────┘
/// ```
///
/// When [onTap] is null the card is not tappable — no [InkWell] is rendered.
/// When [onTap] is provided the full card ripples on tap.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  /// Icon rendered inside the 36×36dp tinted container.
  final IconData icon;

  /// Stroke/fill color of [icon].
  final Color iconColor;

  /// Tinted background color of the icon container.
  final Color iconBackgroundColor;

  /// Card headline — 1 line, ellipsis.
  final String title;

  /// Card supporting text — 1 line, ellipsis.
  final String subtitle;

  /// Tap callback. When null the card is non-interactive (no InkWell).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cardBackground =
        isDark ? AppColors.bgSecondary : AppColors.bgElevatedLight;
    final cardBorder = isDark ? AppColors.border : AppColors.borderLight;
    final titleColor =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subtitleColor =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    final shadow = isDark
        ? <BoxShadow>[]
        : <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];

    final cardContent = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cardBorder),
        boxShadow: shadow,
      ),
      child: Row(
        children: [
          // Icon container — 36×36dp, 10dp radius, tinted background.
          ExcludeSemantics(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Text column — flex so ellipsis works on narrow screens.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption1.copyWith(color: subtitleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final semanticLabel = onTap != null
        ? '$title. $subtitle. Tap for details.'
        : '$title. $subtitle.';

    if (onTap == null) {
      return Semantics(
        label: semanticLabel,
        child: cardContent,
      );
    }

    // Tappable variant: Material + InkWell for correct ripple clipping.
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          splashColor: AppColors.brandPrimaryGlow,
          child: cardContent,
        ),
      ),
    );
  }
}
