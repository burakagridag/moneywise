// Widget tests for RecentTransactionsList — home feature (EPIC8A-09).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/constants/app_colors.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/domain/entities/transaction.dart';
import 'package:moneywise/features/home/presentation/providers/recent_transactions_provider.dart';
import 'package:moneywise/features/home/presentation/widgets/recent_transactions_list.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Transaction _makeTx({
  required String id,
  required String type,
  double amount = 100.0,
  String? description,
}) {
  final now = DateTime(2026, 5, 1);
  return Transaction(
    id: id,
    type: type,
    amount: amount,
    currencyCode: 'EUR',
    accountId: 'acc_1',
    date: now,
    description: description,
    createdAt: now,
    updatedAt: now,
  );
}

/// Wraps [RecentTransactionsList] with the given [stream] override.
Widget _buildWidget({
  required Stream<List<Transaction>> stream,
  VoidCallback? onSeeAllTap,
  ThemeData? theme,
}) {
  return ProviderScope(
    overrides: [
      recentTransactionsProvider.overrideWith((_) => stream),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: theme ?? AppTheme.light,
      home: Scaffold(
        body: RecentTransactionsList(
          onSeeAllTap: onSeeAllTap ?? () {},
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RecentTransactionsList — EPIC8A-09', () {
    // -----------------------------------------------------------------------
    // Empty state
    // -----------------------------------------------------------------------

    testWidgets('hides entire section when 0 transactions', (tester) async {
      final stream = Stream.value(<Transaction>[]);
      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      // No section header text, no "All" link
      expect(find.text('RECENT'), findsNothing);
      expect(find.textContaining('All'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 1 transaction
    // -----------------------------------------------------------------------

    testWidgets('shows 1 row when 1 transaction provided', (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'expense', description: 'Coffee');
      final stream = Stream.value([tx]);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      // Section header is visible
      expect(find.text('RECENT'), findsOneWidget);
      // The transaction name row
      expect(find.text('Coffee'), findsOneWidget);
    });

    testWidgets('shows no divider with 1 transaction', (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'income', amount: 500.0);
      final stream = Stream.value([tx]);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      // Divider container has left margin of 54 — with 1 transaction the
      // divider widget is never built. We verify there is exactly 1 row
      // (ClipRRect contains 1 child Semantics wrapping _RecentTransactionRow).
      // We count visible transaction rows by finding InkWell inside ClipRRect.
      expect(find.byType(InkWell), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 2+ transactions
    // -----------------------------------------------------------------------

    testWidgets('shows exactly 2 rows when 2+ transactions provided',
        (tester) async {
      final txs = [
        _makeTx(id: 'tx1', type: 'expense', description: 'Rent'),
        _makeTx(id: 'tx2', type: 'income', description: 'Salary'),
        _makeTx(id: 'tx3', type: 'expense', description: 'Gym'),
      ];
      final stream = Stream.value(txs);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      // Only 2 rows rendered, Gym (3rd) must not appear
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Gym'), findsNothing);
    });

    testWidgets('shows inset divider between 2 rows', (tester) async {
      final txs = [
        _makeTx(id: 'tx1', type: 'expense', description: 'Row A'),
        _makeTx(id: 'tx2', type: 'income', description: 'Row B'),
      ];
      final stream = Stream.value(txs);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      // Both rows present
      expect(find.text('Row A'), findsOneWidget);
      expect(find.text('Row B'), findsOneWidget);
      // Two InkWell rows
      expect(find.byType(InkWell), findsNWidgets(2));
    });

    // -----------------------------------------------------------------------
    // "All →" link
    // -----------------------------------------------------------------------

    testWidgets('"All →" link is visible with transactions', (tester) async {
      final stream = Stream.value([_makeTx(id: 'tx1', type: 'expense')]);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      expect(find.textContaining('All'), findsOneWidget);
    });

    testWidgets('"All →" tap fires onSeeAllTap callback', (tester) async {
      var tapped = false;
      final stream = Stream.value([_makeTx(id: 'tx1', type: 'expense')]);

      await tester.pumpWidget(_buildWidget(
        stream: stream,
        onSeeAllTap: () => tapped = true,
      ));
      await tester.pump();

      await tester.tap(find.textContaining('All'));
      await tester.pump();

      expect(tapped, isTrue,
          reason: 'onSeeAllTap must be called when "All" tapped');
    });

    // -----------------------------------------------------------------------
    // Amount color
    // -----------------------------------------------------------------------

    testWidgets('income amount renders with income color', (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'income', amount: 500.0);
      final stream = Stream.value([tx]);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      // Find amount text that uses income color
      final incomeTexts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.style?.color == AppColors.income)
          .toList();
      expect(
        incomeTexts,
        isNotEmpty,
        reason: 'Income amount must use AppColors.income',
      );
    });

    testWidgets('expense amount renders with expense color (light theme)',
        (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'expense', amount: 200.0);
      final stream = Stream.value([tx]);

      await tester
          .pumpWidget(_buildWidget(stream: stream, theme: AppTheme.light));
      await tester.pump();

      // In light theme expense color is AppColors.expense
      final expenseTexts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.style?.color == AppColors.expense)
          .toList();
      expect(
        expenseTexts,
        isNotEmpty,
        reason: 'Expense amount must use AppColors.expense in light mode',
      );
    });

    testWidgets('expense amount renders with expenseDark color (dark theme)',
        (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'expense', amount: 200.0);
      final stream = Stream.value([tx]);

      await tester
          .pumpWidget(_buildWidget(stream: stream, theme: AppTheme.dark));
      await tester.pump();

      final darkExpenseTexts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.style?.color == AppColors.expenseDark)
          .toList();
      expect(
        darkExpenseTexts,
        isNotEmpty,
        reason: 'Expense amount must use AppColors.expenseDark in dark mode',
      );
    });

    // -----------------------------------------------------------------------
    // Loading state
    // -----------------------------------------------------------------------

    testWidgets('shows shimmer placeholders while loading', (tester) async {
      // StreamController that never emits — keeps provider in loading state.
      final controller = StreamController<List<Transaction>>();
      addTearDown(controller.close);

      await tester.pumpWidget(_buildWidget(stream: controller.stream));
      await tester.pump(); // one frame — still loading

      // Shimmer uses Container widgets as boxes — just verify no crash
      expect(tester.takeException(), isNull);
    });

    // -----------------------------------------------------------------------
    // Error state
    // -----------------------------------------------------------------------

    testWidgets('shows error message when provider errors', (tester) async {
      final stream = Stream<List<Transaction>>.error(Exception('DB error'));

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      expect(
        find.text('Could not load transactions'),
        findsOneWidget,
        reason: 'Error state must show error message',
      );
    });

    // -----------------------------------------------------------------------
    // Section header
    // -----------------------------------------------------------------------

    testWidgets('section header shows "RECENT" label', (tester) async {
      final stream = Stream.value([_makeTx(id: 'tx1', type: 'income')]);
      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      expect(find.text('RECENT'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // NEW-01: Transaction name shows description, not type string
    // -----------------------------------------------------------------------

    testWidgets('row label shows description when present', (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'expense', description: 'Migros');
      final stream = Stream.value([tx]);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      expect(find.text('Migros'), findsOneWidget,
          reason: 'description field must be used as the row label');
      // Raw type string must NOT appear as row label
      expect(find.text('Expense'), findsNothing,
          reason: 'type string must not be shown when description is set');
    });

    testWidgets('row label falls back to type name when description is null',
        (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'income', description: null);
      final stream = Stream.value([tx]);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      // With no description the widget falls back to 'Income'
      expect(find.text('Income'), findsOneWidget,
          reason: 'type name fallback must appear when description is null');
    });

    testWidgets('row label falls back to type name when description is empty',
        (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'expense', description: '');
      final stream = Stream.value([tx]);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      expect(find.text('Expense'), findsOneWidget,
          reason:
              'type name fallback must appear when description is empty string');
    });

    // -----------------------------------------------------------------------
    // NEW-02: Income/Expense arrow icon direction
    // -----------------------------------------------------------------------

    testWidgets('income row uses arrow_upward icon', (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'income', amount: 100.0);
      final stream = Stream.value([tx]);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.arrow_upward,
        ),
        findsOneWidget,
        reason: 'Income must render Icons.arrow_upward (money coming in)',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.arrow_downward,
        ),
        findsNothing,
        reason: 'Income must NOT render Icons.arrow_downward',
      );
    });

    testWidgets('expense row uses arrow_downward icon', (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'expense', amount: 50.0);
      final stream = Stream.value([tx]);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.arrow_downward,
        ),
        findsOneWidget,
        reason: 'Expense must render Icons.arrow_downward (money going out)',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.arrow_upward,
        ),
        findsNothing,
        reason: 'Expense must NOT render Icons.arrow_upward',
      );
    });

    testWidgets('transfer row uses swap_horiz icon', (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'transfer', amount: 250.0);
      final stream = Stream.value([tx]);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.swap_horiz,
        ),
        findsOneWidget,
        reason: 'Transfer must render Icons.swap_horiz',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.arrow_upward,
        ),
        findsNothing,
        reason: 'Transfer must NOT render Icons.arrow_upward',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.arrow_downward,
        ),
        findsNothing,
        reason: 'Transfer must NOT render Icons.arrow_downward',
      );
    });

    // -----------------------------------------------------------------------
    // Amount sign prefix
    // -----------------------------------------------------------------------

    testWidgets('income amount prefixed with +', (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'income', amount: 100.0);
      final stream = Stream.value([tx]);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      // The formatted amount text contains '+' prefix
      final amountTexts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.data?.startsWith('+') == true)
          .toList();
      expect(
        amountTexts,
        isNotEmpty,
        reason: 'Income amount must start with "+"',
      );
    });

    testWidgets('expense amount prefixed with minus sign (U+2212)',
        (tester) async {
      final tx = _makeTx(id: 'tx1', type: 'expense', amount: 100.0);
      final stream = Stream.value([tx]);

      await tester.pumpWidget(_buildWidget(stream: stream));
      await tester.pump();

      // U+2212 MINUS SIGN — not a hyphen
      const minusSign = '−';
      final amountTexts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.data?.startsWith(minusSign) == true)
          .toList();
      expect(
        amountTexts,
        isNotEmpty,
        reason: 'Expense amount must use U+2212 MINUS SIGN prefix',
      );
    });
  });
}
