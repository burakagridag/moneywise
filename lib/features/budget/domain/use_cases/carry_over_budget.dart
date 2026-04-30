// Use-case that computes the effective budget with carry-over from the previous month — budget feature.
import '../budget_entity.dart';
import '../../data/budget_repository.dart';

/// Computes the effective budget for [month] for a given [budget], taking into
/// account any overspend from the previous month (carry-over).
///
/// Rules:
/// - If previous-month spending <= budget amount → carry-over = 0.
/// - If previous-month spending > budget amount  → carry-over = overspend > 0.
/// - Effective budget = max(0, budget.amount - carryOver).
class CarryOverBudgetUseCase {
  const CarryOverBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  /// Resolves [BudgetWithSpending] for [budget] in [month].
  ///
  /// [currentSpent] is the spending already fetched for the current month
  /// (avoids a redundant DB call when the caller already has it).
  Future<BudgetWithSpending> execute({
    required BudgetEntity budget,
    required DateTime month,
    required double currentSpent,
  }) async {
    final prevMonth = _previousMonth(month);
    final prevSpent =
        await _repository.getSpentAmount(budget.categoryId, prevMonth);

    // Carry-over is the positive overspend from the previous month only.
    final prevBudget = await _repository.getBudgetForCategory(
      budget.categoryId,
      prevMonth,
    );

    double carryOver = 0.0;
    if (prevBudget != null) {
      final overspend = prevSpent - prevBudget.amount;
      if (overspend > 0) {
        carryOver = overspend;
      }
    }

    return BudgetWithSpending(
      budget: budget,
      spent: currentSpent,
      carryOver: carryOver,
    );
  }

  DateTime _previousMonth(DateTime month) {
    if (month.month == 1) {
      return DateTime(month.year - 1, 12);
    }
    return DateTime(month.year, month.month - 1);
  }
}
