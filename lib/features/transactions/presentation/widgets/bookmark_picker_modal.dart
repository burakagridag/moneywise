// Modal bottom sheet for selecting a bookmark to pre-fill the transaction form — transactions feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../domain/entities/bookmark.dart';
import '../providers/bookmark_provider.dart';
import 'bookmark_list_item.dart';

/// Modal bottom sheet that lists all saved bookmarks.
/// Tapping a bookmark pre-fills the transaction form.
/// If the bookmark list is empty, navigates to [BookmarksScreen] instead.
class BookmarkPickerModal extends ConsumerWidget {
  const BookmarkPickerModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncBookmarks = ref.watch(bookmarksStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.bgSecondary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            boxShadow: context.isDark
                ? null
                : [
                    const BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.bookmarkPickerTitle, style: AppTypography.title3),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push(Routes.bookmarks);
                      },
                      child: Text(l10n.bookmarkPickerGoToBookmarks),
                    ),
                  ],
                ),
              ),
              Divider(color: context.dividerColor, height: 1),
              Expanded(
                child: asyncBookmarks.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  error: (e, __) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 40, color: AppColors.error),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AppLocalizations.of(context)!.errorLoadTitle,
                          style: AppTypography.body
                              .copyWith(color: context.textPrimary),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(bookmarksStreamProvider),
                          child: Text(
                            AppLocalizations.of(context)!.retryButton,
                            style: AppTypography.subhead
                                .copyWith(color: AppColors.brandPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  data: (bookmarks) {
                    if (bookmarks.isEmpty) {
                      return _EmptyPickerState(
                        onManage: () {
                          Navigator.of(context).pop();
                          context.push(Routes.bookmarks);
                        },
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      itemCount: bookmarks.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: AppSpacing.lg,
                      ),
                      itemBuilder: (context, index) {
                        final bookmark = bookmarks[index];
                        return BookmarkListItem(
                          bookmark: bookmark,
                          onTap: () => _useBookmark(context, bookmark),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _useBookmark(BuildContext context, Bookmark bookmark) {
    Navigator.of(context).pop();
    context.push(Routes.transactionAddEdit, extra: bookmark);
  }
}

class _EmptyPickerState extends StatelessWidget {
  const _EmptyPickerState({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 64,
              color: context.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.bookmarkPickerEmpty,
              style: AppTypography.body.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onManage,
              child: Text(l10n.bookmarkPickerGoToBookmarks),
            ),
          ],
        ),
      ),
    );
  }
}
