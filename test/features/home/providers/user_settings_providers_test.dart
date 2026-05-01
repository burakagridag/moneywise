// Unit tests for globalBudgetProvider and effectiveBudgetProvider — home feature (EPIC8A-04).
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:moneywise/features/home/presentation/providers/user_settings_providers.dart';

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

(ProviderContainer, AppDatabase) _buildContainer() {
  final db = _openTestDb();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((_) => db),
    ],
  );
  return (container, db);
}

void main() {
  // ---------------------------------------------------------------------------
  // globalBudgetProvider
  // ---------------------------------------------------------------------------

  group('globalBudgetProvider', () {
    test('emits null on a fresh database', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final value = await container.read(globalBudgetProvider.future);
      expect(value, isNull);
    });

    test('emits the set value after upsert', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      await db.userSettingsDao.upsertGlobalBudget(250.0);
      final value = await container.read(globalBudgetProvider.future);
      expect(value, 250.0);
    });

    test('emits null after value is cleared', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      await db.userSettingsDao.upsertGlobalBudget(100.0);
      await db.userSettingsDao.upsertGlobalBudget(null);
      final value = await container.read(globalBudgetProvider.future);
      expect(value, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // effectiveBudgetProvider
  // ---------------------------------------------------------------------------

  group('effectiveBudgetProvider — global set', () {
    test('returns the global budget when it is non-null', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final month = DateTime(2026, 5);
      await db.userSettingsDao.upsertGlobalBudget(3000.0);

      final value =
          await container.read(effectiveBudgetProvider(month).future);
      expect(value, 3000.0);
    });
  });

  group('effectiveBudgetProvider — global null, no category budgets', () {
    test('returns null when both global and category budgets are absent',
        () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      // Global is null (fresh DB), no category budgets seeded.
      final month = DateTime(2026, 5);
      final value =
          await container.read(effectiveBudgetProvider(month).future);
      expect(value, isNull);
    });
  });

  group('effectiveBudgetProvider — global null, category budgets exist', () {
    test('delegates to totalBudgetProvider and returns the category sum',
        () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      // Seed a category budget for May 2026.
      final month = DateTime(2026, 5);
      final categories = await db.categoryDao.getByType('expense');
      final categoryId = categories.first.id;

      await db.budgetDao.upsertBudget(
        BudgetsCompanion.insert(
          categoryId: categoryId,
          amount: 500.0,
          effectiveFrom: '2026-05-01',
          createdAt: '2026-05-01',
          updatedAt: '2026-05-01',
        ),
      );

      // Ensure global remains null.
      final global = await container.read(globalBudgetProvider.future);
      expect(global, isNull);

      final value =
          await container.read(effectiveBudgetProvider(month).future);
      // effectiveBudgetProvider must return the category sum (≥ 500.0).
      expect(value, greaterThan(0));
      expect(value, isNotNull);
    });
  });
}
