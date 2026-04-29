// NoteView — note sub-tab content within StatsScreen — stats feature (US-030).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../providers/note_provider.dart';
import '../providers/stats_provider.dart';

/// Displays the Note sub-tab inside StatsScreen.
class NoteView extends ConsumerWidget {
  const NoteView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(noteGroupsProvider);
    final sortMode = ref.watch(noteSortModeProvider);
    final statsType = ref.watch(statsTypeProvider);

    return Column(
      children: [
        _NoteListHeader(
          sortMode: sortMode,
          onToggleSort: () => ref.read(noteSortModeProvider.notifier).toggle(),
        ),
        Expanded(
          child: groupsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brandPrimary),
            ),
            error: (_, __) => _ErrorState(
              onRetry: () => ref.invalidate(noteGroupsProvider),
            ),
            data: (groups) {
              if (groups.isEmpty) return const _EmptyState();
              return _NoteGroupList(
                groups: groups,
                statsType: statsType,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _NoteListHeader extends StatelessWidget {
  const _NoteListHeader({
    required this.sortMode,
    required this.onToggleSort,
  });

  final String sortMode;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sortLabel =
        sortMode == 'amount' ? l10n.noteViewSortAmount : l10n.noteViewSortCount;

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Text(
            l10n.noteColumnLabel,
            style:
                AppTypography.footnote.copyWith(color: AppColors.textSecondary),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: onToggleSort,
                child: Semantics(
                  label:
                      'Sort by $sortLabel, currently sorted by $sortMode. Double-tap to change.',
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_downward,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          sortLabel,
                          style: AppTypography.footnote
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.expand_more,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            l10n.amountColumnLabel,
            style:
                AppTypography.footnote.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NoteGroupList
// ---------------------------------------------------------------------------

class _NoteGroupList extends StatefulWidget {
  const _NoteGroupList({
    required this.groups,
    required this.statsType,
  });

  final List<NoteGroup> groups;
  final String statsType;

  @override
  State<_NoteGroupList> createState() => _NoteGroupListState();
}

class _NoteGroupListState extends State<_NoteGroupList> {
  final Set<int> _collapsedGroups = {};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: widget.groups.length,
      itemBuilder: (context, i) {
        final group = widget.groups[i];
        final isCollapsed = _collapsedGroups.contains(i);
        final amountColor =
            widget.statsType == 'income' ? AppColors.income : AppColors.expense;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NoteGroupHeader(
              note: group.note,
              count: group.count,
              totalAmount: group.totalAmount,
              amountColor: amountColor,
              isExpanded: !isCollapsed,
              onTap: () => setState(() {
                if (isCollapsed) {
                  _collapsedGroups.remove(i);
                } else {
                  _collapsedGroups.add(i);
                }
              }),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              child: isCollapsed
                  ? const SizedBox.shrink()
                  : Column(
                      children: group.transactions
                          .map(
                            (t) => _NoteTransactionRow(
                              transaction: t,
                              amountColor: amountColor,
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// NoteGroupHeader
// ---------------------------------------------------------------------------

class _NoteGroupHeader extends StatelessWidget {
  const _NoteGroupHeader({
    required this.note,
    required this.count,
    required this.totalAmount,
    required this.amountColor,
    required this.isExpanded,
    required this.onTap,
  });

  final String? note;
  final int count;
  final double totalAmount;
  final Color amountColor;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isNoNote = note == null;
    final noteText = isNoNote ? l10n.noteViewNoNote : note!;

    return Semantics(
      label:
          'Group: $noteText. $count transactions, total ${CurrencyFormatter.format(totalAmount)}.',
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          color: AppColors.bgTertiary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  noteText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isNoNote
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    fontStyle: isNoNote ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.caption2
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                CurrencyFormatter.format(totalAmount),
                style: AppTypography.moneySmall.copyWith(color: amountColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NoteTransactionRow
// ---------------------------------------------------------------------------

class _NoteTransactionRow extends ConsumerWidget {
  const _NoteTransactionRow({
    required this.transaction,
    required this.amountColor,
  });

  final Transaction transaction;
  final Color amountColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('MMM d');

    Future<void> deleteTransaction() async {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: Text(
            l10n.noteViewDeleteConfirmTitle,
            style:
                AppTypography.headline.copyWith(color: AppColors.textPrimary),
          ),
          content: Text(
            l10n.noteViewDeleteConfirmMessage,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.deleteAction,
                  style: const TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      if (!context.mounted) return;

      await ref
          .read(transactionWriteNotifierProvider.notifier)
          .deleteTransaction(transaction.id);
    }

    return Semantics(
      label: 'Transaction. ${CurrencyFormatter.format(transaction.amount)}. '
          '${fmt.format(transaction.date)}. Double-tap to view details.',
      child: Dismissible(
        key: Key('note-tx-${transaction.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          await deleteTransaction();
          return false; // Provider updates reactively; no need to dismiss.
        },
        background: Container(
          color: AppColors.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: Container(
          height: 52,
          color: AppColors.bgSecondary,
          padding: const EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.lg,
          ),
          child: Row(
            children: [
              // Category icon circle placeholder
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Center(
                  child: Icon(
                    Icons.receipt_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      transaction.categoryId ?? '—',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      fmt.format(transaction.date),
                      style: AppTypography.caption1
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(transaction.amount),
                style: AppTypography.moneySmall.copyWith(color: amountColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.note_alt_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.noteViewNoNotes,
              style:
                  AppTypography.title3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.noteViewNoNotesSubtitle,
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.noteViewCouldNotLoad,
            style:
                AppTypography.headline.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            child: Text(
              l10n.retryButton,
              style:
                  AppTypography.subhead.copyWith(color: AppColors.brandPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
