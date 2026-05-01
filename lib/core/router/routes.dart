// Route path constants for go_router navigation.

class Routes {
  Routes._();

  // Epic 8 — top-level shell tabs
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String budget = '/budget';
  static const String more = '/more';

  // Sprint 2 routes
  static const String settings = '/more/settings';
  static const String categoryManagement = '/more/settings/categories';

  // Sprint 3 routes
  static const String transactionAddEdit = '/transactions/add';

  // Sprint 4 routes — alias used by FAB in TransactionsScreen
  static const String addTransaction = '/add-transaction';

  // Sprint 5 routes
  static const String budgetSetting = '/more/budget-setting';

  // Sprint 6 routes
  static const String bookmarks = '/more/bookmarks';

  // Epic 8 — Accounts relocated under More
  static const String accounts = '/more/accounts';
  static const String accountAddEdit = '/more/accounts/add';
}
