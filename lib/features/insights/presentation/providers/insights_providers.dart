// Riverpod providers for the insights feature — assembles InsightContext from
// real data and calls the active InsightProvider implementation.
// EPIC8B-05: real data wiring replaces the V1 empty-rules stub.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../home/presentation/providers/user_settings_providers.dart';
import '../../../more/presentation/providers/app_preferences_provider.dart';
import '../../data/rule_based_insight_provider.dart';
import '../../domain/insight.dart';
import '../../domain/insight_context.dart';
import '../../domain/insight_provider.dart';
import '../../domain/rules/big_transaction_rule.dart';
import '../../domain/rules/concentration_rule.dart';
import '../../domain/rules/daily_overpacing_rule.dart';
import '../../domain/insight_classifier.dart';
import '../../domain/rules/savings_goal_rule.dart';
import '../../domain/rules/weekend_spending_rule.dart';
import '../mappers/insight_mapper.dart';
import '../models/insight_view_model.dart';

part 'insights_providers.g.dart';

// ---------------------------------------------------------------------------
// Swappable InsightProvider binding
// ---------------------------------------------------------------------------

/// Provides the active [InsightProvider] implementation.
///
/// V1 (EPIC8B-05/09): [RuleBasedInsightProvider] with the five concrete V1 rules.
/// Rules are evaluated in registration order; the severity sort in
/// [RuleBasedInsightProvider.generate] determines the final display order.
///
/// V2: Override via `ProviderContainer.overrideWith(...)` at app startup to
/// swap in an AI-driven provider without any UI or scaffold changes.
@riverpod
InsightProvider insightProviderInstance(InsightProviderInstanceRef ref) {
  return const RuleBasedInsightProvider(
    rules: [
      ConcentrationRule(),
      SavingsGoalRule(),
      DailyOverpacingRule(),
      BigTransactionRule(),
      WeekendSpendingRule(),
    ],
  );
}

// ---------------------------------------------------------------------------
// Assembled insights list
// ---------------------------------------------------------------------------

/// Assembles [InsightContext] from live database data, calls
/// [InsightProvider.generate] to produce a sorted list of [Insight]s, then
/// maps each to an [InsightViewModel] enriched with icon and color data for
/// the presentation layer.
///
/// Data sources:
/// - Current-month expense/income transactions from [TransactionRepository]
/// - Previous-month transactions for first-month fallback (see ADR-011)
/// - Active budgets enriched with carry-over from [budgetsForMonthProvider]
/// - Effective budget ceiling from [effectiveBudgetProvider]
///
/// Error handling: any DAO/repository failure is caught and logged; the
/// provider returns an empty list rather than crashing the Home tab.
///
/// Pull-to-refresh: callers invalidate this provider via
/// `ref.invalidate(insightsProvider)`.
@riverpod
Future<List<InsightViewModel>> insights(InsightsRef ref) async {
  final now = DateTime.now();

  // Establish ALL ref.watch subscriptions synchronously before the first await.
  // Riverpod requires watches to be called synchronously so that dependency
  // tracking is established. Watching after an await silently fails to
  // subscribe, causing stale reads when upstream providers change.
  final provider = ref.watch(insightProviderInstanceProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final budgetsFuture = ref.watch(budgetsForMonthProvider(now).future);
  final effectiveBudgetFuture = ref.watch(effectiveBudgetProvider(now).future);
  // Resolve locale-aware AppLocalizations synchronously from user preferences.
  // Falls back to 'en' when preferences are still loading or unavailable.
  final prefsAsync = ref.watch(appPreferencesNotifierProvider);
  final languageCode = prefsAsync.valueOrNull?.languageCode ?? 'en';
  final l10n = lookupAppLocalizations(Locale(languageCode));
  // isDark: resolved from persisted ThemeMode preference.
  // ThemeMode.system cannot be resolved here (no BuildContext); defaults to
  // light — acceptable V1 approximation; users who explicitly set dark mode
  // get correct icon backgrounds.
  final isDark =
      (prefsAsync.valueOrNull?.themeMode ?? ThemeMode.system) == ThemeMode.dark;

  try {
    // Current month transactions — one-shot fetch (FutureProvider, not Stream).
    final currentTxns = await repo.getByMonth(now.year, now.month);

    // Budgets for current month — enriched with carry-over spending.
    final budgets = await budgetsFuture;

    // Effective budget ceiling (global or sum-of-category fallback).
    final effectiveBudget = await effectiveBudgetFuture;

    // Previous month — one-shot fetch; not reactive (acceptable for V1).
    // See ADR-011 §Negative for the documented limitation.
    final prevMonth = DateTime(now.year, now.month - 1);
    final prevTxns = await repo.getByMonth(prevMonth.year, prevMonth.month);

    final context = InsightContext(
      currentMonthTransactions: currentTxns,
      previousMonthTransactions: prevTxns,
      currentMonthBudgets: budgets,
      effectiveBudget: effectiveBudget,
      referenceDate: now,
      formatAmount: (amount) => CurrencyFormatter.format(amount),
    );

    return provider
        .generate(context)
        .map((insight) => insightToViewModel(insight, l10n, isDark: isDark))
        .toList();
  } catch (e, st) {
    // EDGE CASE: DAO or repository failure — return empty list and log.
    // The Home tab's ThisWeekSection hides itself when the list is empty,
    // so the user sees no error UI, only the absence of insight cards.
    debugPrint('[InsightsProvider] Error: $e\n$st');
    return const [];
  }
}

// ---------------------------------------------------------------------------
// Surface-filtered insights list
// ---------------------------------------------------------------------------

/// Returns insights filtered to those visible on [surface].
///
/// Delegates to [insightsProvider] for the full list, then filters using
/// [insightVisibleOn] from the insight classifier (ADR-013 addendum).
///
/// Usage:
/// ```dart
/// final homeInsights = ref.watch(insightsForSurfaceProvider(InsightSurface.home));
/// final budgetInsights = ref.watch(insightsForSurfaceProvider(InsightSurface.budget));
/// ```
@riverpod
Future<List<InsightViewModel>> insightsForSurface(
  InsightsForSurfaceRef ref,
  InsightSurface surface,
) async {
  final all = await ref.watch(insightsProvider.future);
  return all
      .where((vm) => insightVisibleOn(vm.id, surface))
      .toList();
}
