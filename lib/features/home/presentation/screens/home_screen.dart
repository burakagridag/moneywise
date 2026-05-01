// HomeScreen scaffold — home feature (EPIC8A-03, updated EPIC8A-11).
// Pull-to-refresh invalidation and tab-focus mutation signal wired (EPIC8A-11).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart'; // AppSpacing, AppRadius
import '../../../../core/router/routes.dart';
import '../../../insights/presentation/providers/insights_providers.dart';
import '../../../transactions/presentation/providers/transaction_mutation_signal_provider.dart';
import '../providers/net_worth_provider.dart';
import '../providers/user_settings_providers.dart';
import '../widgets/budget_pulse_card.dart';
import '../widgets/empty_state_cards.dart';
import '../widgets/home_header.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/this_week_section.dart';
import '../widgets/total_balance_card.dart';

/// Structural scaffold for the Home tab.
///
/// Contains [RefreshIndicator] wrapping a [CustomScrollView] with six named
/// section slots in the order mandated by the UX spec (spec.md). Each slot is
/// a labeled placeholder widget sized to approximate the final component.
///
/// Phase 2 stories (EPIC8A-05 through EPIC8A-10) replace placeholders with
/// real widgets without needing to modify this scaffold structure.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(EPIC8A-12): fire home_tab_viewed analytics event on initState

    // Tab focus invalidation — mutation signal approach (ADR-011 §Reactive
    // Behaviour, Option B). When any transaction is added, edited, or deleted,
    // TransactionWriteNotifier increments transactionMutationSignalProvider.
    // This listener fires on the next build cycle and invalidates non-streaming
    // home providers so the Home tab shows fresh data the next time the user
    // navigates here without needing a manual pull-to-refresh.
    ref.listen(transactionMutationSignalProvider, (_, __) {
      ref.invalidate(insightsProvider);
      ref.invalidate(previousMonthTotalProvider);
    });

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brandPrimary,
          onRefresh: () async {
            // Capture a fresh timestamp inside the callback to avoid stale
            // references to the `now` value captured at build time.
            final month = DateTime(DateTime.now().year, DateTime.now().month);
            ref.invalidate(insightsProvider);
            ref.invalidate(previousMonthTotalProvider);
            ref.invalidate(effectiveBudgetProvider(month));
            // sparklineDataProvider and recentTransactionsProvider are
            // StreamProviders — they update automatically via Drift streams
            // and do not need explicit invalidation (ADR-011).
            await ref.read(insightsProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Slot 1 — HomeHeader (EPIC8A-05)
                    HomeHeader(
                      currentDate: DateTime.now(),
                      onAvatarTap: () => context.go(Routes.more),
                    ),

                    // Slot 2 — TotalBalanceCard (EPIC8A-06)
                    const TotalBalanceCard(),
                    const SizedBox(height: AppSpacing.md),

                    // Slot 3 — BudgetPulseCard (EPIC8A-07)
                    const BudgetPulseCard(),
                    const SizedBox(height: AppSpacing.md),

                    // Slot 4 — ThisWeekSection (InsightCards) — EPIC8A-08.
                    // Hides itself (SizedBox.shrink) when insightsProvider returns [].
                    const ThisWeekSection(),
                    const SizedBox(height: AppSpacing.md),

                    // Slot 5 — RecentSection (RecentTransactionsList) — EPIC8A-09
                    // Hides itself (SizedBox.shrink) when there are no transactions.
                    RecentTransactionsList(
                      onSeeAllTap: () => context.go(Routes.transactions),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Slot 6 — EmptyState (EPIC8A-10)
                    // Auto-dismisses when recentTransactionsProvider emits ≥1 transaction.
                    const EmptyStateCards(),

                    const SizedBox(height: AppSpacing.xxl),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
