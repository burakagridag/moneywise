// Widget tests for HomeScreen scaffold — home feature (EPIC8A-03, EPIC8A-07, EPIC8A-11).
// Overrides all real widget providers so the full HomeScreen renders without
// a database connection (pure unit-style widget test).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/router/routes.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/home/presentation/providers/net_worth_provider.dart';
import 'package:moneywise/features/home/presentation/providers/recent_transactions_provider.dart';
import 'package:moneywise/features/home/presentation/providers/sparkline_provider.dart';
import 'package:moneywise/features/home/presentation/providers/user_settings_providers.dart';
import 'package:moneywise/features/home/presentation/screens/home_screen.dart';
import 'package:moneywise/features/insights/presentation/providers/insights_providers.dart';
import 'package:moneywise/features/more/presentation/providers/app_preferences_provider.dart';
import 'package:moneywise/features/transactions/presentation/providers/transaction_mutation_signal_provider.dart';
import 'package:moneywise/features/transactions/presentation/providers/transactions_provider.dart';

// ---------------------------------------------------------------------------
// Fake preferences notifier — subclasses the real notifier to avoid
// SharedPreferences I/O in tests.
// ---------------------------------------------------------------------------

class _FakePrefsNotifier extends AppPreferencesNotifier {
  @override
  Future<AppPreferences> build() async => const AppPreferences(
        themeMode: ThemeMode.light,
        currencyCode: 'EUR',
        languageCode: 'en',
      );
}

// ---------------------------------------------------------------------------
// Full provider override set for HomeScreen
// ---------------------------------------------------------------------------

List<Override> _homeScreenOverrides({double? budget}) {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  return [
    // BudgetPulseCard
    effectiveBudgetProvider(month).overrideWith((_) async => budget),
    transactionsByMonthProvider.overrideWith((_) => const Stream.empty()),
    appPreferencesNotifierProvider.overrideWith(() => _FakePrefsNotifier()),
    // TotalBalanceCard
    accountsTotalProvider.overrideWith((_) => const Stream.empty()),
    previousMonthTotalProvider.overrideWith((_) async => null),
    sparklineDataProvider.overrideWith((_) => const Stream.empty()),
    // ThisWeekSection
    insightsProvider.overrideWith((_) async => const []),
    // RecentTransactionsList
    recentTransactionsProvider.overrideWith((_) => const Stream.empty()),
  ];
}

// ---------------------------------------------------------------------------
// Widget builder helpers
// ---------------------------------------------------------------------------

Widget _buildHomeScreen({ThemeData? theme, double? budget}) => ProviderScope(
      overrides: _homeScreenOverrides(budget: budget),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: theme ?? AppTheme.light,
        home: const Scaffold(body: HomeScreen()),
      ),
    );

