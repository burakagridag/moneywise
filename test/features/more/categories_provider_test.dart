// Unit tests for CategoryWriteNotifier and category stream providers — more feature.
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:moneywise/data/repositories/category_repository.dart';
import 'package:moneywise/domain/entities/category.dart' as domain_category;
import 'package:moneywise/features/more/presentation/providers/categories_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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

domain_category.Category _buildCategory({
  required String id,
  String name = 'Test',
  String type = 'expense',
  int sortOrder = 999,
  String? iconEmoji,
  String? colorHex,
}) {
  final now = DateTime.now();
  return domain_category.Category(
    id: id,
    name: name,
    type: type,
    sortOrder: sortOrder,
    isDefault: false,
    iconEmoji: iconEmoji,
    colorHex: colorHex,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // incomeCategoriesProvider — read-only
  // ---------------------------------------------------------------------------

  group('incomeCategoriesProvider', () {
    test('emits default 7 income categories', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final sub = container.listen(incomeCategoriesProvider, (_, __) {});
      addTearDown(sub.close);

      final result = await container.read(incomeCategoriesProvider.future);
      expect(result.length, 7);
      expect(result.every((c) => c.type == 'income'), isTrue);
    });

    test('all income categories are non-deleted', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final sub = container.listen(incomeCategoriesProvider, (_, __) {});
      addTearDown(sub.close);

      final result = await container.read(incomeCategoriesProvider.future);
      for (final c in result) {
        expect(c.isDeleted, isFalse);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // expenseCategoriesProvider — read-only
  // ---------------------------------------------------------------------------

  group('expenseCategoriesProvider', () {
    test('emits default 21 expense categories', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final sub = container.listen(expenseCategoriesProvider, (_, __) {});
      addTearDown(sub.close);

      final result = await container.read(expenseCategoriesProvider.future);
      expect(result.length, 21);
      expect(result.every((c) => c.type == 'expense'), isTrue);
    });

    test('all expense categories are non-deleted', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final sub = container.listen(expenseCategoriesProvider, (_, __) {});
      addTearDown(sub.close);

      final result = await container.read(expenseCategoriesProvider.future);
      for (final c in result) {
        expect(c.isDeleted, isFalse);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // CategoryWriteNotifier.addCategory
  //
  // After notifier writes, verify via the repository stream (not the provider
  // future, which may hold a cached pre-mutation value due to AutoDispose
  // timing).
  // ---------------------------------------------------------------------------

  group('CategoryWriteNotifier.addCategory', () {
    test('added expense category persists via repository stream', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final id = _uuid.v4();
      final category = _buildCategory(
          id: id, name: 'Gaming', type: 'expense', iconEmoji: '🎮');

      await container
          .read(categoryWriteNotifierProvider.notifier)
          .addCategory(category);

      final repo = container.read(categoryRepositoryProvider);
      final expenses = await repo.watchByType('expense').first;
      expect(expenses.any((c) => c.id == id && c.name == 'Gaming'), isTrue);
    });

    test('added income category persists via repository stream', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final id = _uuid.v4();
      final category = _buildCategory(
          id: id, name: 'Dividends', type: 'income', iconEmoji: '💹');

      await container
          .read(categoryWriteNotifierProvider.notifier)
          .addCategory(category);

      final repo = container.read(categoryRepositoryProvider);
      final income = await repo.watchByType('income').first;
      expect(income.any((c) => c.id == id && c.name == 'Dividends'), isTrue);
    });

    test('added expense category does not appear in income stream', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final id = _uuid.v4();
      final category =
          _buildCategory(id: id, name: 'Transport', type: 'expense');

      await container
          .read(categoryWriteNotifierProvider.notifier)
          .addCategory(category);

      final repo = container.read(categoryRepositoryProvider);
      final income = await repo.watchByType('income').first;
      expect(income.any((c) => c.id == id), isFalse);
    });

    test('multiple categories can be added sequentially', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final repo = container.read(categoryRepositoryProvider);
      final baseline = (await repo.watchByType('expense').first).length;
      final notifier = container.read(categoryWriteNotifierProvider.notifier);

      await notifier.addCategory(
          _buildCategory(id: _uuid.v4(), name: 'Cat1', type: 'expense'));
      await notifier.addCategory(
          _buildCategory(id: _uuid.v4(), name: 'Cat2', type: 'expense'));
      await notifier.addCategory(
          _buildCategory(id: _uuid.v4(), name: 'Cat3', type: 'expense'));

      final expenses = await repo.watchByType('expense').first;
      expect(expenses.length, baseline + 3);
    });

    test('category fields are persisted correctly', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final id = _uuid.v4();
      final category = _buildCategory(
        id: id,
        name: 'PersistTest',
        type: 'expense',
        sortOrder: 42,
        iconEmoji: '🔥',
        colorHex: '#FF5733',
      );

      await container
          .read(categoryWriteNotifierProvider.notifier)
          .addCategory(category);

      final repo = container.read(categoryRepositoryProvider);
      final expenses = await repo.watchByType('expense').first;
      final saved = expenses.firstWhere((c) => c.id == id);
      expect(saved.name, 'PersistTest');
      expect(saved.sortOrder, 42);
      expect(saved.iconEmoji, '🔥');
      expect(saved.colorHex, '#FF5733');
      expect(saved.isDefault, isFalse);
    });

    test('expense write does not affect income count', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final repo = container.read(categoryRepositoryProvider);
      final incomeBaseline = (await repo.watchByType('income').first).length;

      await container
          .read(categoryWriteNotifierProvider.notifier)
          .addCategory(_buildCategory(id: _uuid.v4(), type: 'expense'));

      final incomeAfter = await repo.watchByType('income').first;
      expect(incomeAfter.length, incomeBaseline);
    });
  });
}
