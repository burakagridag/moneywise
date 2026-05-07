// insight_mapper.dart — insights feature presentation layer.
// Maps a pure-domain [Insight] to an [InsightViewModel] by resolving the
// icon, color, and localized headline/body for the presentation layer.
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../domain/insight.dart';
import '../../domain/insight_localization_data.dart';
import '../models/insight_view_model.dart';

/// Maps a pure-domain [Insight] to an [InsightViewModel] with icon, color,
/// and localized headline/body for rendering in [InsightCard].
///
/// Icon and color are keyed on [Insight.id] so that the correct visual style
/// is applied even when [Insight.localizationData] is null (future rules).
///
/// Localization: headline and body are resolved by dispatching on the sealed
/// [InsightLocalizationData] subtype. When [localizationData] is null, the
/// mapper falls back to [Insight.headline] and [Insight.body] so that future
/// rules with no registered subtype are never invisible.
InsightViewModel insightToViewModel(
  Insight insight,
  AppLocalizations l10n, {
  bool isDark = false,
}) {
  // Resolve icon / color from the stable id constant.
  final (icon, iconColor, iconBg) = switch (insight.id) {
    'concentration' => (
        Icons.pie_chart_outline,
        AppColors.insightWarningIcon,
        isDark
            ? AppColors.insightWarningIconBgDark
            : AppColors.insightWarningIconBg,
      ),
    'savings_goal' => (
        Icons.savings_outlined,
        AppColors.insightWarningIcon,
        isDark
            ? AppColors.insightWarningIconBgDark
            : AppColors.insightWarningIconBg,
      ),
    'daily_overpacing' => (
        Icons.trending_up,
        AppColors.insightCriticalIcon,
        isDark
            ? AppColors.insightCriticalIconBgDark
            : AppColors.insightCriticalIconBg,
      ),
    'big_transaction' => (
        Icons.warning_amber_outlined,
        AppColors.insightWarningIcon,
        isDark
            ? AppColors.insightWarningIconBgDark
            : AppColors.insightWarningIconBg,
      ),
    'weekend_spending' => (
        Icons.weekend,
        AppColors.insightWarningIcon,
        isDark
            ? AppColors.insightWarningIconBgDark
            : AppColors.insightWarningIconBg,
      ),
    _ => (
        Icons.info_outline,
        AppColors.insightNeutralIcon,
        isDark
            ? AppColors.insightNeutralIconBgDark
            : AppColors.insightNeutralIconBg,
      ),
  };

  // Resolve headline / body by dispatching on the typed localization payload.
  // When localizationData is null, fall back to domain strings so future rules
  // (with no registered subtype yet) are never invisible.
  final (headline, body) = switch (insight.localizationData) {
    ConcentrationLocalizationData(:final pct) => (
        l10n.insightConcentrationTitle,
        l10n.insightConcentrationBody(pct),
      ),
    SavingsGoalLocalizationData() => (
        l10n.insightSavingsGoalTitle,
        l10n.insightSavingsGoalBody,
      ),
    DailyOverpacingLocalizationData() => (
        l10n.insightDailyOverpacingTitle,
        l10n.insightDailyOverpacingBody,
      ),
    BigTransactionLocalizationData(
      :final pct,
      :final formattedAmount,
      :final exceedsBudget
    )
        when !exceedsBudget =>
      (
        l10n.insightBigTransactionTitle,
        l10n.insightBigTransactionBodyNormal(formattedAmount, pct),
      ),
    BigTransactionLocalizationData() => (
        l10n.insightBigTransactionTitle,
        l10n.insightBigTransactionBodyExceeds,
      ),
    WeekendSpendingLocalizationData(:final pct) => (
        l10n.insightWeekendSpendingTitle,
        l10n.insightWeekendSpendingBody(pct),
      ),
    null => (insight.headline, insight.body),
  };

  return InsightViewModel(
    insight: insight,
    icon: icon,
    iconColor: iconColor,
    iconBackgroundColor: iconBg,
    headline: headline,
    body: body,
  );
}
