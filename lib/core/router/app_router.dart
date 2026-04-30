// go_router configuration with 4-tab StatefulShellRoute and Sprint 2 sub-routes.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/account.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/transaction.dart';
import '../../features/accounts/presentation/screens/account_add_edit_screen.dart';
import '../../features/accounts/presentation/screens/accounts_screen.dart';
import '../../features/more/presentation/screens/budget_setting_screen.dart';
import '../../features/more/presentation/screens/category_management_screen.dart';
import '../../features/more/presentation/screens/more_screen.dart';
import '../../features/more/presentation/screens/settings_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/transactions/presentation/screens/bookmarks_screen.dart';
import '../../features/transactions/presentation/screens/transaction_add_edit_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../i18n/arb/app_localizations.dart';
import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: Routes.transactions,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithBottomNav(navigationShell: navigationShell);
      },
      branches: [
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.stats,
              builder: (context, state) => const StatsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.accounts,
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
    final now = DateTime.now();
    final dateLabel = '${now.day}.${now.month}';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined),
            activeIcon: const Icon(Icons.book),
            label: dateLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: const Icon(Icons.bar_chart),
            label: l10n.tabStats,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.tabAccounts,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.more_horiz),
            activeIcon: const Icon(Icons.more_horiz),
            label: l10n.tabMore,
          ),
        ],
      ),
    );
  }
}
