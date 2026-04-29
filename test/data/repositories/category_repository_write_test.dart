// Additional write-path integration tests for CategoryRepository — data/repositories feature.
import 'package:drift/native.dart';
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
  // Helpers
  // ---------------------------------------------------------------------------

  domain.Category buildTestCategory({
    required String id,
    String name = 'Test Category',
    String type = 'expense',
    int sortOrder = 999,
    bool isDefault = false,
    String? iconEmoji,
    String? colorHex,
    String? parentId,
  }) {
    final now = DateTime.now();
    return domain.Category(
      id: id,
      name: name,
      type: type,
      sortOrder: sortOrder,
      isDefault: isDefault,
      iconEmoji: iconEmoji,
      colorHex: colorHex,
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }

  // ---------------------------------------------------------------------------
  // updateCategory
  // ---------------------------------------------------------------------------

  group('updateCategory', () {
    test('updates the name', () async {
      final id = _uuid.v4();
      await repository.addCategory(buildTestCategory(id: id, name: 'Original'));
      final updated = buildTestCategory(id: id, name: 'Updated');
      await repository.updateCategory(updated);
      final all = await repository.watchAll().first;
      expect(all.firstWhere((c) => c.id == id).name, 'Updated');
    });

    test('updates iconEmoji', () async {
      final id = _uuid.v4();
      await repository.addCategory(buildTestCategory(id: id, iconEmoji: '🍔'));
      final updated = buildTestCategory(id: id, iconEmoji: '🍕');
      await repository.updateCategory(updated);
      final all = await repository.watchAll().first;
      expect(all.firstWhere((c) => c.id == id).iconEmoji, '🍕');
    });

    test('updates colorHex', () async {
      final id = _uuid.v4();
      await repository
          .addCategory(buildTestCategory(id: id, colorHex: '#000000'));
      final updated = buildTestCategory(id: id, colorHex: '#FFFFFF');
      await repository.updateCategory(updated);
      final all = await repository.watchAll().first;
      expect(all.firstWhere((c) => c.id == id).colorHex, '#FFFFFF');
    });

    test('updates sortOrder', () async {
      final id = _uuid.v4();
      await repository.addCategory(buildTestCategory(id: id, sortOrder: 500));
      final updated = buildTestCategory(id: id, sortOrder: 1);
      await repository.updateCategory(updated);
      final income = await repository.watchByType('expense').first;
      expect(income.firstWhere((c) => c.id == id).sortOrder, 1);
    });

    test('updates type from expense to income', () async {
      final id = _uuid.v4();
      await repository.addCategory(
          buildTestCategory(id: id, type: 'expense', name: 'FlipType'));
      // Type change: rebuild with new type.
      final now = DateTime.now();
      final updated = domain.Category(
        id: id,
        name: 'FlipType',
        type: 'income',
        sortOrder: 999,
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );
      await repository.updateCategory(updated);
      final income = await repository.watchByType('income').first;
      expect(income.any((c) => c.id == id), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteCategory — edge cases
  // ---------------------------------------------------------------------------

  group('deleteCategory', () {
    test('deleting same category twice does not throw', () async {
      final id = _uuid.v4();
      await repository.addCategory(buildTestCategory(id: id));
      await repository.deleteCategory(id);
      await expectLater(repository.deleteCategory(id), completes);
    });

    test('other categories remain after targeted delete', () async {
      final idA = _uuid.v4();
      final idB = _uuid.v4();
      await repository.addCategory(buildTestCategory(id: idA, name: 'KeepMe'));
      await repository
          .addCategory(buildTestCategory(id: idB, name: 'DeleteMe'));
      await repository.deleteCategory(idB);
      final all = await repository.watchAll().first;
      expect(all.any((c) => c.id == idA), isTrue);
      expect(all.any((c) => c.id == idB), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // addCategory — optional field mapping
  // ---------------------------------------------------------------------------

  group('addCategory — optional field mapping', () {
    test('optional fields are null when not provided', () async {
      final id = _uuid.v4();
      await repository.addCategory(buildTestCategory(id: id));
      final all = await repository.watchAll().first;
      final saved = all.firstWhere((c) => c.id == id);
      expect(saved.iconEmoji, isNull);
      expect(saved.colorHex, isNull);
      expect(saved.parentId, isNull);
    });

    test('parentId is persisted when provided', () async {
      final parentId = _uuid.v4();
      final childId = _uuid.v4();
      await repository
          .addCategory(buildTestCategory(id: parentId, name: 'Parent'));
      await repository.addCategory(
          buildTestCategory(id: childId, name: 'Child', parentId: parentId));
      final all = await repository.watchAll().first;
      expect(all.firstWhere((c) => c.id == childId).parentId, parentId);
    });

    test('isDefault flag is persisted', () async {
      final id = _uuid.v4();
      await repository.addCategory(buildTestCategory(id: id, isDefault: true));
      final all = await repository.watchAll().first;
      expect(all.firstWhere((c) => c.id == id).isDefault, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // watchAll after multiple mutations
  // ---------------------------------------------------------------------------

  group('watchAll — compound mutations', () {
    test('add then update reflects latest state', () async {
      final id = _uuid.v4();
      await repository.addCategory(buildTestCategory(id: id, name: 'V1'));
      await repository.updateCategory(buildTestCategory(id: id, name: 'V2'));
      final all = await repository.watchAll().first;
      expect(all.firstWhere((c) => c.id == id).name, 'V2');
    });

    test('total count is correct after add and delete', () async {
      final baseline = (await repository.watchAll().first).length;
      final keepId = _uuid.v4();
      final deleteId = _uuid.v4();
      await repository.addCategory(buildTestCategory(id: keepId));
      await repository.addCategory(buildTestCategory(id: deleteId));
      await repository.deleteCategory(deleteId);
      final all = await repository.watchAll().first;
      expect(all.length, baseline + 1);
    });
  });
}
