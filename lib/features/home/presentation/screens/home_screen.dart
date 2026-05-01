// HomeScreen scaffold — home feature (EPIC8A-03, updated EPIC8A-08).
// ThisWeekSection (InsightCards) is now live; other slots remain as placeholders
// until EPIC8A-09 through EPIC8A-10 replace them.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart'; // AppSpacing, AppRadius
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/routes.dart';
import '../widgets/budget_pulse_card.dart';
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

    // TODO(EPIC8A-13): tab focus invalidation stub
    // Options per ADR-011 §Reactive Behaviour:
    //   a) Listen to go_router RouteInformationProvider, invalidate on /home.
    //   b) Use a Riverpod Listener on transactionMutationSignalProvider
    //      (StateProvider<int> incremented on any mutation).
    // Chosen approach will be documented in the PR description.

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brandPrimary,
          onRefresh: () async {
            // TODO(EPIC8A-11): invalidate home data providers on pull-to-refresh.
            // ref.invalidate(insightsProvider);
            // ref.invalidate(sparklineDataProvider);
            // ref.invalidate(recentTransactionsProvider);
            // ref.invalidate(budgetPulseProvider);
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

                    // Slot 6 — EmptyState
                    // Shown only when 0 transactions ever. Implemented in EPIC8A-10.
                    const _EmptyStatePlaceholder(),

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

// ---------------------------------------------------------------------------
// Section placeholder widgets — remaining until EPIC8A-09 and EPIC8A-10
// ---------------------------------------------------------------------------

/// Placeholder for EmptyState — implemented in EPIC8A-10.
///
/// Replaces sections 2–5 when the user has no transaction history.
class _EmptyStatePlaceholder extends StatelessWidget {
  const _EmptyStatePlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Center(
        child: Text(
          'EmptyState — coming in EPIC8A-10',
          style: AppTypography.caption1.copyWith(color: context.textTertiary),
        ),
      ),
    );
  }
}
