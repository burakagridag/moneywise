// Widget and unit tests for Sprint 1 + Sprint 2 foundation.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/app.dart';
import 'package:moneywise/core/constants/app_colors.dart';
import 'package:moneywise/core/constants/app_spacing.dart';
import 'package:moneywise/core/constants/app_typography.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/router/routes.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:moneywise/features/accounts/presentation/screens/account_add_edit_screen.dart';
import 'package:moneywise/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:moneywise/features/more/presentation/screens/category_management_screen.dart';
import 'package:moneywise/features/more/presentation/screens/more_screen.dart';
import 'package:moneywise/features/transactions/presentation/screens/transactions_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates an in-memory [AppDatabase] for tests (no file I/O, no seed delay).
AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Wraps [screen] with localizations and Riverpod scope.
/// Optionally overrides [appDatabaseProvider] with an in-memory DB.
Widget _buildScreen(
  Widget screen, {
  bool withDb = false,
}) {
  final overrides = <Override>[
    if (withDb) appDatabaseProvider.overrideWith((_) => _testDb()),
  ];

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: screen,
    ),
  );
}

// ---------------------------------------------------------------------------
// App smoke test
// ---------------------------------------------------------------------------

void main() {
  group('App smoke test', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: MoneyWiseApp()));
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Placeholder screens (Sprint 1 screens that don't need a DB)
  // ---------------------------------------------------------------------------

  group('Placeholder screens', () {
    // TransactionsScreen builds 4 sub-views via IndexedStack, each watching
    // a Drift stream provider. When the widget tree is disposed, Drift's
    // StreamQueryStore schedules zero-duration timers for cleanup. We must
    // drain those timers before the test binding's teardown by pumping
    // Duration.zero multiple times after replacing the widget tree.
    testWidgets('TransactionsScreen renders', (tester) async {
      final db = _testDb();
      final widget = ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: AppTheme.light,
          home: const TransactionsScreen(),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      // The AppBar title from i18n is 'Transactions'
      expect(find.text('Transactions'), findsOneWidget);
      // Replace widget tree → ProviderScope.dispose → Drift schedules
      // zero-duration timers for each stream. Pump several times to drain.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    // StatsScreen render test removed — EPIC8A-02: StatsScreen is no longer
    // mounted in the navigation shell. Tests preserved in stats feature directory.

    testWidgets('MoreScreen renders with settings menu item', (tester) async {
      await tester.pumpWidget(_buildScreen(const MoreScreen()));
      expect(find.text('More'), findsOneWidget);
      // Fix 1: Categories moved under Settings sub-screen.
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // AccountsScreen — Sprint 2 (needs DB override)
  // ---------------------------------------------------------------------------

  group('AccountsScreen', () {
    // Drift's StreamQueryStore schedules a zero-duration timer in FakeAsync
    // when a stream is cancelled. This timer fires during the test binding's
    // final teardown frame. The fix is to explicitly dispose the ProviderScope
    // and pump within the test body (before the binding's teardown) so that the
    // zero-timer is drained before _verifyInvariants checks it.

    Widget buildAccountsScreen(AppDatabase db) => ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((_) => db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const AccountsScreen(),
          ),
        );

    testWidgets('shows AccountsScreen widget when rendered', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(buildAccountsScreen(db));
      await tester.pump();
      expect(find.byType(AccountsScreen), findsOneWidget);
      // Replace with empty widget → ProviderScope.dispose → Drift zero-timers
      // created. Pump twice to ensure all zero-duration timers are drained.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('renders AppBar with Accounts title', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(buildAccountsScreen(db));
      await tester.pump();
      expect(find.text('Accounts'), findsAtLeastNWidgets(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('shows FAB', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(buildAccountsScreen(db));
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // CategoryManagementScreen — Sprint 2 (needs DB override)
  // ---------------------------------------------------------------------------

  group('CategoryManagementScreen', () {
    Widget buildCategoryScreen(AppDatabase db) => ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((_) => db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const CategoryManagementScreen(),
          ),
        );

    testWidgets('renders CategoryManagementScreen widget', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(buildCategoryScreen(db));
      await tester.pump();
      expect(find.byType(CategoryManagementScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('has a TabBar with Income and Expense tabs', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(buildCategoryScreen(db));
      await tester.pump();
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('shows Categories title in AppBar', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(buildCategoryScreen(db));
      await tester.pump();
      expect(find.text('Categories'), findsAtLeastNWidgets(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // AccountAddEditScreen — Sprint 2 (needs DB override)
  // ---------------------------------------------------------------------------

  group('AccountAddEditScreen', () {
    Widget buildAddEditScreen(AppDatabase db) => ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((_) => db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const AccountAddEditScreen(),
          ),
        );

    testWidgets('renders AccountAddEditScreen widget', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(buildAddEditScreen(db));
      await tester.pump();
      expect(find.byType(AccountAddEditScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('shows Add Account title in AppBar', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(buildAddEditScreen(db));
      await tester.pump();
      expect(find.text('Add Account'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('has a name field and a Save button', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(buildAddEditScreen(db));
      await tester.pump();
      expect(
          find.widgetWithText(TextFormField, 'Account Name'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Save'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // AppColors
  // ---------------------------------------------------------------------------

  group('AppColors', () {
    test('brand primary is slate blue (sprint-7 refresh)', () {
      expect(AppColors.brandPrimary, const Color(0xFF3D5A99));
    });

    test('dark bg primary is darkest background', () {
      expect(AppColors.bgPrimary, const Color(0xFF0F1117));
    });

    test('income is teal blue', () {
      expect(AppColors.income, const Color(0xFF2E86AB));
    });
  });

  // ---------------------------------------------------------------------------
  // AppSpacing
  // ---------------------------------------------------------------------------

  group('AppSpacing', () {
    test('spacing scale is ordered', () {
      expect(AppSpacing.xs, lessThan(AppSpacing.sm));
      expect(AppSpacing.sm, lessThan(AppSpacing.md));
      expect(AppSpacing.md, lessThan(AppSpacing.lg));
      expect(AppSpacing.lg, lessThan(AppSpacing.xl));
    });

    test('button height meets minimum tap target', () {
      expect(AppHeights.button, greaterThanOrEqualTo(44.0));
    });
  });

  // ---------------------------------------------------------------------------
  // AppTypography
  // ---------------------------------------------------------------------------

  group('AppTypography', () {
    test('large title has correct font size', () {
      expect(AppTypography.largeTitle.fontSize, 34.0);
    });

    test('money styles use tabular figures', () {
      expect(AppTypography.moneyLarge.fontFeatures, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Routes
  // ---------------------------------------------------------------------------

  group('Routes', () {
    test('all route paths start with /', () {
      expect(Routes.home, startsWith('/'));
      expect(Routes.transactions, startsWith('/'));
      expect(Routes.budget, startsWith('/'));
      expect(Routes.accounts, startsWith('/'));
      expect(Routes.more, startsWith('/'));
    });

    test('all routes are unique', () {
      final routes = [
        Routes.home,
        Routes.transactions,
        Routes.budget,
        Routes.accounts,
        Routes.more,
      ];
      expect(routes.toSet().length, routes.length);
    });

    test('sprint 2 routes are defined and unique', () {
      expect(Routes.accountAddEdit, startsWith('/'));
      expect(Routes.categoryManagement, startsWith('/'));
      expect(Routes.accountAddEdit, isNot(Routes.categoryManagement));
    });
  });

  // ---------------------------------------------------------------------------
  // AppTheme
  // ---------------------------------------------------------------------------

  group('AppTheme', () {
    test('dark theme has correct scaffold background', () {
      expect(
        AppTheme.dark.scaffoldBackgroundColor,
        AppColors.bgPrimary,
      );
    });

    test('light theme has correct scaffold background', () {
      expect(
        AppTheme.light.scaffoldBackgroundColor,
        AppColors.bgPrimaryLight,
      );
    });

    test('both themes use brand primary as primary color', () {
      expect(AppTheme.dark.colorScheme.primary, AppColors.brandPrimary);
      expect(AppTheme.light.colorScheme.primary, AppColors.brandPrimary);
    });
  });

  // ---------------------------------------------------------------------------
}
