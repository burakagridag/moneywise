// BookmarksNotifier — manages CRUD for saved transaction templates — more/bookmarks feature.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/repositories/bookmark_repository.dart';
import '../../../../domain/entities/bookmark.dart';

part 'bookmarks_provider.g.dart';

const _uuid = Uuid();

/// Reactive list of all bookmarks backed by [BookmarkRepository].
@riverpod
class BookmarksNotifier extends _$BookmarksNotifier {
  @override
  Stream<List<Bookmark>> build() {
    return ref.watch(bookmarkRepositoryProvider).watchAll();
  }

  /// Adds a new bookmark with a generated UUID.
  Future<void> add({
    required String name,
    required String type,
    double? amount,
    String currencyCode = 'EUR',
    String? categoryId,
    String? accountId,
    String? toAccountId,
    String? note,
    int sortOrder = 0,
  }) async {
    final now = DateTime.now();
    final bookmark = Bookmark(
      id: _uuid.v4(),
      name: name,
      type: type,
      amount: amount,
      currencyCode: currencyCode,
      categoryId: categoryId,
      accountId: accountId,
      toAccountId: toAccountId,
      note: note,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(bookmarkRepositoryProvider).add(bookmark);
  }

  /// Updates an existing bookmark.
  Future<void> save(Bookmark bookmark) async {
    await ref
        .read(bookmarkRepositoryProvider)
        .update(bookmark.copyWith(updatedAt: DateTime.now()));
  }

  /// Permanently deletes a bookmark by [id].
  Future<void> delete(String id) async {
    await ref.read(bookmarkRepositoryProvider).delete(id);
  }
}
