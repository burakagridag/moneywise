// insight_mapper.dart — insights feature presentation layer.
// Maps a pure-domain [Insight] to an [InsightViewModel] by resolving the
// icon, color, and localized headline/body for the presentation layer.
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../domain/insight.dart';
import '../models/insight_view_model.dart';

/// Maps a pure-domain [Insight] to an [InsightViewModel] with icon, color,
/// and localized headline/body for rendering in [InsightCard].
///
/// The switch is keyed on [Insight.id], which is a stable constant defined in
/// each rule class. An unknown id falls back to a neutral info style so that
/// future rules are never invisible.
///
/// Localization: pass [l10n] to resolve locale-aware headline and body strings.
/// Computed body values (pct, amount) are sourced from [Insight.bodyParams] so
/// that the domain rule only needs to set the params map — the mapper builds the
/// fully-localized string via ARB placeholders.
InsightViewModel insightToViewModel(
  Insight insight,
  AppLocalizations l10n, {
  bool isDark = false,
}) {
  return switch (insight.id) {
    'concentration' => InsightViewModel(
        insight: insight,
        icon: Icons.pie_chart_outline,
        iconColor: AppColors.insightWarningIcon,
        iconBackgroundColor: isDark
            ? AppColors.insightWarningIconBgDark
            : AppColors.insightWarningIconBg,
        headline: l10n.insightConcentrationTitle,
        body: () {
          final pct = insight.bodyParams['pct'] as int?;
          return pct != null
              ? l10n.insightConcentrationBody(pct)
              : insight.body;
        }(),
      ),
    'savings_goal' => InsightViewModel(
        insight: insight,
        icon: Icons.savings_outlined,
        iconColor: AppColors.insightWarningIcon,
        iconBackgroundColor: isDark
            ? AppColors.insightWarningIconBgDark
            : AppColors.insightWarningIconBg,
        headline: l10n.insightSavingsGoalTitle,
        body: l10n.insightSavingsGoalBody,
      ),
    'daily_overpacing' => InsightViewModel(
        insight: insight,
        icon: Icons.trending_up,
        iconColor: AppColors.insightCriticalIcon,
        iconBackgroundColor: isDark
            ? AppColors.insightCriticalIconBgDark
            : AppColors.insightCriticalIconBg,
        headline: l10n.insightDailyOverpacingTitle,
        body: l10n.insightDailyOverpacingBody,
      ),
    'big_transaction' => InsightViewModel(
        insight: insight,
        icon: Icons.warning_amber_outlined,
        iconColor: AppColors.insightWarningIcon,
        iconBackgroundColor: isDark
            ? AppColors.insightWarningIconBgDark
            : AppColors.insightWarningIconBg,
        headline: l10n.insightBigTransactionTitle,
        body: () {
          final amount = insight.bodyParams['amount'] as String?;
          final pct = insight.bodyParams['pct'] as int?;
          return (amount != null && pct != null)
              ? l10n.insightBigTransactionBodyNormal(amount, pct)
              : l10n.insightBigTransactionBodyExceeds;
        }(),
      ),
    _ => InsightViewModel(
        insight: insight,
        icon: Icons.info_outline,
        iconColor: AppColors.insightNeutralIcon,
        iconBackgroundColor: isDark
            ? AppColors.insightNeutralIconBgDark
            : AppColors.insightNeutralIconBg,
        headline: insight.headline,
        body: insight.body,
      ),
  };
}
