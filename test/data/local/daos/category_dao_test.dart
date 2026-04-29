// Unit tests for CategoryDao write paths and non-watch methods — data/local feature.
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() {
    db = _openTestDb();
  });

  tearDown(() async => db.close());

  // ---------------------------------------------------------------------------
  // getByType — non-reactive read
  // ---------------------------------------------------------------------------

  group('CategoryDao.getByType', () {
    test('returns 7 income categories', () async {
      final cats = await db.categoryDao.getByType('income');
      expect(cats.length, 7);
    });

    test('returns 21 expense categories', () async {
      final cats = await db.categoryDao.getByType('expense');
      expect(cats.length, 21);
    });

    test('all returned categories match the requested type', () async {
      final income = await db.categoryDao.getByType('income');
      for (final c in income) {
        expect(c.type, 'income');
      }
      final expense = await db.categoryDao.getByType('expense');
      for (final c in expense) {
        expect(c.type, 'expense');
      }
    });

    test('categories are ordered by sortOrder ascending', () async {
      final cats = await db.categoryDao.getByType('expense');
      for (var i = 1; i < cats.length; i++) {
        expect(cats[i].sortOrder, greaterThanOrEqualTo(cats[i - 1].sortOrder));
      }
    });

    test('soft-deleted categories are excluded from getByType', () async {
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('HiddenCat'),
          type: const Value('income'),
          sortOrder: const Value(999),
          isDefault: const Value(false),
          isDeleted: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final cats = await db.categoryDao.getByType('income');
      expect(cats.any((c) => c.id == id), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // insertCategory
  // ---------------------------------------------------------------------------

  group('CategoryDao.insertCategory', () {
    test('inserted category appears in watchAll stream', () async {
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('Freelance'),
          type: const Value('income'),
          sortOrder: const Value(100),
          isDefault: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final all = await db.categoryDao.watchAll().first;
      expect(all.any((c) => c.id == id && c.name == 'Freelance'), isTrue);
    });

    test('inserted category appears in watchByType', () async {
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('Gaming'),
          type: const Value('expense'),
          iconEmoji: const Value('🎮'),
          sortOrder: const Value(101),
          isDefault: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final expenses = await db.categoryDao.watchByType('expense').first;
      final found = expenses.firstWhere((c) => c.id == id);
      expect(found.name, 'Gaming');
      expect(found.iconEmoji, '🎮');
    });

    test('inserted category does not appear in watchByType for wrong type',
        () async {
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('IncomeOnly'),
          type: const Value('income'),
          sortOrder: const Value(102),
          isDefault: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final expenses = await db.categoryDao.watchByType('expense').first;
      expect(expenses.any((c) => c.id == id), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // updateCategory
  // ---------------------------------------------------------------------------

  group('CategoryDao.updateCategory', () {
    test('updateCategory changes the name', () async {
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('OldName'),
          type: const Value('expense'),
          sortOrder: const Value(200),
          isDefault: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.categoryDao.updateCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('NewName'),
          type: const Value('expense'),
          sortOrder: const Value(200),
          isDefault: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final all = await db.categoryDao.watchAll().first;
      expect(all.firstWhere((c) => c.id == id).name, 'NewName');
    });

    test('updateCategory changes iconEmoji', () async {
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('IconTest'),
          type: const Value('expense'),
          iconEmoji: const Value('🍔'),
          sortOrder: const Value(201),
          isDefault: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.categoryDao.updateCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('IconTest'),
          type: const Value('expense'),
          iconEmoji: const Value('🍕'),
          sortOrder: const Value(201),
          isDefault: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final all = await db.categoryDao.watchAll().first;
      expect(all.firstWhere((c) => c.id == id).iconEmoji, '🍕');
    });

    test('updateCategory changes sortOrder', () async {
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('SortTest'),
          type: const Value('income'),
          sortOrder: const Value(300),
          isDefault: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.categoryDao.updateCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('SortTest'),
          type: const Value('income'),
          sortOrder: const Value(1),
          isDefault: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final all = await db.categoryDao.watchAll().first;
      expect(all.firstWhere((c) => c.id == id).sortOrder, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // softDeleteCategory
  // ---------------------------------------------------------------------------

  group('CategoryDao.softDeleteCategory', () {
    test('soft-deleted category is excluded from watchAll', () async {
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('ToDelete'),
          type: const Value('expense'),
          sortOrder: const Value(400),
          isDefault: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.categoryDao.softDeleteCategory(id);
      final all = await db.categoryDao.watchAll().first;
      expect(all.any((c) => c.id == id), isFalse);
    });

    test('soft-deleted category is excluded from watchByType', () async {
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('GoneExpense'),
          type: const Value('expense'),
          sortOrder: const Value(401),
          isDefault: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.categoryDao.softDeleteCategory(id);
      final expenses = await db.categoryDao.watchByType('expense').first;
      expect(expenses.any((c) => c.id == id), isFalse);
    });

    test('soft-delete of non-existent id does not throw', () async {
      await expectLater(
        db.categoryDao.softDeleteCategory(_uuid.v4()),
        completes,
      );
    });

    test('soft-deleted category is excluded from getByType', () async {
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: Value(id),
          name: const Value('ByTypeGone'),
          type: const Value('income'),
          sortOrder: const Value(402),
          isDefault: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.categoryDao.softDeleteCategory(id);
      final income = await db.categoryDao.getByType('income');
      expect(income.any((c) => c.id == id), isFalse);
    });
  });
}
