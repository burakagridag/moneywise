// ThisWeekSection widget — home feature (EPIC8A-08, updated EPIC8A-12).
// Renders the "This week" insight cards or hides the section when no insights.
// Fires insight_card_tapped analytics event when a card is tapped (EPIC8A-12).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../features/insights/domain/insight_classifier.dart';
import '../../../../features/insights/presentation/providers/insights_providers.dart';
import 'insight_card.dart';

/// Renders the "This week" section header and up to 2 [InsightCard]s sourced
/// from [insightsProvider].
///
/// Visibility rules (per spec.md and ADR-011):
/// - 0 insights → entire section hidden ([SizedBox.shrink]).
/// - 1–2 insights → header + InsightCard list.
/// - >2 insights → top 2 by severity (provider already sorts; widget takes first 2).
/// - Loading → shimmer placeholders.
/// - Error → non-blocking: section header + single error card.
class ThisWeekSection extends ConsumerWidget {
  const ThisWeekSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInsights =
        ref.watch(insightsForSurfaceProvider(InsightSurface.home));

    return asyncInsights.when(
      loading: () => const _ThisWeekShimmer(),
      error: (_, __) => const _ThisWeekError(),
      data: (insights) {
        if (insights.isEmpty) {
          // Section occupies zero height when there are no insights.
          return const SizedBox.shrink();
        }

        // Resolve actual device brightness — correctly handles ThemeMode.system.
        // The provider cannot do this (no BuildContext), so it defaults to light
        // when ThemeMode.system is set. Re-apply the correct icon background
        // here where brightness is authoritative.
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Cap at 2 cards per spec display logic (EPIC8A-08).
        // copyWithDark corrects iconBackgroundColor for ThemeMode.system users.
        final visible =
            insights.take(2).map((vm) => vm.copyWithDark(isDark)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header — "THIS WEEK"
            const _ThisWeekHeader(),
            ...visible.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.sm,
                ),
                child: InsightCard(
                  icon: insight.icon,
                  iconColor: insight.iconColor,
                  iconBackgroundColor: insight.iconBackgroundColor,
                  title: insight.headline,
                  subtitle: insight.body,
                  onTap: () {
                    // Fire analytics event for every tap, regardless of
                    // whether there is an actionRoute (EPIC8A-12).
                    ref.read(analyticsServiceProvider).logEvent(
                      'insight_card_tapped',
                      parameters: {'insight_type': insight.id},
                    );
                    if (insight.actionRoute != null) {
                      // mounted check not needed in ConsumerWidget — context
                      // is always valid within build; navigation deferred to
                      // next frame via GoRouter.
                      context.go(insight.actionRoute!);
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _ThisWeekHeader extends StatelessWidget {
  const _ThisWeekHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.only(
        top: 18,
        bottom: 10,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Text(
        AppLocalizations.of(context)!.homeThisWeekTitle.toUpperCase(),
        style: AppTypography.caption2.copyWith(
          color:
              isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading shimmer
// ---------------------------------------------------------------------------

class _ThisWeekShimmer extends StatelessWidget {
  const _ThisWeekShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final shimmerColor =
        isDark ? AppColors.bgTertiary : AppColors.bgSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header shimmer bar
        Padding(
          padding: const EdgeInsets.only(
            top: 18,
            bottom: 10,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
          ),
          child: Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
        // Two card shimmer placeholders
        for (int i = 0; i < 2; i++)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  // Icon area shimmer
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.bgElevated
                          : AppColors.bgTertiaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.bgElevated
                                : AppColors.bgTertiaryLight,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 120,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.bgElevated
                                : AppColors.bgTertiaryLight,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

/// Non-blocking error fallback for [ThisWeekSection].
///
/// Uses the `build(BuildContext context)` parameter — never stores a stale
/// [BuildContext] as a constructor field (Critical 1, code review 2026-05-01).
class _ThisWeekError extends StatelessWidget {
  const _ThisWeekError();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ThisWeekHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.homeInsightsUnavailable,
              style: AppTypography.caption1.copyWith(
                color: context.isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
