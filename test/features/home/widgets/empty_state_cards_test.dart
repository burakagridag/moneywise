// Widget tests for EmptyStateCards — home feature (EPIC8A-10).
// Verifies empty-state visibility and auto-dismiss behaviour via provider overrides.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/router/routes.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/domain/entities/transaction.dart';
import 'package:moneywise/domain/entities/transaction_with_details.dart';
import 'package:moneywise/features/home/presentation/providers/recent_transactions_provider.dart';
import 'package:moneywise/features/home/presentation/widgets/empty_state_cards.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

TransactionWithDetails _makeDetails(String id) {
  final now = DateTime(2026, 5, 1);
  final tx = Transaction(
    id: id,
    type: 'expense',
    amount: 10.0,
    currencyCode: 'EUR',
    accountId: 'acc_1',
    date: now,
    createdAt: now,
    updatedAt: now,
  );
  return TransactionWithDetails(transaction: tx);
}

/// Builds [EmptyStateCards] with a router so [context.go] works.
Widget _buildWidget({
  required Stream<List<TransactionWithDetails>> stream,
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
        path: Routes.budget,
        builder: (_, __) => const Scaffold(body: Text('Budget')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      recentTransactionsProvider.overrideWith((_) => stream),
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
  group('EmptyStateCards — EPIC8A-10', () {
    testWidgets('shows 3 cards when provider emits empty list', (tester) async {
      await tester.pumpWidget(
        _buildWidget(stream: Stream.value([])),
      );
      await tester.pump();

      // All 3 card titles must be visible
      expect(find.text('Add your first transaction'), findsOneWidget);
      expect(find.text('Manage your accounts'), findsOneWidget);
      expect(find.text('Set a monthly budget'), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink when provider emits 1+ transactions',
        (tester) async {
      final stream = Stream.value([_makeDetails('tx_1')]);
      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      expect(find.text('Add your first transaction'), findsNothing);
      expect(find.text('Manage your accounts'), findsNothing);
      expect(find.text('Set a monthly budget'), findsNothing);
    });

    testWidgets('each card has correct subtitle text visible', (tester) async {
      await tester.pumpWidget(
        _buildWidget(stream: Stream.value([])),
      );
      await tester.pump();

      expect(
        find.text('Track income, expenses and transfers'),
        findsOneWidget,
      );
      expect(find.text('Add cash, bank or card accounts'), findsOneWidget);
      expect(find.text('Stay on top of your spending'), findsOneWidget);
    });

    testWidgets('3 InkWell widgets present (cards are tappable)',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget(stream: Stream.value([])),
      );
      await tester.pump();

      expect(find.byType(InkWell), findsNWidgets(3));
    });

    testWidgets(
        'hides cards when live stream transitions from empty to non-empty',
        (tester) async {
      // Start with an empty list
      final controller = StreamController<List<TransactionWithDetails>>();
      addTearDown(controller.close);

      await tester.pumpWidget(_buildWidget(stream: controller.stream));

      controller.add([]);
      await tester.pump(); // process stream event
      await tester.pump(); // process setState from provider

      expect(find.text('Add your first transaction'), findsOneWidget);

      // Add a transaction — cards should disappear
      controller.add([_makeDetails('tx_1')]);
      await tester.pump(); // process stream event
      await tester.pump(); // process setState from provider

      expect(find.text('Add your first transaction'), findsNothing);
    });

    testWidgets('tapping first card navigates to transactions route',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget(stream: Stream.value([])),
      );
      await tester.pump();

      await tester.tap(find.text('Add your first transaction'));
      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsOneWidget);
    });

    testWidgets('tapping second card navigates to more route', (tester) async {
      await tester.pumpWidget(
        _buildWidget(stream: Stream.value([])),
      );
      await tester.pump();

      await tester.tap(find.text('Manage your accounts'));
      await tester.pumpAndSettle();

      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('tapping third card navigates to budget route', (tester) async {
      await tester.pumpWidget(
        _buildWidget(stream: Stream.value([])),
      );
      await tester.pump();

      await tester.tap(find.text('Set a monthly budget'));
      await tester.pumpAndSettle();

      expect(find.text('Budget'), findsOneWidget);
    });

    testWidgets('renders without errors in dark theme', (tester) async {
      await tester.pumpWidget(
        _buildWidget(stream: Stream.value([]), theme: AppTheme.dark),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Add your first transaction'), findsOneWidget);
    });

    testWidgets('renders without errors in light theme', (tester) async {
      await tester.pumpWidget(
        _buildWidget(stream: Stream.value([]), theme: AppTheme.light),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Add your first transaction'), findsOneWidget);
    });
  });
}
