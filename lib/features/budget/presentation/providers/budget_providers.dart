// Riverpod providers for budget feature — budget feature.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/budget_repository.dart';
import '../../domain/budget_entity.dart';
import '../../domain/use_cases/carry_over_budget.dart';

export '../../data/budget_repository.dart' show budgetRepositoryProvider;

part 'budget_providers.g.dart';

// ---------------------------------------------------------------------------
// Use-case provider
// ---------------------------------------------------------------------------

/// Provides a [CarryOverBudgetUseCase] wired to [BudgetRepository].
@riverpod
CarryOverBudgetUseCase carryOverBudgetUseCase(CarryOverBudgetUseCaseRef ref) {
  return CarryOverBudgetUseCase(ref.watch(budgetRepositoryProvider));
}

// ---------------------------------------------------------------------------
// Budgets for a given month — enriched with carry-over spending data
// ---------------------------------------------------------------------------

/// Emits all active budgets for [month], each enriched with current spending
/// and carry-over from the previous month.
@riverpod
Future<List<BudgetWithSpending>> budgetsForMonth(
  BudgetsForMonthRef ref,
  DateTime month,
) async {
  final repo = ref.watch(budgetRepositoryProvider);
  final useCase = ref.watch(carryOverBudgetUseCaseProvider);

  // Listen reactively to budget configuration changes.
  final budgets = await ref.watch(budgetsForMonthStreamProvider(month).future);

  final results = await Future.wait(
    budgets.map((budget) async {
      final spent = await repo.getSpentAmount(budget.categoryId, month);
      return useCase.execute(
        budget: budget,
        month: month,
        currentSpent: spent,
      );
    }),
  );

  return results;
}

/// Internal stream provider — allows [budgetsForMonth] to rebuild whenever the
/// database emits a new list (e.g. after upsert or delete).
@riverpod
Stream<List<BudgetEntity>> budgetsForMonthStream(
  BudgetsForMonthStreamRef ref,
  DateTime month,
) =>
    ref.watch(budgetRepositoryProvider).watchBudgetsForMonth(month);

// ---------------------------------------------------------------------------
// Totals for a given month
// ---------------------------------------------------------------------------

/// Emits the aggregate total budget ceiling and total spending for [month].
@riverpod
Future<({double totalBudget, double totalSpent})> totalBudget(
  TotalBudgetRef ref,
  DateTime month,
) async {
  final items = await ref.watch(budgetsForMonthProvider(month).future);
  final totalBudgetAmount =
      items.fold<double>(0.0, (sum, b) => sum + b.effective);
  final totalSpent = items.fold<double>(0.0, (sum, b) => sum + b.spent);
  return (totalBudget: totalBudgetAmount, totalSpent: totalSpent);
}
