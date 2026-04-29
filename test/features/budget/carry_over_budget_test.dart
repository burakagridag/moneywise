// Unit tests for CarryOverBudgetUseCase — budget feature.
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void stubPrevSpent(double spent) {
    when(() => mockRepo.getSpentAmount(categoryId, march))
        .thenAnswer((_) async => spent);
  }

  void stubPrevBudget(BudgetEntity? budget) {
    when(() => mockRepo.getBudgetForCategory(categoryId, march))
        .thenAnswer((_) async => budget);
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  group('CarryOverBudgetUseCase', () {
    test('carry-over is 0 when previous month spending is less than budget',
        () async {
      final budget = _budget(categoryId: categoryId, amount: 500.0);
      final prevBudget = _budget(categoryId: categoryId, amount: 500.0, id: 2);

      stubPrevSpent(300.0); // under budget
      stubPrevBudget(prevBudget);

      final result = await useCase.execute(
        budget: budget,
        month: april,
        currentSpent: 200.0,
      );

      expect(result.carryOver, 0.0);
      expect(result.effective, 500.0); // full budget, no reduction
      expect(result.spent, 200.0);
      expect(result.remaining, 300.0);
      expect(result.isOverBudget, isFalse);
    });

    test('carry-over is 0 when previous month spending equals budget exactly',
        () async {
      final budget = _budget(categoryId: categoryId, amount: 500.0);
      final prevBudget = _budget(categoryId: categoryId, amount: 400.0, id: 2);

      stubPrevSpent(400.0); // exactly at limit
      stubPrevBudget(prevBudget);

      final result = await useCase.execute(
        budget: budget,
        month: april,
        currentSpent: 100.0,
      );

      expect(result.carryOver, 0.0);
    });

    test(
        'carry-over equals overspend when previous month spending exceeds budget',
        () async {
      final budget = _budget(categoryId: categoryId, amount: 500.0);
      final prevBudget = _budget(categoryId: categoryId, amount: 400.0, id: 2);

      stubPrevSpent(500.0); // 100 over
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

    test('effective budget is clamped to 0 when carry-over exceeds budget',
        () async {
      // Current month budget is 50, but carry-over from prev month is 200.
      final budget = _budget(categoryId: categoryId, amount: 50.0);
      final prevBudget = _budget(categoryId: categoryId, amount: 200.0, id: 2);

      stubPrevSpent(400.0); // 200 over prev budget
      stubPrevBudget(prevBudget);

      final result = await useCase.execute(
        budget: budget,
        month: april,
        currentSpent: 0.0,
      );

      expect(result.carryOver, 200.0);
      // 50.0 - 200.0 would be negative; must clamp to 0.
      expect(result.effective, 0.0);
      expect(result.isOverBudget, isFalse); // spent is also 0
    });

    test('carry-over is 0 when no previous budget exists for the category',
        () async {
      final budget = _budget(categoryId: categoryId, amount: 500.0);

      stubPrevSpent(999.0); // large spending, but no prev budget configured
      stubPrevBudget(null);

      final result = await useCase.execute(
        budget: budget,
        month: april,
        currentSpent: 100.0,
      );

      // Without a previous budget there is no reference amount, so no carry-over.
      expect(result.carryOver, 0.0);
      expect(result.effective, 500.0);
    });

    test('isOverBudget is true when spent exceeds effective budget', () async {
      final budget = _budget(categoryId: categoryId, amount: 500.0);
      final prevBudget = _budget(categoryId: categoryId, amount: 500.0, id: 2);

      stubPrevSpent(0.0);
      stubPrevBudget(prevBudget);

      final result = await useCase.execute(
        budget: budget,
        month: april,
        currentSpent: 600.0, // 100 over
      );

      expect(result.isOverBudget, isTrue);
      expect(result.remaining, -100.0);
    });

    test('progressRatio is 1.0 when effective budget is 0', () async {
      // Carry-over bigger than budget → effective is 0.
      final budget = _budget(categoryId: categoryId, amount: 50.0);
      final prevBudget = _budget(categoryId: categoryId, amount: 100.0, id: 2);

      stubPrevSpent(200.0); // 100 over prev budget
      stubPrevBudget(prevBudget);

      final result = await useCase.execute(
        budget: budget,
        month: april,
        currentSpent: 0.0,
      );

      expect(result.effective, 0.0);
      expect(result.progressRatio, 1.0);
    });
  });
}
