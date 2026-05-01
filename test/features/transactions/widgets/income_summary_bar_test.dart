// Widget tests for IncomeSummaryBar — features/transactions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/transactions/presentation/widgets/income_summary_bar.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildBar({required double income, required double expense}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: AppTheme.light,
    home: Scaffold(
      body: IncomeSummaryBar(income: income, expense: expense),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('IncomeSummaryBar', () {
    testWidgets('should_display_correct_income_amount', (tester) async {
      await tester.pumpWidget(_buildBar(income: 1234.00, expense: 0));
      await tester.pump();

      // Expect formatted income somewhere in the tree.
      expect(find.textContaining('1.234'), findsAtLeastNWidgets(1),
          reason: 'Income amount should be displayed formatted');
    });

    testWidgets('should_display_correct_expense_amount', (tester) async {
      await tester.pumpWidget(_buildBar(income: 0, expense: 567.89));
      await tester.pump();

      expect(find.textContaining('567'), findsAtLeastNWidgets(1),
          reason: 'Expense amount should be displayed formatted');
    });

    testWidgets('should_display_correct_net_total', (tester) async {
      // income 500, expense 200 → net = +300
      await tester.pumpWidget(_buildBar(income: 500.0, expense: 200.0));
      await tester.pump();

      // Net total uses + prefix when positive.
      expect(find.textContaining('+'), findsAtLeastNWidgets(1),
          reason: 'Net total should show + prefix when income > expense');
    });

    testWidgets('shows Income, Exp., and Total column labels', (tester) async {
      await tester.pumpWidget(_buildBar(income: 0, expense: 0));
      await tester.pump();

      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('shows negative net when expense exceeds income',
        (tester) async {
      await tester.pumpWidget(_buildBar(income: 100.0, expense: 300.0));
      await tester.pump();

      // Net is -200, expect minus sign.
      expect(find.textContaining('-'), findsAtLeastNWidgets(1),
          reason: 'Net total should show - prefix when expense > income');
    });
  });
}
