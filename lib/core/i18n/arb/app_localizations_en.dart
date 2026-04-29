// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MoneyWise';

  @override
  String get tabTransactions => 'Trans.';

  @override
  String get tabStats => 'Stats';

  @override
  String get tabAccounts => 'Accounts';

  @override
  String get tabMore => 'More';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get transfer => 'Transfer';

  @override
  String get amount => 'Amount';

  @override
  String get category => 'Category';

  @override
  String get account => 'Account';

  @override
  String get note => 'Note';

  @override
  String get description => 'Description';

  @override
  String get date => 'Date';

  @override
  String get settings => 'Settings';

  @override
  String get accounts => 'Accounts';

  @override
  String get addAccount => 'Add Account';

  @override
  String get editAccount => 'Edit Account';

  @override
  String get accountName => 'Account Name';

  @override
  String get accountGroup => 'Account Group';

  @override
  String get currency => 'Currency';

  @override
  String get initialBalance => 'Initial Balance';

  @override
  String get includeInTotals => 'Include in Totals';

  @override
  String get accountNameRequired => 'Account name is required';

  @override
  String get invalidBalance => 'Please enter a valid number';

  @override
  String get emptyAccountsMessage =>
      'No accounts yet.\nTap + to add your first account.';

  @override
  String get categories => 'Categories';

  @override
  String get addCategory => 'Add Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryNameRequired => 'Category name is required';

  @override
  String get categoryIcon => 'Icon (emoji)';

  @override
  String get emptyCategoriesMessage => 'No categories yet.';

  @override
  String get defaultBadge => 'Default';

  @override
  String get loading => 'Loading...';

  @override
  String get errorSavingAccount => 'Failed to save account. Please try again.';

  @override
  String get errorSavingCategory =>
      'Failed to save category. Please try again.';

  @override
  String get includeInTotalDescription =>
      "Count this account's balance in your total net worth";

  @override
  String get editCategory => 'Edit Category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get deleteCategoryConfirm =>
      'Are you sure you want to delete this category?';

  @override
  String get errorDeletingCategory =>
      'Failed to delete category. Please try again.';

  @override
  String get errorUpdatingCategory =>
      'Failed to update category. Please try again.';
}
