// Data access object for bookmark (transaction template) records — data/local feature.
import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/bookmarks_table.dart';

part 'bookmark_dao.g.dart';

/// Provides CRUD and reactive query methods for Bookmarks.
@DriftAccessor(tables: [Bookmarks])
class BookmarkDao extends DatabaseAccessor<AppDatabase>
    with _$BookmarkDaoMixin {
  BookmarkDao(super.db);

  /// Reactive stream of all non-deleted bookmarks ordered by sortOrder ASC,
  /// then createdAt DESC.
  Stream<List<Bookmark>> watchAll() {
    return (select(bookmarks)
          ..where((b) => b.isDeleted.equals(false))
          ..orderBy([
            (b) => OrderingTerm.asc(b.sortOrder),
            (b) => OrderingTerm.desc(b.createdAt),
          ]))
        .watch();
  }

  /// Insert or replace a bookmark row (upsert on primary key conflict).
  Future<void> upsert(BookmarksCompanion companion) async {
    await into(bookmarks).insertOnConflictUpdate(companion);
  }

  /// Soft-delete the bookmark with the given [id].
  Future<void> softDelete(String id) async {
    await (update(bookmarks)..where((b) => b.id.equals(id))).write(
      BookmarksCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
