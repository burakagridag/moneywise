// Repository providing category operations to the domain layer — data/repositories feature.
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../local/daos/category_dao.dart';

// database.dart re-exports the generated Category, CategoriesCompanion data
// classes via its .g.dart part file.
import '../local/database.dart';

import '../../domain/entities/category.dart' as domain;

part 'category_repository.g.dart';

/// Riverpod provider that wires [CategoryRepository] to [AppDatabase].
@riverpod
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return CategoryRepository(db.categoryDao);
}

/// Mediates between the data layer (Drift DAOs) and the domain layer.
/// All public methods work exclusively with domain entities.
class CategoryRepository {
  CategoryRepository(this._dao);

  final CategoryDao _dao;

  /// Reactive stream of all non-deleted categories.
  Stream<List<domain.Category>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_mapCategory).toList());

  /// Reactive stream of categories filtered by [type] ('income' or 'expense').
  Stream<List<domain.Category>> watchByType(String type) =>
      _dao.watchByType(type).map(
            (rows) => rows.map(_mapCategory).toList(),
          );

  /// Persists a new category derived from the domain entity.
  Future<void> addCategory(domain.Category category) =>
      _dao.insertCategory(_toCompanion(category));

  /// Updates an existing category.
  Future<void> updateCategory(domain.Category category) =>
      _dao.updateCategory(_toCompanion(category));

  /// Soft-deletes a category by [id].
  Future<void> deleteCategory(String id) => _dao.softDeleteCategory(id);

  // ---------------------------------------------------------------------------
  // Mapping — data → domain
  // ---------------------------------------------------------------------------

  domain.Category _mapCategory(Category row) => domain.Category(
        id: row.id,
        name: row.name,
        type: row.type,
        parentId: row.parentId,
        iconEmoji: row.iconEmoji,
        colorHex: row.colorHex,
        sortOrder: row.sortOrder,
        isDefault: row.isDefault,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        isDeleted: row.isDeleted,
      );

  // ---------------------------------------------------------------------------
  // Mapping — domain → data
  // ---------------------------------------------------------------------------

  CategoriesCompanion _toCompanion(domain.Category c) => CategoriesCompanion(
        id: Value(c.id),
        name: Value(c.name),
        type: Value(c.type),
        parentId: Value(c.parentId),
        iconEmoji: Value(c.iconEmoji),
        colorHex: Value(c.colorHex),
        sortOrder: Value(c.sortOrder),
        isDefault: Value(c.isDefault),
        createdAt: Value(c.createdAt),
        updatedAt: Value(DateTime.now()),
        isDeleted: Value(c.isDeleted),
      );
}
