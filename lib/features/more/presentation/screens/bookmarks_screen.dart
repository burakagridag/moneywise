// BookmarksScreen — manage saved transaction templates — more/bookmarks feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/entities/bookmark.dart';
import '../providers/bookmarks_provider.dart';
import '../../presentation/widgets/bookmark_add_edit_sheet.dart';

/// Full-screen list of saved transaction templates.
/// Users can add, edit, and delete bookmarks from here.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBookmarks = ref.watch(bookmarksNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks', style: AppTypography.title2),
        centerTitle: false,
      ),
      body: asyncBookmarks.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandPrimary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: bookmarks.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              return _BookmarkTile(bookmark: bookmark);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_bookmark_fab',
        onPressed: () => _showAddEditSheet(context, null),
        backgroundColor: AppColors.brandPrimary,
        child: const Icon(Icons.add, color: AppColors.textOnBrand),
      ),
    );
  }

  static void _showAddEditSheet(BuildContext context, Bookmark? bookmark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookmarkAddEditSheet(bookmark: bookmark),
    );
  }
}

// ---------------------------------------------------------------------------
// Bookmark list tile
// ---------------------------------------------------------------------------

class _BookmarkTile extends ConsumerWidget {
  const _BookmarkTile({required this.bookmark});

  final Bookmark bookmark;

  IconData get _typeIcon {
    switch (bookmark.type) {
      case 'income':
        return Icons.arrow_downward;
      case 'expense':
        return Icons.arrow_upward;
      default:
        return Icons.swap_horiz;
    }
  }

  Color get _typeColor {
    switch (bookmark.type) {
      case 'income':
        return AppColors.income;
      case 'expense':
        return AppColors.expense;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(_typeIcon, color: _typeColor),
      title: Text(bookmark.name, style: AppTypography.body),
      subtitle: bookmark.amount != null
          ? Text(
              bookmark.amount!.toStringAsFixed(2),
              style: AppTypography.caption1
                  .copyWith(color: AppColors.textSecondary),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon:
                const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            onPressed: () =>
                BookmarksScreen._showAddEditSheet(context, bookmark),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => ref
                .read(bookmarksNotifierProvider.notifier)
                .delete(bookmark.id),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_outline,
              size: 72,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No bookmarks yet',
              style:
                  AppTypography.title3.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Save a transaction template to quickly add it later.',
              style: AppTypography.subhead
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
