// Riverpod providers for user financial settings (global budget) — home feature.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/user_settings_repository.dart';
import '../../../budget/presentation/providers/budget_providers.dart';

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
