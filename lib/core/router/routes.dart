// Route path constants for go_router navigation.

class Routes {
  Routes._();

  static const String transactions = '/transactions';
  static const String stats = '/stats';
  static const String accounts = '/accounts';
  static const String more = '/more';

  // Sprint 2 routes
  static const String accountAddEdit = '/accounts/add';
  static const String settings = '/more/settings';
  static const String categoryManagement = '/more/settings/categories';

  // Sprint 3 routes
  static const String transactionAddEdit = '/transactions/add';

  // Sprint 4 routes — alias used by FAB in TransactionsScreen
  static const String addTransaction = '/add-transaction';
}
