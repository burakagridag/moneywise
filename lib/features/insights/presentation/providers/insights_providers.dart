// Riverpod providers for the insights feature — assembles InsightContext and
// calls the active InsightProvider implementation.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/repositories/transaction_repository.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../home/presentation/providers/user_settings_providers.dart';
import '../../data/rule_based_insight_provider.dart';
import '../../domain/insight.dart';
import '../../domain/insight_context.dart';
import '../../domain/insight_provider.dart';

part 'insights_providers.g.dart';

// ---------------------------------------------------------------------------
// Swappable InsightProvider binding
// ---------------------------------------------------------------------------

/// Provides the active [InsightProvider] implementation.
///
/// V1: [RuleBasedInsightProvider] with an empty rules list — produces no
/// insights until Epic 8b registers the four concrete rule classes.
///
/// V2: Override via `ProviderContainer.overrideWith(...)` at app startup to
/// swap in an AI-driven provider without any UI or scaffold changes.
@riverpod
InsightProvider insightProviderInstance(InsightProviderInstanceRef ref) {
  // V1: empty rules list — Epic 8b will add rule instances here.
  return const RuleBasedInsightProvider(rules: []);
}

// ---------------------------------------------------------------------------
// Assembled insights list
// ---------------------------------------------------------------------------

/// Assembles [InsightContext] from existing providers and calls
/// [InsightProvider.generate] to produce a sorted list of [Insight]s.
///
/// Returns an empty list in V1 because [insightProviderInstanceProvider] is
/// wired with zero rules. The [ThisWeekSection] widget hides itself when the
/// list is empty — no placeholder is shown.
///
/// Pull-to-refresh: callers invalidate this provider via
/// `ref.invalidate(insightsProvider)`.
@riverpod
Future<List<Insight>> insights(InsightsRef ref) async {
  final now = DateTime.now();
  final provider = ref.watch(insightProviderInstanceProvider);
  final repo = ref.watch(transactionRepositoryProvider);

  // Current month transactions — one-shot fetch (FutureProvider, not Stream).
  final currentTxns = await repo.getByMonth(now.year, now.month);

  // Budgets for current month — enriched with carry-over spending.
  final budgets = await ref.watch(budgetsForMonthProvider(now).future);

  // Effective budget ceiling (global or sum-of-category fallback).
  final effectiveBudget = await ref.watch(effectiveBudgetProvider(now).future);

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
  );

  return provider.generate(context);
}
