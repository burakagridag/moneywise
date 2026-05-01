// Widget tests for HomeScreen scaffold — home feature (EPIC8A-03).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/router/routes.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/home/presentation/screens/home_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildHomeScreen({ThemeData? theme}) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: theme ?? AppTheme.light,
        home: const Scaffold(body: HomeScreen()),
      ),
    );

/// Builds a full router-wired app so the default route can be verified.
Widget _buildRouterApp({ThemeData? theme}) {
  final router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const HomeScreen(),
      ),
    ],
  );

  return ProviderScope(
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

      // No overflow errors — test fails automatically on RenderFlex overflow.
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

    testWidgets('renders all 6 section placeholders', (tester) async {
      await tester.pumpWidget(_buildHomeScreen());
      await tester.pump();

      // Each placeholder has a unique label text. Use substring matching so
      // the test is not brittle to minor wording changes.
      expect(
        find.textContaining('HomeHeader'),
        findsOneWidget,
        reason: 'Slot 1 — HomeHeader placeholder missing',
      );
      expect(
        find.textContaining('TotalBalanceCard'),
        findsOneWidget,
        reason: 'Slot 2 — TotalBalanceCard placeholder missing',
      );
      expect(
        find.textContaining('BudgetPulseCard'),
        findsOneWidget,
        reason: 'Slot 3 — BudgetPulseCard placeholder missing',
      );
      expect(
        find.textContaining('ThisWeekSection'),
        findsOneWidget,
        reason: 'Slot 4 — ThisWeekSection placeholder missing',
      );
      expect(
        find.textContaining('RecentSection'),
        findsOneWidget,
        reason: 'Slot 5 — RecentSection placeholder missing',
      );
      expect(
        find.textContaining('EmptyState'),
        findsOneWidget,
        reason: 'Slot 6 — EmptyState placeholder missing',
      );
    });

    testWidgets('section placeholders appear in the correct scroll order',
        (tester) async {
      await tester.pumpWidget(_buildHomeScreen());
      await tester.pump();

      final homeHeader = tester.getTopLeft(find.textContaining('HomeHeader'));
      final balanceCard =
          tester.getTopLeft(find.textContaining('TotalBalanceCard'));
      final budgetPulse =
          tester.getTopLeft(find.textContaining('BudgetPulseCard'));
      final thisWeek =
          tester.getTopLeft(find.textContaining('ThisWeekSection'));
      final recent = tester.getTopLeft(find.textContaining('RecentSection'));
      final emptyState = tester.getTopLeft(find.textContaining('EmptyState'));

      expect(homeHeader.dy, lessThan(balanceCard.dy),
          reason: 'HomeHeader must be above TotalBalanceCard');
      expect(balanceCard.dy, lessThan(budgetPulse.dy),
          reason: 'TotalBalanceCard must be above BudgetPulseCard');
      expect(budgetPulse.dy, lessThan(thisWeek.dy),
          reason: 'BudgetPulseCard must be above ThisWeekSection');
      expect(thisWeek.dy, lessThan(recent.dy),
          reason: 'ThisWeekSection must be above RecentSection');
      expect(recent.dy, lessThan(emptyState.dy),
          reason: 'RecentSection must be above EmptyState');
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
      await tester.pumpAndSettle();

      // HomeScreen rendered when router lands on /home.
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
