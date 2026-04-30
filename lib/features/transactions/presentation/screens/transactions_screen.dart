// TransactionsScreen — period tab bar scaffold with Daily, Calendar, Monthly,
// Summary, and Description sub-views — features/transactions US-020 / SPEC-008.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../providers/transactions_provider.dart';
import '../widgets/bookmark_picker_modal.dart';
import '../widgets/calendar_view.dart';
import '../widgets/daily_view.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/income_summary_bar.dart';
import '../widgets/month_navigator.dart';
import '../widgets/monthly_view.dart';
import '../widgets/summary_view.dart';
import '../widgets/transaction_search_bar.dart';

/// Tab index for Monthly tab — used to switch navigator to year-only mode.
const int _monthlyTabIndex = 2;

/// Total number of period tabs — Daily, Calendar, Monthly, Summary, Description.
const int _tabCount = 5;

/// Root screen for the Transactions bottom-nav tab.
/// Hosts MonthNavigator, PeriodTabBar, IncomeSummaryBar, and 4 sub-views.
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
    _tabController = TabController(length: _tabCount, vsync: this);
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
    // Guard: skip rebuild during mid-animation frames to avoid redundant
    // setState calls on every frame of the tab-switch animation.
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  bool get _isMonthlyTab => _tabController.index == _monthlyTabIndex;

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
    final totalsAsync = ref.watch(monthlyTotalsProvider);
    final yearTotalsAsync = ref.watch(yearlyTotalsProvider);

    final (income, expense) = _isMonthlyTab
        ? yearTotalsAsync.when(
            data: (t) => (t.income, t.expense),
            loading: () => (0.0, 0.0),
            error: (_, __) => (0.0, 0.0),
          )
        : totalsAsync.when(
            data: (t) => (t.income, t.expense),
            loading: () => (0.0, 0.0),
            error: (_, __) => (0.0, 0.0),
          );

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        elevation: 0,
        leading: Semantics(
          label: 'Search transactions',
          button: true,
          child: IconButton(
            icon: Icon(Icons.search, color: context.textSecondary),
            onPressed: _toggleSearchBar,
          ),
        ),
        title: Text(l10n.tabTransactions, style: AppTypography.title2),
        centerTitle: false,
        actions: [
          Semantics(
            label: 'Open bookmarks',
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
            label: 'Filter transactions',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.tune,
                color: context.textSecondary,
              ),
              onPressed: () => _showFilterSheet(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Animated search bar below AppBar
          TransactionSearchBar(isVisible: _showSearchBar),
          // Month/Year navigator
          MonthNavigator(showYearOnly: _isMonthlyTab),
          // Period tab bar
          _PeriodTabBar(controller: _tabController),
          // Income / Expense / Total summary bar
          IncomeSummaryBar(income: income, expense: expense),
          // Page content
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              children: const [
                DailyView(),
                CalendarView(),
                MonthlyView(),
                SummaryView(),
                _DescriptionView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: const _Fabs(),
    );
  }
}

// ---------------------------------------------------------------------------
// Period tab bar
// ---------------------------------------------------------------------------

class _PeriodTabBar extends StatelessWidget {
  const _PeriodTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: AppHeights.tabBar,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(
          bottom: BorderSide(color: context.dividerColor, width: 1),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: AppTypography.caption1.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.caption1,
        labelColor: context.textPrimary,
        unselectedLabelColor: context.textSecondary,
        indicatorColor: AppColors.brandPrimary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Semantics(
            label: '${l10n.tabDaily} view tab.',
            selected: controller.index == 0,
            child: Tab(text: l10n.tabDaily),
          ),
          Semantics(
            label: '${l10n.tabCalendar} view tab.',
            selected: controller.index == 1,
            child: Tab(text: l10n.tabCalendar),
          ),
          Semantics(
            label: '${l10n.tabMonthly} view tab.',
            selected: controller.index == 2,
            child: Tab(text: l10n.tabMonthly),
          ),
          Semantics(
            label: '${l10n.tabSummary} view tab.',
            selected: controller.index == 3,
            child: Tab(text: l10n.tabSummary),
          ),
          Semantics(
            label: '${l10n.tabDescription} view tab.',
            selected: controller.index == 4,
            child: Tab(text: l10n.tabDescription),
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(
        bottom: AppSpacing.lg,
        right: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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

// ---------------------------------------------------------------------------
// Description view placeholder
// ---------------------------------------------------------------------------

/// Placeholder for the Description tab — full implementation deferred to a
/// future sprint.
class _DescriptionView extends StatelessWidget {
  const _DescriptionView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Text(
        l10n.comingSoon,
        style: AppTypography.subhead.copyWith(color: context.textSecondary),
      ),
    );
  }
}
