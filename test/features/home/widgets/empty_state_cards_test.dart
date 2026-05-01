// Widget tests for EmptyStateCards — home feature (EPIC8A-10).
// Verifies per-card independent visibility and auto-dismiss behaviour via
// provider overrides for totalTransactionCountProvider, userAccountCountProvider,
// and hasBudgetConfiguredProvider.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/router/routes.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/home/presentation/providers/empty_state_provider.dart';
import 'package:moneywise/features/home/presentation/widgets/empty_state_cards.dart';

// ---------------------------------------------------------------------------
// Helper — build widget with provider overrides
// ---------------------------------------------------------------------------

Widget _buildWidget({
  required Stream<int> txCountStream,
  required Stream<int> acctCountStream,
  required Stream<bool> hasBudgetStream,
  ThemeData? theme,
}) {
  final router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const Scaffold(body: EmptyStateCards()),
      ),
      GoRoute(
        path: Routes.transactions,
        builder: (_, __) => const Scaffold(body: Text('Transactions')),
      ),
      GoRoute(
        path: Routes.more,
        builder: (_, __) => const Scaffold(body: Text('More')),
      ),
      GoRoute(
        path: Routes.accounts,
        builder: (_, __) => const Scaffold(body: Text('Accounts')),
      ),
      GoRoute(
        path: Routes.budget,
        builder: (_, __) => const Scaffold(body: Text('Budget')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      totalTransactionCountProvider.overrideWith((_) => txCountStream),
      userAccountCountProvider.overrideWith((_) => acctCountStream),
      hasBudgetConfiguredProvider.overrideWith((_) => hasBudgetStream),
    ],
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
  group('EmptyStateCards — EPIC8A-10 (independent card visibility)', () {
    // -----------------------------------------------------------------------
    // Scenario 1 — brand new user: all 3 cards visible
    // -----------------------------------------------------------------------
    testWidgets(
        'brand new user (txCount=0, acctCount=0, hasBudget=false) → 3 cards visible',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(false),
        ),
      );
      await tester.pump();

      expect(find.text('Add your first transaction'), findsOneWidget);
      expect(find.text('Manage your accounts'), findsOneWidget);
      expect(find.text('Set a monthly budget'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Scenario 2 — budget + account set, no transaction → only tx card
    // -----------------------------------------------------------------------
    testWidgets(
        'budget + account exist, no transaction (txCount=0, acctCount=1, hasBudget=true) '
        '→ only "Add transaction" card visible', (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(1),
          hasBudgetStream: Stream.value(true),
        ),
      );
      await tester.pump();

      expect(find.text('Add your first transaction'), findsOneWidget);
      expect(find.text('Manage your accounts'), findsNothing);
      expect(find.text('Set a monthly budget'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Scenario 3 — only budget set: tx + account cards visible
    // -----------------------------------------------------------------------
    testWidgets(
        'only budget set (txCount=0, acctCount=0, hasBudget=true) '
        '→ 2 cards visible (tx + accounts)', (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(true),
        ),
      );
      await tester.pump();

      expect(find.text('Add your first transaction'), findsOneWidget);
      expect(find.text('Manage your accounts'), findsOneWidget);
      expect(find.text('Set a monthly budget'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Scenario 4 — all completed: SizedBox.shrink
    // -----------------------------------------------------------------------
    testWidgets(
        'all completed (txCount=1, acctCount=1, hasBudget=true) → SizedBox.shrink',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(1),
          acctCountStream: Stream.value(1),
          hasBudgetStream: Stream.value(true),
        ),
      );
      await tester.pump();

      expect(find.text('Add your first transaction'), findsNothing);
      expect(find.text('Manage your accounts'), findsNothing);
      expect(find.text('Set a monthly budget'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Scenario 5 — loading state: widget hidden
    // -----------------------------------------------------------------------
    testWidgets('while providers are loading → widget is hidden',
        (tester) async {
      // StreamController with no events emitted = loading state.
      final txCtrl = StreamController<int>();
      final acctCtrl = StreamController<int>();
      final budgetCtrl = StreamController<bool>();
      addTearDown(() {
        txCtrl.close();
        acctCtrl.close();
        budgetCtrl.close();
      });

      await tester.pumpWidget(
        _buildWidget(
          txCountStream: txCtrl.stream,
          acctCountStream: acctCtrl.stream,
          hasBudgetStream: budgetCtrl.stream,
        ),
      );
      await tester.pump();

      // Nothing should be visible while still loading.
      expect(find.text('Add your first transaction'), findsNothing);
      expect(find.text('Manage your accounts'), findsNothing);
      expect(find.text('Set a monthly budget'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Scenario 6 — live stream: tx card auto-dismisses when tx is added
    // -----------------------------------------------------------------------
    testWidgets(
        'tx card auto-dismisses when live stream transitions 0 → 1 transaction',
        (tester) async {
      final txCtrl = StreamController<int>();
      addTearDown(txCtrl.close);

      await tester.pumpWidget(
        _buildWidget(
          txCountStream: txCtrl.stream,
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(false),
        ),
      );

      txCtrl.add(0);
      await tester.pump();
      await tester.pump();

      expect(find.text('Add your first transaction'), findsOneWidget);

      txCtrl.add(1);
      await tester.pump();
      await tester.pump();

      expect(find.text('Add your first transaction'), findsNothing);
      // Other cards remain since acctCount=0 and hasBudget=false.
      expect(find.text('Manage your accounts'), findsOneWidget);
      expect(find.text('Set a monthly budget'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Scenario 7 — subtitles visible for all 3 cards in new user state
    // -----------------------------------------------------------------------
    testWidgets('correct subtitle text visible for each card', (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(false),
        ),
      );
      await tester.pump();

      expect(
        find.text('Track income, expenses and transfers'),
        findsOneWidget,
      );
      expect(find.text('Add cash, bank or card accounts'), findsOneWidget);
      expect(find.text('Stay on top of your spending'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Scenario 8 — cards are tappable (InkWell count matches visible cards)
    // -----------------------------------------------------------------------
    testWidgets('3 InkWell widgets present when all 3 cards visible',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(false),
        ),
      );
      await tester.pump();

      expect(find.byType(InkWell), findsNWidgets(3));
    });

    testWidgets('1 InkWell present when only tx card visible', (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(1),
          hasBudgetStream: Stream.value(true),
        ),
      );
      await tester.pump();

      expect(find.byType(InkWell), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Scenario 9 — navigation tests
    // -----------------------------------------------------------------------
    testWidgets(
        'tapping "Add your first transaction" navigates to transactions',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(false),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Add your first transaction'));
      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsOneWidget);
    });

    testWidgets('tapping "Manage your accounts" navigates to accounts route',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(false),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Manage your accounts'));
      await tester.pumpAndSettle();

      expect(find.text('Accounts'), findsOneWidget);
    });

    testWidgets('tapping "Set a monthly budget" navigates to budget route',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(false),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Set a monthly budget'));
      await tester.pumpAndSettle();

      expect(find.text('Budget'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Scenario 10 — theme smoke tests
    // -----------------------------------------------------------------------
    testWidgets('renders without errors in dark theme', (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(false),
          theme: AppTheme.dark,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Add your first transaction'), findsOneWidget);
    });

    testWidgets('renders without errors in light theme', (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(false),
          theme: AppTheme.light,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Add your first transaction'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Scenario 11 — error state: all cards hidden
    // -----------------------------------------------------------------------
    testWidgets('hides all cards when transaction provider emits error',
        (tester) async {
      // Any provider emitting an error → widget collapses to SizedBox.shrink.
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.error(Exception('db error')),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(false),
        ),
      );
      await tester.pump();

      expect(find.text('Add your first transaction'), findsNothing);
      expect(find.text('Manage your accounts'), findsNothing);
      expect(find.text('Set a monthly budget'), findsNothing);
    });

    testWidgets('hides all cards when account provider emits error',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.error(Exception('db error')),
          hasBudgetStream: Stream.value(false),
        ),
      );
      await tester.pump();

      expect(find.text('Add your first transaction'), findsNothing);
      expect(find.text('Manage your accounts'), findsNothing);
      expect(find.text('Set a monthly budget'), findsNothing);
    });

    testWidgets('hides all cards when hasBudgetConfigured provider emits error',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.error(Exception('db error')),
        ),
      );
      await tester.pump();

      expect(find.text('Add your first transaction'), findsNothing);
      expect(find.text('Manage your accounts'), findsNothing);
      expect(find.text('Set a monthly budget'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Scenario 12 — category budget only: card hidden (bug fix EPIC8A-10)
    // -----------------------------------------------------------------------
    testWidgets(
        'hasBudget=true via category budget only → "Set a monthly budget" card hidden',
        (tester) async {
      // Simulates the case where no global budget is set but a category budget
      // exists. hasBudgetConfiguredProvider emits true in this scenario.
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(true),
        ),
      );
      await tester.pump();

      expect(find.text('Set a monthly budget'), findsNothing);
      // Transaction and account cards still show since they have no entries.
      expect(find.text('Add your first transaction'), findsOneWidget);
      expect(find.text('Manage your accounts'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Scenario 13 — global budget only: card hidden (regression guard)
    // -----------------------------------------------------------------------
    testWidgets(
        'hasBudget=true via global budget only → "Set a monthly budget" card hidden, '
        'other 2 cards still visible', (tester) async {
      // txCount=0 and acctCount=0 so that only the budget card is the variable
      // under test. If we used txCount=1/acctCount=1, both those cards would
      // already be hidden and we would not be able to assert that the OTHER
      // cards remain independently visible.
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(0),
          acctCountStream: Stream.value(0),
          hasBudgetStream: Stream.value(true),
        ),
      );
      await tester.pump();

      expect(find.text('Set a monthly budget'), findsNothing);
      // The other two onboarding cards must still be visible — this confirms
      // that only the budget card reacted to hasBudget=true.
      expect(find.text('Add your first transaction'), findsOneWidget);
      expect(find.text('Manage your accounts'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Scenario 14 — no budget configured: card visible
    // -----------------------------------------------------------------------
    testWidgets(
        'hasBudget=false (no global or category budget) → "Set a monthly budget" card visible',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          txCountStream: Stream.value(1),
          acctCountStream: Stream.value(1),
          hasBudgetStream: Stream.value(false),
        ),
      );
      await tester.pump();

      expect(find.text('Set a monthly budget'), findsOneWidget);
    });
  });
}
