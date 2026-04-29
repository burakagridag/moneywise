// Immutable domain entity for a monthly category budget — budget feature.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_entity.freezed.dart';

/// Pure domain representation of a budget record.
/// Has no dependency on any data-layer types.
@freezed
class BudgetEntity with _$BudgetEntity {
  const factory BudgetEntity({
    required int id,

    /// The category this budget applies to.
    required String categoryId,

    /// Budget ceiling in the user's base currency (decimal-precise).
    required double amount,

    /// First day of the first active month (inclusive).
    required DateTime effectiveFrom,

    /// First day of the last active month (inclusive).
    /// Null means the budget is open-ended (all future months).
    DateTime? effectiveTo,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BudgetEntity;
}

/// Enriched view model combining a [BudgetEntity] with runtime spending data.
class BudgetWithSpending {
  const BudgetWithSpending({
    required this.budget,
    required this.spent,
    required this.carryOver,
  });

  /// The underlying budget configuration.
  final BudgetEntity budget;

  /// Actual spending for the queried month.
  final double spent;

  /// Amount carried over from the previous month's overspend (>= 0).
  final double carryOver;

  /// Effective budget ceiling after carry-over reduction (clamped to >= 0).
  double get effective =>
      (budget.amount - carryOver).clamp(0.0, double.infinity);

  /// Remaining budget (effective - spent); may be negative when over budget.
  double get remaining => effective - spent;

  /// Progress ratio in [0.0, 1.0+] — may exceed 1.0 when over budget.
  double get progressRatio => effective == 0 ? 1.0 : spent / effective;

  /// True when spending has exceeded the effective budget.
  bool get isOverBudget => spent > effective;
}