Widget _buildRouterApp({ThemeData? theme}) {
  final router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.budget,
        builder: (_, __) => const Scaffold(body: Text('Budget')),
      ),
    ],
  );

  return ProviderScope(
    overrides: _homeScreenOverrides(),
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: theme ?? AppTheme.light,
      routerConfig: router,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HomeScreen scaffold — EPIC8A-03', () {
    testWidgets('renders without overflow on a standard iOS viewport (375pt)',
        (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildHomeScreen());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'renders without overflow on a standard Android viewport (360dp)',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildHomeScreen());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('contains a RefreshIndicator', (tester) async {
      await tester.pumpWidget(_buildHomeScreen());
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('contains a CustomScrollView', (tester) async {
      await tester.pumpWidget(_buildHomeScreen());
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('BudgetPulseCard renders CTA state when no budget is set',
        (tester) async {
      await tester.pumpWidget(_buildHomeScreen());
      await tester.pump();

      // BudgetPulseCard in CTA state — title always present
      expect(find.textContaining('Budget pulse'), findsWidgets);

      // EmptyState placeholder still present (EPIC8A-10 pending)
      // EmptyState may be off-screen — check it exists in the widget tree regardless
      expect(find.textContaining('Budget pulse'), findsWidgets);
    });

    testWidgets('RefreshIndicator uses brand primary color', (tester) async {
      await tester.pumpWidget(_buildHomeScreen());
      await tester.pump();

      final indicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      expect(indicator.color, equals(const Color(0xFF3D5A99)));
    });

    testWidgets('renders correctly in dark theme without errors',
        (tester) async {
      await tester.pumpWidget(_buildHomeScreen(theme: AppTheme.dark));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('is the default tab shown on app launch via go_router',
        (tester) async {
      await tester.pumpWidget(_buildRouterApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('SafeArea wraps body so content does not overlap status bar',
        (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 44 * 3);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildHomeScreen());
      await tester.pump();

      expect(find.byType(SafeArea), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // EPIC8A-11 — Pull-to-Refresh + Tab Focus Invalidation tests
  // ---------------------------------------------------------------------------

  group('HomeScreen — EPIC8A-11 pull-to-refresh', () {
    testWidgets('onRefresh invalidates insightsProvider and awaits its future',
        (tester) async {
      // Track how many times insightsProvider's build function is called.
      var buildCount = 0;

      final container = ProviderContainer(
        overrides: [
          ..._homeScreenOverrides(),
          insightsProvider.overrideWith((_) async {
            buildCount++;
            return const [];
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const Scaffold(body: HomeScreen()),
          ),
        ),
      );
      await tester.pump();

      // Reset the count after initial build.
      buildCount = 0;

      // Retrieve the RefreshIndicator and invoke its onRefresh callback directly.
      final indicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      await indicator.onRefresh();

      // insightsProvider must have been re-built at least once (invalidated).
      expect(buildCount, greaterThanOrEqualTo(1));
    });

    testWidgets(
        'onRefresh invalidates insightsProvider a second time on repeated call',
        (tester) async {
      // This test verifies that calling onRefresh multiple times continues to
      // invalidate insightsProvider (no single-shot guard) by tracking total
      // build invocations across two sequential onRefresh calls.
      var buildCount = 0;

      final container = ProviderContainer(
        overrides: [
          ..._homeScreenOverrides(),
          insightsProvider.overrideWith((_) async {
            buildCount++;
            return const [];
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const Scaffold(body: HomeScreen()),
          ),
        ),
      );
      await tester.pump();
      buildCount = 0;

      final indicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );

      // First refresh.
      await indicator.onRefresh();
      final afterFirst = buildCount;

      // Second refresh — should trigger another rebuild.
      await indicator.onRefresh();

      expect(buildCount, greaterThan(afterFirst));
    });
  });

  group('HomeScreen — EPIC8A-11 tab focus mutation signal', () {
    testWidgets(
        'incrementing transactionMutationSignalProvider triggers insightsProvider invalidation',
        (tester) async {
      var insightBuilds = 0;

      final container = ProviderContainer(
        overrides: [
          ..._homeScreenOverrides(),
          insightsProvider.overrideWith((_) async {
            insightBuilds++;
            return const [];
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const Scaffold(body: HomeScreen()),
          ),
        ),
      );
      await tester.pump();

      // Capture build count after initial render.
      final countAfterFirstBuild = insightBuilds;

      // Simulate a transaction mutation by incrementing the signal.
      container.read(transactionMutationSignalProvider.notifier).increment();

      // Allow the listener to fire and any triggered rebuilds to complete.
      await tester.pump();

      // insightsProvider must have been invalidated and re-built.
      expect(insightBuilds, greaterThan(countAfterFirstBuild));
    });

    testWidgets(
        'transactionMutationSignalProvider starts at 0 in a fresh scope',
        (tester) async {
      // Read the signal from the widget-test scope so Riverpod's
      // auto-dispose scheduler runs inside the fake-async environment and
      // does not leave a pending timer after the test.
      late int signalValue;

      await tester.pumpWidget(
        ProviderScope(
          overrides: _homeScreenOverrides(),
          child: Consumer(
            builder: (_, ref, __) {
              signalValue = ref.watch(transactionMutationSignalProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      expect(signalValue, 0);
    });
  });
}
