// Data access object for income and expense categories — data/local feature.
import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/categories_table.dart';

part 'category_dao.g.dart';

/// Provides CRUD and reactive query methods for Categories.
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Emits all non-deleted categories ordered by [sortOrder].
  Stream<List<Category>> watchAll() => (select(categories)
        ..where((c) => c.isDeleted.equals(false))
        ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
      .watch();

  /// Emits non-deleted categories filtered by [type] ('income' or 'expense').
  Stream<List<Category>> watchByType(String type) => (select(categories)
        ..where(
          (c) => c.isDeleted.equals(false) & c.type.equals(type),
        )
        ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
      .watch();

  /// Returns all non-deleted categories for [type] once (non-reactive).
  Future<List<Category>> getByType(String type) => (select(categories)
        ..where(
          (c) => c.isDeleted.equals(false) & c.type.equals(type),
        )
        ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
      .get();

  /// Inserts a new category row.
  Future<void> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);

  /// Updates an existing category row.
  Future<void> updateCategory(CategoriesCompanion category) =>
      (update(categories)..where((c) => c.id.equals(category.id.value)))
          .write(category);

  /// Soft-deletes a category (sets isDeleted = true).
  Future<void> softDeleteCategory(String id) =>
      (update(categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
