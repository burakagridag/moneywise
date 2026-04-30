// Riverpod providers for bookmark (transaction template) operations — features/transactions.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/repositories/bookmark_repository.dart';
import '../../../../domain/entities/bookmark.dart';

part 'bookmark_provider.g.dart';

/// Reactive stream of all non-deleted bookmarks.
@riverpod
Stream<List<Bookmark>> bookmarksStream(BookmarksStreamRef ref) {
  return ref.watch(bookmarkRepositoryProvider).watchAll();
}

/// Notifier that exposes save and delete operations for bookmarks.
@riverpod
class BookmarkWriteNotifier extends _$BookmarkWriteNotifier {
  @override
  void build() {}

  /// Saves (insert or update) a [bookmark].
  Future<void> save(Bookmark bookmark) async {
    await ref.read(bookmarkRepositoryProvider).save(bookmark);
  }

  /// Soft-deletes the bookmark with the given [id].
  Future<void> delete(String id) async {
    await ref.read(bookmarkRepositoryProvider).delete(id);
  }
}
