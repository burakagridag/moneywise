// Unit tests for CategoryRepository mapping logic — data/repositories feature.
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:moneywise/data/repositories/category_repository.dart';
import 'package:moneywise/domain/entities/category.dart' as domain;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late CategoryRepository repository;

  setUp(() {
    db = _openTestDb();
    repository = CategoryRepository(db.categoryDao);
  });

  tearDown(() async => db.close());

  // ---------------------------------------------------------------------------
  // Seeded default categories
  // ---------------------------------------------------------------------------

  group('watchByType — default seed', () {
    test('emits 7 income categories after DB creation', () async {
      final cats = await repository.watchByType('income').first;
      expect(cats.length, 7);
    });

    test('emits 21 expense categories after DB creation', () async {
      final cats = await repository.watchByType('expense').first;
      expect(cats.length, 21);
    });

    test('all income categories have type income', () async {
      final cats = await repository.watchByType('income').first;
      for (final c in cats) {
        expect(c.type, 'income');
      }
    });

    test('all expense categories have type expense', () async {
      final cats = await repository.watchByType('expense').first;
      for (final c in cats) {
        expect(c.type, 'expense');
      }
    });

    test('default categories are marked isDefault = true', () async {
      final income = await repository.watchByType('income').first;
      final expense = await repository.watchByType('expense').first;
      for (final c in [...income, ...expense]) {
        expect(c.isDefault, isTrue);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // watchAll
  // ---------------------------------------------------------------------------

  group('watchAll', () {
    test('emits all 28 default categories', () async {
      final all = await repository.watchAll().first;
      expect(all.length, 28); // 7 income + 21 expense
    });
  });

  // ---------------------------------------------------------------------------
  // addCategory / soft-delete
  // ---------------------------------------------------------------------------

  group('addCategory + softDelete', () {
    test('new custom category appears in watchByType', () async {
      final now = DateTime.now();
      final cat = domain.Category(
        id: _uuid.v4(),
        name: 'Gaming',
        type: 'expense',
        iconEmoji: '🎮',
        sortOrder: 999,
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      await repository.addCategory(cat);
      final cats = await repository.watchByType('expense').first;
      expect(cats.any((c) => c.name == 'Gaming'), isTrue);
    });

    test('soft-deleted category is excluded from watchByType', () async {
      final now = DateTime.now();
      final id = _uuid.v4();
      final cat = domain.Category(
        id: id,
        name: 'Temp',
        type: 'expense',
        sortOrder: 999,
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      await repository.addCategory(cat);
      await repository.deleteCategory(id);

      final cats = await repository.watchByType('expense').first;
      expect(cats.any((c) => c.id == id), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Riverpod provider wiring
  // ---------------------------------------------------------------------------

  group('categoryRepositoryProvider', () {
    test('provider creates CategoryRepository', () {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((_) => _openTestDb()),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(categoryRepositoryProvider);
      expect(repo, isA<CategoryRepository>());
    });
  });
}
