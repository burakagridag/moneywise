// TransactionsView — 3-tab (Liste / Takvim / Özet) layout widget for the
// redesigned Transactions screen — features/transactions EPIC8D-01.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../providers/search_filter_provider.dart';
import '../providers/transactions_provider.dart';
import 'transactions_calendar_tab.dart';
import 'transactions_empty_state.dart';
import 'transactions_list_tab.dart';
import 'transactions_summary_strip.dart';
import 'transactions_summary_tab.dart';

/// Index of the Liste tab — used by the calendar day-tap to switch.
const int kListTabIndex = 0;

/// Total number of tabs in the redesigned screen.
const int kTabCount = 3;

/// Main 3-tab view widget. Accepts an externally created [TabController] so
/// that the parent [TransactionsScreen] can read its index for MonthNavigator.
class TransactionsView extends ConsumerWidget {
  const TransactionsView({
    super.key,
    required this.tabController,
  });

  final TabController tabController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AC: when the selected month has zero transactions, show empty state
    // without the tab bar (US-EPIC8D-01).
    final asyncTxs = ref.watch(filteredTransactionsProvider);
    if (asyncTxs.asData?.value.isEmpty == true) {
      return const TransactionsEmptyState();
    }

    final totalsAsync = ref.watch(monthlyTotalsProvider);
    final (income, expense) = totalsAsync.when(
      data: (t) => (t.income, t.expense),
      loading: () => (0.0, 0.0),
      error: (_, __) => (0.0, 0.0),
    );

    return Column(
      children: [
        // Period tab bar
        _PeriodTabBar(controller: tabController),

        // Shared Income / Expense / Net strip
        TransactionsSummaryStrip(income: income, expense: expense),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              // Tab 0: Liste
              const TransactionsListTab(),

              // Tab 1: Takvim — tapping a day switches to Liste tab.
              TransactionsCalendarTab(
                onDaySelected: (_) => tabController.animateTo(kListTabIndex),
              ),

              // Tab 2: Özet
              const TransactionsSummaryTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Period tab bar — 3 tabs
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
        isScrollable: false,
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
            label: '${l10n.transactionsTabList} view tab.',
            selected: controller.index == 0,
            child: Tab(text: l10n.transactionsTabList),
          ),
          Semantics(
            label: '${l10n.transactionsTabCalendar} view tab.',
            selected: controller.index == 1,
            child: Tab(text: l10n.transactionsTabCalendar),
          ),
          Semantics(
            label: '${l10n.transactionsTabSummary} view tab.',
            selected: controller.index == 2,
            child: Tab(text: l10n.transactionsTabSummary),
          ),
        ],
      ),
    );
  }
}
