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
  int id = 1,
  TransactionType type = TransactionType.expense,
  double amount = 42.0,
  bool isExcluded = false,
}) {
  return Transaction(
    id: id,
    type: type,
    amount: amount,
    currencyCode: 'EUR',
    accountId: 'acc_1',
    date: DateTime(2026, 4, 15),
    isExcluded: isExcluded,
    createdAt: DateTime(2026, 4, 15),
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
    testWidgets('should_show_income_color_for_income_type', (tester) async {
      final tx = _makeTransaction(type: TransactionType.income, amount: 100.0);
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

    testWidgets('should_show_expense_color_for_expense_type', (tester) async {
      final tx = _makeTransaction(type: TransactionType.expense, amount: 55.0);
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

    testWidgets('should_show_strikethrough_when_excluded', (tester) async {
      final tx = _makeTransaction(
        type: TransactionType.expense,
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

    testWidgets('should_call_onDelete_when_confirmed', (tester) async {
      bool deleteCalled = false;
      final tx = _makeTransaction(type: TransactionType.expense);

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
