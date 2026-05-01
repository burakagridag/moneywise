// HomeScreen scaffold with section placeholders — home feature.
// Structural scaffold for EPIC8A Phase 2 component stories to slot into.
// Real components are implemented in EPIC8A-05 through EPIC8A-10.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart'; // AppSpacing, AppRadius
import '../../../../core/constants/app_typography.dart';

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
                  // Slot 1 — HomeHeader
                  // Implemented in EPIC8A-05.
                  const _HomeHeaderPlaceholder(),

                  // Slot 2 — TotalBalanceCard
                  // Implemented in EPIC8A-06.
                  const _TotalBalanceCardPlaceholder(),
                  const SizedBox(height: AppSpacing.md),

                  // Slot 3 — BudgetPulseCard
                  // Implemented in EPIC8A-07.
                  const _BudgetPulseCardPlaceholder(),
                  const SizedBox(height: AppSpacing.md),

                  // Slot 4 — ThisWeekSection (InsightCards)
                  // Conditionally hidden when 0 insights. Implemented in EPIC8A-08.
                  const _ThisWeekSectionPlaceholder(),
                  const SizedBox(height: AppSpacing.md),

                  // Slot 5 — RecentSection (RecentTransactionsList)
                  // Conditionally hidden when 0 transactions. Implemented in EPIC8A-09.
                  const _RecentSectionPlaceholder(),
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
// Section placeholder widgets
// Each placeholder approximates the real component's height so the scaffold
// demonstrates the correct scroll rhythm before real widgets arrive.
// ---------------------------------------------------------------------------

/// Placeholder for HomeHeader — implemented in EPIC8A-05.
class _HomeHeaderPlaceholder extends StatelessWidget {
  const _HomeHeaderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Center(
        child: Text(
          'HomeHeader — coming in EPIC8A-05',
          style: AppTypography.caption1.copyWith(color: context.textTertiary),
        ),
      ),
    );
  }
}

/// Placeholder for TotalBalanceCard — implemented in EPIC8A-06.
class _TotalBalanceCardPlaceholder extends StatelessWidget {
  const _TotalBalanceCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
      child: SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'TotalBalanceCard — coming in EPIC8A-06',
            style: AppTypography.caption1.copyWith(color: context.textTertiary),
          ),
        ),
      ),
    );
  }
}

/// Placeholder for BudgetPulseCard — implemented in EPIC8A-07.
class _BudgetPulseCardPlaceholder extends StatelessWidget {
  const _BudgetPulseCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
      child: SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'BudgetPulseCard — coming in EPIC8A-07',
            style: AppTypography.caption1.copyWith(color: context.textTertiary),
          ),
        ),
      ),
    );
  }
}

/// Placeholder for ThisWeekSection (InsightCards) — implemented in EPIC8A-08.
///
/// Conditionally hidden in Phase 2 when the insights list is empty.
class _ThisWeekSectionPlaceholder extends StatelessWidget {
  const _ThisWeekSectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
      child: SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'ThisWeekSection (InsightCards) — coming in EPIC8A-08',
            style: AppTypography.caption1.copyWith(color: context.textTertiary),
          ),
        ),
      ),
    );
  }
}

/// Placeholder for RecentSection (RecentTransactionsList) — implemented in EPIC8A-09.
///
/// Conditionally hidden in Phase 2 when there are no transactions.
class _RecentSectionPlaceholder extends StatelessWidget {
  const _RecentSectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
      child: SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'RecentSection (RecentTransactionsList) — coming in EPIC8A-09',
            style: AppTypography.caption1.copyWith(color: context.textTertiary),
          ),
        ),
      ),
    );
  }
}

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
