// go_router configuration with 4-tab StatefulShellRoute — Epic 8A IA refactor.
// Tab order: Home | Transactions | Budget | More
// Accounts is accessible as a nested route under /more/accounts.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/account.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/transaction.dart';
import '../../features/accounts/presentation/screens/account_add_edit_screen.dart';
import '../../features/accounts/presentation/screens/accounts_screen.dart';
import '../../features/budget/presentation/screens/budget_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/more/presentation/screens/budget_setting_screen.dart';
import '../../features/more/presentation/screens/category_management_screen.dart';
import '../../features/more/presentation/screens/more_screen.dart';
import '../../features/more/presentation/screens/settings_screen.dart';
import '../../features/transactions/presentation/screens/bookmarks_screen.dart';
import '../../features/transactions/presentation/screens/transaction_add_edit_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../i18n/arb/app_localizations.dart';
import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: Routes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithBottomNav(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0 — Home tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Branch 1 — Transactions tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.transactions,
              builder: (context, state) => const TransactionsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) {
                    final extra = state.extra;
                    if (extra is Bookmark) {
                      return TransactionAddEditScreen(prefillBookmark: extra);
                    }
                    return TransactionAddEditScreen(
                      transaction: extra as Transaction?,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Branch 2 — Budget tab (promoted from Stats sub-tab, EPIC8A-01)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.budget,
              builder: (context, state) => const BudgetScreen(),
            ),
          ],
        ),
        // Branch 3 — More tab (Accounts relocated here, EPIC8A-01)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.more,
              builder: (context, state) => const MoreScreen(),
              routes: [
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                  routes: [
                    GoRoute(
                      path: 'categories',
                      builder: (context, state) =>
                          const CategoryManagementScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'budget-setting',
                  builder: (context, state) => const BudgetSettingScreen(),
                ),
                GoRoute(
                  path: 'bookmarks',
                  builder: (context, state) => const BookmarksScreen(),
                ),
                // Accounts relocated from top-level tab to More sub-page (EPIC8A-01)
                GoRoute(
                  path: 'accounts',
                  builder: (context, state) => const AccountsScreen(),
                  routes: [
                    GoRoute(
                      path: 'add',
                      builder: (context, state) => AccountAddEditScreen(
                        account: state.extra as Account?,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Bottom-navigation shell shared across all top-level tabs.
class ScaffoldWithBottomNav extends StatelessWidget {
  const ScaffoldWithBottomNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.tabTransactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.savings_outlined),
            selectedIcon: const Icon(Icons.savings),
            label: l10n.tabBudget,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view),
            label: l10n.tabMore,
          ),
        ],
      ),
    );
  }
}
