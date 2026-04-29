import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MoneyWise'**
  String get appName;

  /// No description provided for @tabTransactions.
  ///
  /// In en, this message translates to:
  /// **'Trans.'**
  String get tabTransactions;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get tabStats;

  /// No description provided for @tabAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get tabAccounts;

  /// No description provided for @tabMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tabMore;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get editAccount;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @accountGroup.
  ///
  /// In en, this message translates to:
  /// **'Account Group'**
  String get accountGroup;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @initialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get initialBalance;

  /// No description provided for @includeInTotals.
  ///
  /// In en, this message translates to:
  /// **'Include in Totals'**
  String get includeInTotals;

  /// No description provided for @accountNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Account name is required'**
  String get accountNameRequired;

  /// No description provided for @invalidBalance.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get invalidBalance;

  /// No description provided for @emptyAccountsMessage.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet.\nTap + to add your first account.'**
  String get emptyAccountsMessage;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Category name is required'**
  String get categoryNameRequired;

  /// No description provided for @categoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon (emoji)'**
  String get categoryIcon;

  /// No description provided for @emptyCategoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get emptyCategoriesMessage;

  /// No description provided for @defaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultBadge;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorSavingAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to save account. Please try again.'**
  String get errorSavingAccount;

  /// No description provided for @errorSavingCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to save category. Please try again.'**
  String get errorSavingCategory;

  /// No description provided for @includeInTotalDescription.
  ///
  /// In en, this message translates to:
  /// **'Count this account\'s balance in your total net worth'**
  String get includeInTotalDescription;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get deleteCategoryConfirm;

  /// No description provided for @errorDeletingCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category. Please try again.'**
  String get errorDeletingCategory;

  /// No description provided for @errorUpdatingCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to update category. Please try again.'**
  String get errorUpdatingCategory;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransaction;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveAndContinue;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @deleteTransactionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get deleteTransactionConfirm;

  /// No description provided for @errorDeletingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete transaction. Please try again.'**
  String get errorDeletingTransaction;

  /// No description provided for @errorSavingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Failed to save transaction. Please try again.'**
  String get errorSavingTransaction;

  /// No description provided for @noTransactionsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No transactions this month'**
  String get noTransactionsThisMonth;

  /// No description provided for @tapPlusToAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first transaction.'**
  String get tapPlusToAddFirst;

  /// No description provided for @failedToLoadTransactions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load transactions.'**
  String get failedToLoadTransactions;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get toAccount;

  /// No description provided for @summaryIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get summaryIncome;

  /// No description provided for @summaryExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get summaryExpense;

  /// No description provided for @summaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get summaryTotal;

  /// No description provided for @noDataForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get noDataForPeriod;

  /// No description provided for @addTransactionsForBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Add transactions to see your spending breakdown.'**
  String get addTransactionsForBreakdown;

  /// No description provided for @couldNotLoadStatistics.
  ///
  /// In en, this message translates to:
  /// **'Could not load statistics.'**
  String get couldNotLoadStatistics;

  /// No description provided for @pleaseRetryStatistics.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get pleaseRetryStatistics;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @statsSubTabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsSubTabStats;

  /// No description provided for @statsSubTabBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get statsSubTabBudget;

  /// No description provided for @statsSubTabNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get statsSubTabNote;

  /// No description provided for @budgetTrackingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Budget management will be available soon.'**
  String get budgetTrackingComingSoon;

  /// No description provided for @noteSummaryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Note-based summaries will be available soon.'**
  String get noteSummaryComingSoon;

  /// No description provided for @budgetTracking.
  ///
  /// In en, this message translates to:
  /// **'Budget tracking'**
  String get budgetTracking;

  /// No description provided for @spendingNotes.
  ///
  /// In en, this message translates to:
  /// **'Spending notes'**
  String get spendingNotes;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @tabDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get tabDaily;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// No description provided for @tabMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get tabMonthly;

  /// No description provided for @tabSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get tabSummary;

  /// No description provided for @tabDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get tabDescription;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trans.'**
  String get transactionsTitle;

  /// No description provided for @expenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Exp.'**
  String get expenseLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @errorLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get errorLoadTitle;

  /// No description provided for @errorLoadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get errorLoadSubtitle;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @dailyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get dailyEmptyTitle;

  /// No description provided for @dailyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add an income, expense or transfer.'**
  String get dailyEmptySubtitle;

  /// No description provided for @dailyEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get dailyEmptyCta;

  /// No description provided for @deleteTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction?'**
  String get deleteTransactionTitle;

  /// No description provided for @deleteTransactionMessage.
  ///
  /// In en, this message translates to:
  /// **'This transaction will be permanently deleted. This action cannot be undone.'**
  String get deleteTransactionMessage;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @calendarNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get calendarNoTransactions;

  /// No description provided for @calendarDayPanelNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions for this day.\nTap + to add one.'**
  String get calendarDayPanelNoTransactions;

  /// No description provided for @monthlyNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions this month.'**
  String get monthlyNoTransactions;

  /// No description provided for @monthlyCurrentWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get monthlyCurrentWeekLabel;

  /// No description provided for @savingsRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get savingsRateLabel;

  /// No description provided for @accountsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsCardTitle;

  /// No description provided for @budgetCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetCardTitle;

  /// No description provided for @categoryBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending Breakdown'**
  String get categoryBreakdownTitle;

  /// No description provided for @exportToExcelTitle.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportToExcelTitle;

  /// No description provided for @exportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Export feature coming soon'**
  String get exportComingSoon;

  /// No description provided for @setBudgetCta.
  ///
  /// In en, this message translates to:
  /// **'Set Budget'**
  String get setBudgetCta;

  /// No description provided for @budgetNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Budget not configured yet.'**
  String get budgetNotConfigured;

  /// No description provided for @seeAllButton.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAllButton;

  /// No description provided for @noExpensesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No expenses this month.'**
  String get noExpensesThisMonth;

  /// No description provided for @noBudgetThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No budget for this period.'**
  String get noBudgetThisMonth;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @budgetOf.
  String get budgetOf;

  /// No description provided for @budgetSpent.
  String get budgetSpent;

  /// No description provided for @budgetRemaining.
  String get budgetRemaining;

  /// No description provided for @budgetOverBy.
  String get budgetOverBy;

  /// No description provided for @budgetCarryOver.
  String get budgetCarryOver;

  /// No description provided for @budgetEffective.
  String get budgetEffective;

  /// No description provided for @budgetAddNew.
  String get budgetAddNew;

  /// No description provided for @budgetEditExisting.
  String get budgetEditExisting;

  /// No description provided for @budgetDeleteConfirm.
  String get budgetDeleteConfirm;

  /// No description provided for @budgetDeleteAction.
  String get budgetDeleteAction;

  /// No description provided for @budgetSavedSuccess.
  String get budgetSavedSuccess;

  /// No description provided for @budgetDeletedSuccess.
  String get budgetDeletedSuccess;

  /// No description provided for @budgetErrorSaving.
  String get budgetErrorSaving;

  /// No description provided for @budgetErrorDeleting.
  String get budgetErrorDeleting;

  /// No description provided for @budgetEffectiveFrom.
  String get budgetEffectiveFrom;

  /// No description provided for @budgetEffectiveTo.
  String get budgetEffectiveTo;

  /// No description provided for @budgetAmountRequired.
  String get budgetAmountRequired;

  /// No description provided for @budgetCategoryRequired.
  String get budgetCategoryRequired;

  String get budgetSettingTitle;
  String get budgetSettingTotal;
  String get budgetSettingNoBudget;
  String get budgetSettingClearBudget;
  String get budgetSettingOnlyThisMonth;
  String get budgetSettingAmountHint;
  String get budgetSettingAmountGreaterThanZero;
  String get budgetSettingAmountTooLarge;
  String get budgetSettingRemoveConfirmTitle;
  String get budgetSettingRemoveConfirmMessage;
  String get budgetSettingRemoveAction;
  String get budgetSettingDiscardTitle;
  String get budgetSettingDiscardMessage;
  String get budgetSettingDiscardAction;
  String get budgetSettingKeepEditing;

  String get budgetViewRemainingMonthly;
  String get budgetViewNoBudgetsTitle;
  String get budgetViewNoBudgetsSubtitle;
  String get budgetViewSetUpBudgets;
  String get budgetViewCouldNotLoad;
  String get budgetViewNoBudgetSet;
  String budgetViewIncludesCarryOver(String amount);
  String get budgetSetting;

  String get noteViewNoNotes;
  String get noteViewNoNotesSubtitle;
  String get noteViewNoNote;
  String get noteViewSortAmount;
  String get noteViewSortCount;
  String get noteViewDeleteConfirmTitle;
  String get noteViewDeleteConfirmMessage;
  String get noteViewCouldNotLoad;
  String get noteColumnLabel;
  String get amountColumnLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
