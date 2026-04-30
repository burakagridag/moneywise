// Bookmarks CRUD screen — lists, adds, edits, and deletes transaction templates — transactions feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../domain/entities/bookmark.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/bookmark_add_edit_sheet.dart';
import '../widgets/bookmark_list_item.dart';

/// Full-screen bookmarks management view.
/// Swipe left on any row to delete. Tap FAB to add a new bookmark.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncBookmarks = ref.watch(bookmarksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookmarks, style: AppTypography.title2),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_bookmark_fab',
        onPressed: () => _openSheet(context),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.textOnBrand,
        child: const Icon(Icons.add),
      ),
      body: asyncBookmarks.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandPrimary),
        ),
        error: (e, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.errorLoadTitle,
                style: AppTypography.headline.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.invalidate(bookmarksStreamProvider),
                child: Text(
                  l10n.retryButton,
                  style: AppTypography.subhead.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return _EmptyState(onAdd: () => _openSheet(context));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: bookmarks.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: AppSpacing.lg),
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              return Dismissible(
                key: ValueKey(bookmark.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return await _confirmDelete(context, l10n);
                },
                onDismissed: (_) {
                  ref
                      .read(bookmarkWriteNotifierProvider.notifier)
                      .delete(bookmark.id)
                      .catchError((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.errorDeletingBookmark)),
                      );
                    }
                  });
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  color: AppColors.error,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: BookmarkListItem(
                  bookmark: bookmark,
                  onTap: () => _openSheet(context, existing: bookmark),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openSheet(BuildContext context, {Bookmark? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => BookmarkAddEditSheet(existing: existing),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.bookmarkDeleteConfirm, style: AppTypography.title3),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.bookmarkDeleteAction,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_outline,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.bookmarkEmptyTitle,
              style: AppTypography.title3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.bookmarkEmptySubtitle,
              style: AppTypography.subhead.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.addBookmark),
            ),
          ],
        ),
      ),
    );
  }
}
