// RecentTransactionsList — compact home-tab section showing the 2 most recent
// transactions with a "All →" link — home feature (EPIC8A-09).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/transaction.dart';
import '../../../../domain/entities/transaction_with_details.dart';
import '../providers/recent_transactions_provider.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Renders the "Recent" section on the Home tab.
///
/// Shows at most 2 transactions. When the list is empty the widget returns
/// [SizedBox.shrink] so the parent scaffold hides the slot entirely.
///
/// Data is sourced from [recentTransactionsProvider]; [onSeeAllTap] is wired
/// by [HomeScreen] to navigate to the Transactions tab.
class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({
    super.key,
    required this.onSeeAllTap,
  });

  final VoidCallback onSeeAllTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTxs = ref.watch(recentTransactionsProvider);

    return asyncTxs.when(
      loading: () => const _RecentShimmer(),
      error: (_, __) => _RecentError(onSeeAllTap: onSeeAllTap),
      data: (txs) {
        if (txs.isEmpty) return const SizedBox.shrink();
        final visible = txs.take(2).toList();
        return _RecentContent(
          transactions: visible,
          onSeeAllTap: onSeeAllTap,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Content state (1–2 transactions)
// ---------------------------------------------------------------------------

class _RecentContent extends StatelessWidget {
  const _RecentContent({
    required this.transactions,
    required this.onSeeAllTap,
  });

  final List<TransactionWithDetails> transactions;
  final VoidCallback onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;

    final containerBg =
        isDark ? AppColors.bgSecondary : AppColors.bgElevatedLight;
    final containerBorder = isDark ? AppColors.border : AppColors.borderLight;

    return Semantics(
      label: 'Recent transactions. ${transactions.length} shown.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ----- Section header -----
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              18,
              AppSpacing.lg,
              10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.homeRecentTitle.toUpperCase(),
                  style: AppTypography.caption2.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                Semantics(
                  label: 'View all transactions',
                  button: true,
                  child: GestureDetector(
                    onTap: onSeeAllTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      // Extend tap target inward to satisfy 44×44 minimum
                      padding: const EdgeInsets.only(
                        left: AppSpacing.lg,
                        top: 16,
                        bottom: 16,
                      ),
                      child: Text(
                        '${l10n.homeRecentAll} →',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ----- List container -----
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: containerBg,
              border: Border.all(color: containerBorder),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: isDark
                  ? const []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Column(
                children: [
                  Semantics(
                    label: _rowSemanticLabel(transactions[0], l10n),
                    button: true,
                    child: ExcludeSemantics(
                      child: _RecentTransactionRow(
                        details: transactions[0],
                      ),
                    ),
                  ),
                  if (transactions.length > 1) ...[
                    ExcludeSemantics(child: _InsetDivider()),
                    Semantics(
                      label: _rowSemanticLabel(transactions[1], l10n),
                      button: true,
                      child: ExcludeSemantics(
                        child: _RecentTransactionRow(
                          details: transactions[1],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rowSemanticLabel(
    TransactionWithDetails details,
    AppLocalizations l10n,
  ) {
    final tx = details.transaction;
    final amountStr = _semanticAmount(tx, l10n);
    final name = resolveDisplayName(tx, details.categoryName, l10n);
    return '$name. $amountStr. Tap for details.';
  }

  /// 3-step display-name fallback:
  ///   1. transaction.description — if non-null and non-empty.
  ///   2. categoryName — if available.
  ///   3. type string — resolved via [AppLocalizations] (never hard-coded English).
  static String resolveDisplayName(
    Transaction tx,
    String? categoryName,
    AppLocalizations l10n,
  ) {
    if (tx.description?.isNotEmpty == true) {
      return tx.description!;
    }
    if (categoryName != null && categoryName.isNotEmpty) {
      return categoryName;
    }
    switch (tx.transactionType) {
      case TransactionType.income:
        return l10n.income;
      case TransactionType.expense:
        return l10n.expense;
      case TransactionType.transfer:
        return l10n.transfer;
    }
  }

  String _semanticAmount(Transaction tx, AppLocalizations l10n) {
    final abs = tx.amount.abs();
    final formatted = CurrencyFormatter.format(abs);
    switch (tx.transactionType) {
      case TransactionType.income:
        return l10n.semanticAmountPositive(formatted);
      case TransactionType.expense:
        return l10n.semanticAmountNegative(formatted);
      case TransactionType.transfer:
        return formatted;
    }
  }
}

// ---------------------------------------------------------------------------
// Individual transaction row
// ---------------------------------------------------------------------------

class _RecentTransactionRow extends StatelessWidget {
  const _RecentTransactionRow({required this.details});

  final TransactionWithDetails details;

  Transaction get _tx => details.transaction;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final l10n = AppLocalizations.of(context)!;
    final displayName =
        _RecentContent.resolveDisplayName(_tx, details.categoryName, l10n);

    // Show the category name as subtitle only when it is available AND different
    // from the resolved display name (avoids duplicate lines such as
    // title="Salary" / subtitle="Salary").
    final showSubtitle = details.categoryName != null &&
        details.categoryName!.isNotEmpty &&
        details.categoryName != displayName;

    return InkWell(
      onTap: () => _openDetail(context),
      splashColor: AppColors.brandPrimaryGlow,
      highlightColor: AppColors.brandPrimaryGlow,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category icon container
            ExcludeSemantics(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _iconBgColor(context),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: _buildIcon(context),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Title + optional subtitle column
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showSubtitle)
                    Text(
                      details.categoryName!,
                      style: AppTypography.caption1.copyWith(
                        color: context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Signed amount
            Text(
              _formattedAmount,
              style: AppTypography.moneySmall.copyWith(
                color: _amountColor(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _formattedAmount {
    final formatted = CurrencyFormatter.format(_tx.amount.abs());
    switch (_tx.transactionType) {
      case TransactionType.income:
        return '+$formatted';
      case TransactionType.expense:
        // U+2212 MINUS SIGN — not a hyphen
        return '−$formatted';
      case TransactionType.transfer:
        return formatted;
    }
  }

  Color _amountColor(bool isDark) {
    switch (_tx.transactionType) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return isDark ? AppColors.expenseDark : AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }

  Color _iconBgColor(BuildContext context) {
    switch (_tx.transactionType) {
      case TransactionType.income:
        return AppColors.income.withAlpha(38);
      case TransactionType.expense:
        return context.expenseColor.withAlpha(38);
      case TransactionType.transfer:
        return context.bgTertiary;
    }
  }

  // No category emoji available without JOIN — use type icon.
  // Income = money coming IN → upward arrow.
  // Expense = money going OUT → downward arrow.
  // Transfer = swap horizontal.
  Widget _buildIcon(BuildContext context) {
    switch (_tx.transactionType) {
      case TransactionType.income:
        return const Icon(Icons.arrow_upward,
            size: 16, color: AppColors.income);
      case TransactionType.expense:
        return Icon(Icons.arrow_downward,
            size: 16, color: context.expenseColor);
      case TransactionType.transfer:
        return Icon(Icons.swap_horiz, size: 16, color: context.textSecondary);
    }
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetailPreview(details: details),
    );
  }
}

// ---------------------------------------------------------------------------
// Minimal detail preview sheet (until full TransactionDetailSheet is wired)
// ---------------------------------------------------------------------------

class _TransactionDetailPreview extends StatelessWidget {
  const _TransactionDetailPreview({required this.details});

  final TransactionWithDetails details;

  @override
  Widget build(BuildContext context) {
    final tx = details.transaction;
    final isDark = context.isDark;
    final l10n = AppLocalizations.of(context)!;
    final bgColor = isDark ? AppColors.bgSecondary : AppColors.bgElevatedLight;
    final typeLabel = switch (tx.transactionType) {
      TransactionType.income => l10n.income,
      TransactionType.expense => l10n.expense,
      TransactionType.transfer => l10n.transfer,
    };
    final displayName =
        _RecentContent.resolveDisplayName(tx, details.categoryName, l10n);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.textTertiary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            typeLabel,
            style: AppTypography.headline.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            CurrencyFormatter.format(tx.amount.abs()),
            style: AppTypography.moneyLarge.copyWith(
              color: switch (tx.transactionType) {
                TransactionType.income => AppColors.income,
                TransactionType.expense =>
                  isDark ? AppColors.expenseDark : AppColors.expense,
                TransactionType.transfer => context.textSecondary,
              },
            ),
          ),
          if (displayName != typeLabel) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              displayName,
              style:
                  AppTypography.subhead.copyWith(color: context.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading shimmer state
// ---------------------------------------------------------------------------

class _RecentShimmer extends StatelessWidget {
  const _RecentShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final baseColor = isDark ? AppColors.bgTertiary : AppColors.bgTertiaryLight;
    final highlightColor =
        isDark ? AppColors.bgSecondary : AppColors.bgSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(AppSpacing.lg, 18, AppSpacing.lg, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(
                width: 50,
                height: 10,
                base: baseColor,
                highlight: highlightColor,
              ),
              _ShimmerBox(
                width: 28,
                height: 10,
                base: baseColor,
                highlight: highlightColor,
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSecondary : AppColors.bgElevatedLight,
            border: Border.all(
              color: isDark ? AppColors.border : AppColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Column(
              children: [
                _ShimmerRow(base: baseColor, highlight: highlightColor),
                Container(
                  margin: const EdgeInsets.only(left: 54),
                  height: 1,
                  color: baseColor,
                ),
                _ShimmerRow(base: baseColor, highlight: highlightColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow({required this.base, required this.highlight});

  final Color base;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: 14,
      ),
      child: Row(
        children: [
          _ShimmerBox(
            width: 32,
            height: 32,
            base: base,
            highlight: highlight,
            radius: AppRadius.sm,
          ),
          const SizedBox(width: AppSpacing.sm),
          _ShimmerBox(width: 120, height: 14, base: base, highlight: highlight),
          const Spacer(),
          _ShimmerBox(width: 70, height: 14, base: base, highlight: highlight),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.base,
    required this.highlight,
    this.radius = 4,
  });

  final double width;
  final double height;
  final Color base;
  final Color highlight;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _RecentError extends StatelessWidget {
  const _RecentError({required this.onSeeAllTap});

  final VoidCallback onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(AppSpacing.lg, 18, AppSpacing.lg, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.homeRecentTitle.toUpperCase(),
                style: AppTypography.caption2.copyWith(
                  color: context.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: onSeeAllTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    top: 16,
                    bottom: 16,
                  ),
                  child: Text(
                    '${l10n.homeRecentAll} →',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSecondary : AppColors.bgElevatedLight,
            border: Border.all(
              color: isDark ? AppColors.border : AppColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          height: AppHeights.listItem,
          child: Center(
            child: Text(
              l10n.homeRecentCouldNotLoad,
              style: AppTypography.caption1.copyWith(
                color: context.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Inset divider
// ---------------------------------------------------------------------------

class _InsetDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      margin: const EdgeInsets.only(left: 54),
      height: 1,
      color: isDark ? AppColors.divider : AppColors.bgTertiaryLight,
    );
  }
}
