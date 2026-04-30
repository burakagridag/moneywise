// Widget tests for BudgetView — empty state, progress bar colours, carry-over — budget feature.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/core/widgets/budget_progress_bar.dart';
import 'package:moneywise/data/local/database.dart' hide Transaction;
import 'package:moneywise/features/budget/domain/budget_entity.dart';
import 'package:moneywise/features/budget/presentation/widgets/budget_view.dart';

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _buildBudgetView(AppDatabase db) => ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((_) => db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: const Scaffold(body: BudgetView()),
      ),
    );

void main() {
  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  group('BudgetView — empty state', () {
    testWidgets('shows no-budgets message when no budgets configured',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildBudgetView(db));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No budgets set'), findsOneWidget);
      expect(
          find.text(
              "Tap 'Budget Setting' to configure monthly limits per category."),
          findsOneWidget);
      expect(find.text('Set Up Budgets'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // BudgetProgressBar colour thresholds
  // ---------------------------------------------------------------------------

  group('BudgetProgressBar — colour thresholds', () {
    test('returns brandPrimary for ratio < 0.7', () {
      expect(
        BudgetProgressBar.colorForRatio(0.5),
        const Color(0xFFFF6B5C), // AppColors.brandPrimary
      );
    });

    test('returns warning for ratio in [0.7, 1.0)', () {
      expect(
        BudgetProgressBar.colorForRatio(0.85),
        const Color(0xFFFFA726), // AppColors.warning
      );
    });

    test('returns error for ratio >= 1.0', () {
      expect(
        BudgetProgressBar.colorForRatio(1.0),
        const Color(0xFFE53935), // AppColors.error
      );
      expect(
        BudgetProgressBar.colorForRatio(1.5),
        const Color(0xFFE53935),
      );
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetProgressBar(ratio: 0.6, height: 8),
          ),
        ),
      );
      expect(find.byType(BudgetProgressBar), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // BudgetWithSpending helper assertions
  // ---------------------------------------------------------------------------

  group('BudgetWithSpending — carry-over computation', () {
    test('effective equals budget minus carry-over, clamped to 0', () {
      final entity = BudgetEntity(
        id: 1,
        categoryId: 'cat1',
        amount: 200.0,
        effectiveFrom: DateTime(2026, 4, 1),
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      );

      final bws = BudgetWithSpending(
        budget: entity,
        spent: 150.0,
        carryOver: 50.0,
      );

      expect(bws.effective, 150.0); // 200 - 50
      expect(bws.remaining, 0.0); // 150 - 150
      expect(bws.isOverBudget, isFalse);
    });

    test('clamps effective to 0 when carryOver exceeds budget', () {
      final entity = BudgetEntity(
        id: 1,
        categoryId: 'cat1',
        amount: 100.0,
        effectiveFrom: DateTime(2026, 4, 1),
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      );

      final bws = BudgetWithSpending(
        budget: entity,
        spent: 50.0,
        carryOver: 150.0, // Exceeds budget
      );

      expect(bws.effective, 0.0);
      expect(bws.isOverBudget, isTrue);
    });

    test('isOverBudget is true when spent exceeds effective', () {
      final entity = BudgetEntity(
        id: 2,
        categoryId: 'cat2',
        amount: 300.0,
        effectiveFrom: DateTime(2026, 4, 1),
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      );

      final bws = BudgetWithSpending(
        budget: entity,
        spent: 350.0,
        carryOver: 0.0,
      );

      expect(bws.isOverBudget, isTrue);
      expect(bws.remaining, -50.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Populated state
  // ---------------------------------------------------------------------------

  group('BudgetView — populated state', () {
    testWidgets('renders summary card with budget data', (tester) async {
      final db = _testDb();

      // Seed an expense category and a budget.
      final expenseCats = await db.categoryDao.getByType('expense');
      final catId = expenseCats.first.id;
      final now = DateTime.now();
      final monthStart =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-01';

      await db.budgetDao.upsertBudget(
        BudgetsCompanion(
          categoryId: Value(catId),
          amount: const Value(300.0),
          effectiveFrom: Value(monthStart),
          createdAt: Value(now.toIso8601String()),
          updatedAt: Value(now.toIso8601String()),
        ),
      );

      await tester.pumpWidget(_buildBudgetView(db));
      await tester.pump(const Duration(milliseconds: 300));

      // Budget summary card label should be visible.
      expect(find.text('Remaining (Monthly)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // budgetsForMonthProvider reactive updates
  // ---------------------------------------------------------------------------

  group('budgetsForMonthProvider — reactive', () {
    testWidgets('BudgetView shows empty state when no budgets in DB',
        (tester) async {
      final db = _testDb();

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const Scaffold(body: BudgetView()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Empty state shown when no budgets exist.
      expect(find.text('No budgets set'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });
}
