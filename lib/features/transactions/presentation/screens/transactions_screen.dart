// TransactionsScreen — redesigned 3-tab (Liste / Takvim / Özet) scaffold —
// features/transactions EPIC8D-01 / ADR-015.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../widgets/bookmark_picker_modal.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/month_navigator.dart';
import '../widgets/transaction_search_bar.dart';
import '../widgets/transactions_view.dart';

/// Root screen for the Transactions bottom-nav tab (EPIC8D-01 redesign).
/// Hosts MonthNavigator, 3-tab period selector, shared summary strip,
/// and the three sub-views (Liste / Takvim / Özet).
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: kTabCount, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  void _toggleSearchBar() {
    setState(() => _showSearchBar = !_showSearchBar);
  }

  void _showBookmarkPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookmarkPickerModal(),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        elevation: 0,
        leading: Semantics(
          label: l10n.transactionsSearchHint,
          button: true,
          child: IconButton(
            icon: Icon(Icons.search, color: context.textSecondary),
            onPressed: _toggleSearchBar,
          ),
        ),
        title: Text(l10n.transactionsTitle, style: AppTypography.title2),
        centerTitle: false,
        actions: [
          Semantics(
            label: l10n.transactionsBookmarksTitle,
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.bookmark_outline,
                color: context.textSecondary,
              ),
              onPressed: () => _showBookmarkPicker(context),
            ),
          ),
          Semantics(
            label: l10n.transactionsFilterTitle,
            button: true,
            child: IconButton(
              icon: Icon(Icons.tune, color: context.textSecondary),
              onPressed: () => _showFilterSheet(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Animated search bar below AppBar
          TransactionSearchBar(isVisible: _showSearchBar),

          // Month / Year navigator (no year-only mode in 3-tab redesign)
          const MonthNavigator(showYearOnly: false),

          // 3-tab view (tab bar + summary strip + tab content)
          Expanded(
            child: TransactionsView(tabController: _tabController),
          ),
        ],
      ),
      floatingActionButton: const _Fabs(),
    );
  }
}

// ---------------------------------------------------------------------------
// FABs
// ---------------------------------------------------------------------------

class _Fabs extends StatelessWidget {
  const _Fabs();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bookmark mini-FAB
          Semantics(
            label: 'Add from bookmark',
            button: true,
            child: SizedBox(
              width: 44,
              height: 44,
              child: FloatingActionButton(
                heroTag: 'bookmark_fab',
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const BookmarkPickerModal(),
                  );
                },
                backgroundColor: context.bgSecondary,
                elevation: 2,
                mini: true,
                child: Icon(
                  Icons.bookmark_outline,
                  color: context.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Add transaction FAB
          Semantics(
            label: 'Add new transaction',
            button: true,
            child: FloatingActionButton(
              heroTag: 'add_transaction_fab',
              onPressed: () => context.push(Routes.transactionAddEdit),
              backgroundColor: AppColors.brandPrimary,
              child: const Icon(
                Icons.add,
                color: AppColors.textOnBrand,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
