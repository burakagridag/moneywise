// BudgetScreen — top-level Budget tab screen — budget feature.
// Wraps BudgetView with a Scaffold and AppBar for standalone tab presentation.
// Previously BudgetView was embedded as a sub-tab inside StatsScreen;
// this screen promotes it to a first-class tab (EPIC8A-01).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../widgets/budget_view.dart';

/// Standalone screen for the Budget tab.
/// Hosts [BudgetView] with a top app bar and a settings action.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        title: Text(l10n.tabBudget, style: AppTypography.title2),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            color: AppColors.brandPrimary,
            tooltip: l10n.budgetSetting,
            onPressed: () => context.push(Routes.budgetSetting),
          ),
        ],
      ),
      body: const BudgetView(),
    );
  }
}
