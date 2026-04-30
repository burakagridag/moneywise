// Unit tests for CarryOverBudgetUseCase and BudgetWithSpending — budget/domain.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneywise/features/budget/data/budget_repository.dart';
import 'package:moneywise/features/budget/domain/budget_entity.dart';
import 'package:moneywise/features/budget/domain/use_cases/carry_over_budget.dart';

class _MockBudgetRepository extends Mock implements BudgetRepository {}

BudgetEntity _budget({
  required String categoryId,
  required double amount,
  int id = 1,
}) {
  final now = DateTime.now();
  return BudgetEntity(
    id: id,
    categoryId: categoryId,
    amount: amount,
    effectiveFrom: DateTime(2026, 4),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _MockBudgetRepository mockRepo;
  late CarryOverBudgetUseCase useCase;

  const categoryId = 'cat-001';
  final april = DateTime(2026, 4);
  final march = DateTime(2026, 3);

  setUp(() {
    mockRepo = _MockBudgetRepository();
    useCase = CarryOverBudgetUseCase(mockRepo);
  });

  void stubPrevSpent(double spent) {
    when(() => mockRepo.getSpentAmount(categoryId, march))
        .thenAnswer((_) async => spent);
  }

  void stubPrevBudget(BudgetEntity? budget) {
    when(() => mockRepo.getBudgetForCategory(categoryId, march))
        .thenAnswer((_) async => budget);
  }

  // ---------------------------------------------------------------------------
  // CarryOverBudgetUseCase tests
  // ---------------------------------------------------------------------------

  group('CarryOverBudgetUseCase', () {
    test('should_return_zero_carry_over_when_prev_month_under_budget',
        () async {
      final budget = _budget(categoryId: categoryId, amount: 500.0);
      final prevBudget = _budget(categoryId: categoryId, amount: 500.0, id: 2);

      stubPrevSpent(300.0); // 300 < 500, under budget
      stubPrevBudget(prevBudget);

      final result = await useCase.execute(
        budget: budget,
        month: april,
        currentSpent: 200.0,
      );

      expect(result.carryOver, 0.0);
      expect(result.effective, 500.0);
      expect(result.spent, 200.0);
      expect(result.isOverBudget, isFalse);
    });

    test('should_return_positive_carry_over_when_prev_month_over_budget',
        () async {
      final budget = _budget(categoryId: categoryId, amount: 500.0);
      final prevBudget = _budget(categoryId: categoryId, amount: 400.0, id: 2);

      stubPrevSpent(500.0); // 500 - 400 = 100 overspend
      stubPrevBudget(prevBudget);

      final result = await useCase.execute(
        budget: budget,
        month: april,
        currentSpent: 200.0,
      );

      expect(result.carryOver, 100.0);
      expect(result.effective, 400.0); // 500 - 100
      expect(result.remaining, 200.0); // 400 - 200
    });

    test('should_return_zero_carry_over_when_no_prev_budget_exists', () async {
      final budget = _budget(categoryId: categoryId, amount: 500.0);

      stubPrevSpent(999.0); // large spending but no prev budget reference
      stubPrevBudget(null);

      final result = await useCase.execute(
        budget: budget,
        month: april,
        currentSpent: 100.0,
      );

      expect(result.carryOver, 0.0);
      expect(result.effective, 500.0);
    });

    test('should_handle_january_correctly_as_previous_month_is_december',
        () async {
      final january = DateTime(2026, 1);
      final december = DateTime(2025, 12);

      final budget = _budget(categoryId: categoryId, amount: 600.0);
      final prevBudget = _budget(categoryId: categoryId, amount: 500.0, id: 2);

      when(() => mockRepo.getSpentAmount(categoryId, december))
          .thenAnswer((_) async => 600.0); // 100 overspend in December
      when(() => mockRepo.getBudgetForCategory(categoryId, december))
          .thenAnswer((_) async => prevBudget);

      final result = await useCase.execute(
        budget: budget,
        month: january,
        currentSpent: 50.0,
      );

      expect(result.carryOver, 100.0);
      expect(result.effective, 500.0); // 600 - 100
    });
  });

  // ---------------------------------------------------------------------------
  // BudgetWithSpending computed properties
  // ---------------------------------------------------------------------------

  group('BudgetWithSpending', () {
    BudgetWithSpending makeBws({
      required double amount,
      required double spent,
      required double carryOver,
    }) {
      final entity = _budget(categoryId: categoryId, amount: amount);
      return BudgetWithSpending(
        budget: entity,
        spent: spent,
        carryOver: carryOver,
      );
    }

    test('effective is never negative (clamp to 0)', () {
      // carry-over (300) > budget (100) => would be -200, must clamp to 0.
      final bws = makeBws(amount: 100.0, spent: 0.0, carryOver: 300.0);
      expect(bws.effective, 0.0);
    });

    test('progressRatio returns 1.0 when effective is 0', () {
      final bws = makeBws(amount: 50.0, spent: 0.0, carryOver: 200.0);
      expect(bws.effective, 0.0);
      expect(bws.progressRatio, 1.0);
    });

    test('progressRatio is spent/effective for normal case', () {
      final bws = makeBws(amount: 500.0, spent: 250.0, carryOver: 0.0);
      expect(bws.progressRatio, closeTo(0.5, 0.001));
    });

    test('isOverBudget is true when spent exceeds effective', () {
      final bws = makeBws(amount: 500.0, spent: 600.0, carryOver: 0.0);
      expect(bws.isOverBudget, isTrue);
      expect(bws.remaining, closeTo(-100.0, 0.001));
    });
  });
}
