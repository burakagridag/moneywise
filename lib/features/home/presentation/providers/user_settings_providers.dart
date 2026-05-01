// Riverpod providers for user financial settings (global budget) — home feature.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/user_settings_repository.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../../data/repositories/transaction_repository.dart';

export '../../data/user_settings_repository.dart'
    show userSettingsRepositoryProvider;

part 'user_settings_providers.g.dart';

// ---------------------------------------------------------------------------
// Global budget stream
// ---------------------------------------------------------------------------

/// Emits the raw global monthly budget value as stored in the database.
///
/// Emits `null` when the user has not set a global budget ceiling.
/// Consumers should prefer [effectiveBudgetProvider] which applies the
/// category-budget fallback automatically.
@riverpod
Stream<double?> globalBudget(GlobalBudgetRef ref) {
  final repo = ref.watch(userSettingsRepositoryProvider);
  return repo.watchGlobalBudget();
}

// ---------------------------------------------------------------------------
// Effective budget (with fallback)
// ---------------------------------------------------------------------------

/// Resolves the budget ceiling to display for [month] using the following
/// priority order:
///   1. Global monthly budget (when set by the user)
///   2. Sum of category budgets for [month] via [totalBudgetProvider]
///   3. null — neither is configured; BudgetPulseCard should show a CTA
///
/// Both [globalBudgetProvider] and [totalBudgetProvider] are watched so this
/// provider rebuilds whenever either changes.
///
/// V1 ASSUMPTION: single primary currency — all budgets and spending amounts
/// are assumed to be in the user's configured default currency (currencyCode
/// from AppPreferencesNotifier). Multi-currency aggregation is deferred to V2.
/// See ADR-010 §Multi-Currency Behaviour for the full rationale.
@riverpod
Future<double?> effectiveBudget(
  EffectiveBudgetRef ref,
  DateTime month,
) async {
  final global = await ref.watch(globalBudgetProvider.future);

  if (global != null) {
    return global;
  }

  // Fall back to the sum of all active category budgets for the given month.
  final totals = await ref.watch(totalBudgetProvider(month).future);
  final categorySum = totals.totalBudget;

  return categorySum > 0 ? categorySum : null;
}

// ---------------------------------------------------------------------------
// Effective spent (mode-aware, mirrors effectiveBudget logic)
// ---------------------------------------------------------------------------

/// Resolves the correct "spent" total to show alongside [effectiveBudgetProvider]
/// for [month].
///
/// The two modes must be kept in sync:
///
///   • **Global budget mode** (globalBudget != null):
///     spent = SUM of all non-excluded, non-deleted expense transactions for
///     [month]. This is the unfiltered total because the global budget ceiling
///     applies to the user's total spending.
///
///   • **Fallback mode** (only category budgets exist):
///     spent = SUM of transactions whose category has an active budget for
///     [month]. Using the full transaction total here inflates the numerator
///     relative to the budget denominator and produces a misleading (often
///     negative) remaining figure. [totalBudgetProvider] already computes the
///     category-scoped spent via [BudgetRepository.getSpentAmount], so we
///     reuse it directly.
///
/// Consumers (BudgetPulseCard) MUST use this provider instead of summing
/// [transactionsByMonthProvider] directly.
@riverpod
Future<double> effectiveSpent(
  EffectiveSpentRef ref,
  DateTime month,
) async {
  final global = await ref.watch(globalBudgetProvider.future);

  if (global != null) {
    // Global budget mode — sum all expense transactions for the explicit [month]
    // parameter. Using the repository directly avoids coupling to
    // selectedMonthProvider (the Transactions tab's navigation state).
    final repo = ref.watch(transactionRepositoryProvider);
    final txList = await repo.watchByMonth(month.year, month.month).first;
    return txList
        .where((t) => t.type == 'expense' && !t.isExcluded && !t.isDeleted)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  // Fallback mode — only count spending under budgeted categories.
  final totals = await ref.watch(totalBudgetProvider(month).future);
  return totals.totalSpent;
}
