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
import 'package:moneywise/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:moneywise/features/more/presentation/providers/theme_mode_provider.dart';
import 'package:moneywise/features/more/presentation/screens/more_screen.dart';
import 'package:moneywise/features/stats/presentation/screens/stats_screen.dart';
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
    testWidgets('TransactionsScreen renders', (tester) async {
      await tester.pumpWidget(_buildScreen(const TransactionsScreen()));
      expect(find.text('Transactions'), findsOneWidget);
    });

    testWidgets('StatsScreen renders', (tester) async {
      await tester.pumpWidget(_buildScreen(const StatsScreen()));
      expect(find.text('Stats'), findsOneWidget);
    });

    testWidgets('MoreScreen renders with categories menu item', (tester) async {
      await tester.pumpWidget(_buildScreen(const MoreScreen()));
      expect(find.text('More'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
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
  // AppColors
  // ---------------------------------------------------------------------------

  group('AppColors', () {
    test('brand primary is coral', () {
      expect(AppColors.brandPrimary, const Color(0xFFFF6B5C));
    });

    test('dark bg primary is darkest background', () {
      expect(AppColors.bgPrimary, const Color(0xFF1A1B1E));
    });

    test('income is blue', () {
      expect(AppColors.income, const Color(0xFF4A90E2));
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
      expect(Routes.transactions, startsWith('/'));
      expect(Routes.stats, startsWith('/'));
      expect(Routes.accounts, startsWith('/'));
      expect(Routes.more, startsWith('/'));
    });

    test('all routes are unique', () {
      final routes = [
        Routes.transactions,
        Routes.stats,
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
  // AppThemeMode provider
  // ---------------------------------------------------------------------------

  group('AppThemeMode provider', () {
    test('defaults to dark mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(appThemeModeProvider), ThemeMode.dark);
    });

    test('toggle switches to light mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appThemeModeProvider.notifier).toggle();
      expect(container.read(appThemeModeProvider), ThemeMode.light);
    });

    test('double toggle returns to dark mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appThemeModeProvider.notifier).toggle();
      container.read(appThemeModeProvider.notifier).toggle();
      expect(container.read(appThemeModeProvider), ThemeMode.dark);
    });
  });
}
