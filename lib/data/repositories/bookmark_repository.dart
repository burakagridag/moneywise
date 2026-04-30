// Repository providing bookmark operations to the domain layer — data/repositories feature.
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../local/daos/bookmark_dao.dart';
import '../local/database.dart' hide Bookmark;
import '../../domain/entities/bookmark.dart';

// Alias the Drift-generated Bookmark to avoid collision with domain Bookmark.
import '../local/database.dart' as db show Bookmark;

part 'bookmark_repository.g.dart';

/// Riverpod provider that wires [BookmarkRepository] to [AppDatabase].
@riverpod
BookmarkRepository bookmarkRepository(BookmarkRepositoryRef ref) {
  final appDb = ref.watch(appDatabaseProvider);
  return BookmarkRepository(appDb.bookmarkDao);
}

/// Mediates between the data layer (BookmarkDao) and the domain layer.
/// All public methods work exclusively with domain entities.
class BookmarkRepository {
  BookmarkRepository(this._dao);

  final BookmarkDao _dao;

  /// Reactive stream of all non-deleted bookmarks.
  Stream<List<Bookmark>> watchAll() {
    return _dao.watchAll().map(
          (rows) => rows.map(_mapToDomain).toList(),
        );
  }

  /// Persists (insert or update) a [bookmark].
  Future<void> save(Bookmark bookmark) async {
    await _dao.upsert(_mapToCompanion(bookmark));
  }

  /// Soft-deletes the bookmark with the given [id].
  Future<void> delete(String id) async {
    await _dao.softDelete(id);
  }

  // ---------------------------------------------------------------------------
  // Mapping helpers
  // ---------------------------------------------------------------------------

  Bookmark _mapToDomain(db.Bookmark row) {
    return Bookmark(
      id: row.id,
      name: row.name,
      type: row.type,
      amount: row.amount,
      currencyCode: row.currencyCode,
      accountId: row.accountId,
      toAccountId: row.toAccountId,
      categoryId: row.categoryId,
      note: row.note,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  BookmarksCompanion _mapToCompanion(Bookmark b) {
    return BookmarksCompanion(
      id: Value(b.id),
      name: Value(b.name),
      type: Value(b.type),
      amount: Value(b.amount),
      currencyCode: Value(b.currencyCode),
      accountId: Value(b.accountId),
      toAccountId: Value(b.toAccountId),
      categoryId: Value(b.categoryId),
      note: Value(b.note),
      sortOrder: Value(b.sortOrder),
      createdAt: Value(b.createdAt),
      updatedAt: Value(b.updatedAt),
    );
  }
}
