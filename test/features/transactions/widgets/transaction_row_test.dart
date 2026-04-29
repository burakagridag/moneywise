// Widget tests for TransactionRow — features/transactions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/constants/app_colors.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/domain/entities/transaction.dart';
import 'package:moneywise/features/transactions/presentation/widgets/transaction_row.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Transaction _makeTransaction({
  String type = 'expense',
  double amount = 42.0,
  bool isExcluded = false,
}) {
  final now = DateTime(2026, 4, 15);
  return Transaction(
    id: 'tx-test-001',
    type: type,
    amount: amount,
    currencyCode: 'EUR',
    accountId: 'acc_1',
    date: now,
    isExcluded: isExcluded,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildRow(TransactionRow row) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: AppTheme.light,
    home: Scaffold(body: row),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TransactionRow', () {
    testWidgets('shows income color for income type', (tester) async {
      final tx = _makeTransaction(type: 'income', amount: 100.0);
      await tester.pumpWidget(_buildRow(
        TransactionRow(transaction: tx, currencySymbol: '€'),
      ));
      await tester.pump();

      // The amount text should be rendered with income color.
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.style?.color == AppColors.income)
          .toList();
      expect(texts, isNotEmpty,
          reason: 'Income text should use AppColors.income color');
    });

    testWidgets('shows expense color for expense type', (tester) async {
      final tx = _makeTransaction(type: 'expense', amount: 55.0);
      await tester.pumpWidget(_buildRow(
        TransactionRow(transaction: tx, currencySymbol: '€'),
      ));
      await tester.pump();

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.style?.color == AppColors.expense)
          .toList();
      expect(texts, isNotEmpty,
          reason: 'Expense text should use AppColors.expense color');
    });

    testWidgets('shows strikethrough when excluded', (tester) async {
      final tx = _makeTransaction(
        type: 'expense',
        amount: 20.0,
        isExcluded: true,
      );
      await tester.pumpWidget(_buildRow(
        TransactionRow(transaction: tx, currencySymbol: '€'),
      ));
      await tester.pump();

      // The amount text should have lineThrough decoration.
      final strikeTexts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.style?.decoration == TextDecoration.lineThrough)
          .toList();
      expect(strikeTexts, isNotEmpty,
          reason: 'Excluded transaction must show strikethrough decoration');
    });

    testWidgets('calls onDelete when confirmed', (tester) async {
      bool deleteCalled = false;
      final tx = _makeTransaction(type: 'expense');

      await tester.pumpWidget(_buildRow(
        TransactionRow(
          transaction: tx,
          currencySymbol: '€',
          onDelete: () => deleteCalled = true,
        ),
      ));
      await tester.pump();

      // Swipe end-to-start to trigger Dismissible.
      await tester.drag(
        find.byType(Dismissible),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // Confirm dialog should appear — tap Delete button.
      expect(find.text('Delete'), findsAtLeastNWidgets(1));
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue,
          reason: 'onDelete callback must be fired after confirmation');
    });
  });
}
