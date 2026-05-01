// ThisWeekSection widget — home feature (EPIC8A-08).
// Renders the "This week" insight cards or hides the section when no insights.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
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
    final asyncInsights = ref.watch(insightsProvider);

    return asyncInsights.when(
      loading: () => const _ThisWeekShimmer(),
      error: (_, __) => _ThisWeekError(context: context),
      data: (insights) {
        if (insights.isEmpty) {
          // Section occupies zero height when there are no insights.
          return const SizedBox.shrink();
        }

        // Cap at 2 cards per spec display logic.
        final visible = insights.take(2).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header — "THIS WEEK"
            _ThisWeekHeader(),
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
                  onTap: insight.actionRoute != null
                      ? () {
                          // mounted check not needed in ConsumerWidget — context
                          // is always valid within build; navigation deferred to
                          // next frame via GoRouter.
                          context.go(insight.actionRoute!);
                        }
                      : null,
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
        'THIS WEEK',
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

class _ThisWeekError extends StatelessWidget {
  const _ThisWeekError({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThisWeekHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Center(
            child: Text(
              'Insights unavailable',
              style: AppTypography.caption1.copyWith(
                color: ctx.isDark
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
