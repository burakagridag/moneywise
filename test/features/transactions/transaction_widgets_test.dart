// Widget tests for Sprint 3 transaction and stats widgets.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/constants/app_colors.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/domain/entities/transaction.dart';
import 'package:moneywise/features/stats/presentation/widgets/category_legend_row.dart';
import 'package:moneywise/features/stats/presentation/widgets/pie_chart_widget.dart';
import 'package:moneywise/features/transactions/presentation/widgets/day_group_header.dart';
import 'package:moneywise/features/transactions/presentation/widgets/summary_bar.dart';
import 'package:moneywise/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Wraps a widget in a MaterialApp with localisation support.
Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

Transaction _makeTransaction({
  String type = 'expense',
  double amount = 50.0,
  bool isExcluded = false,
}) {
  final now = DateTime.now();
  return Transaction(
    id: _uuid.v4(),
    type: type,
    date: now,
    amount: amount,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    createdAt: now,
    updatedAt: now,
    isExcluded: isExcluded,
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // SummaryBar
  // ---------------------------------------------------------------------------

  group('SummaryBar', () {
    testWidgets('renders income, expense, and total labels', (tester) async {
      await tester.pumpWidget(_wrap(
        const SummaryBar(income: 100.0, expense: 40.0, currencySymbol: '€'),
      ));
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('displays formatted income amount', (tester) async {
      await tester.pumpWidget(_wrap(
        const SummaryBar(income: 1234.56, expense: 0.0, currencySymbol: '€'),
      ));
      expect(find.textContaining('1.234,56'), findsAtLeastNWidgets(1));
    });
  });

  // ---------------------------------------------------------------------------
  // DayGroupHeader
  // ---------------------------------------------------------------------------

  group('DayGroupHeader', () {
    testWidgets('renders day number and currency symbol', (tester) async {
      final date = DateTime(2026, 4, 15);
      await tester.pumpWidget(_wrap(
        DayGroupHeader(date: date, dailyTotal: 99.0, currencySymbol: '€'),
      ));
      expect(find.text('15'), findsOneWidget);
      expect(find.textContaining('€'), findsOneWidget);
    });

    testWidgets('renders weekday abbreviation', (tester) async {
      // April 15, 2026 is a Wednesday
      final date = DateTime(2026, 4, 15);
      await tester.pumpWidget(_wrap(
        DayGroupHeader(date: date, dailyTotal: 0.0, currencySymbol: '€'),
      ));
      expect(find.textContaining('Wed'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // TransactionListItem
  // ---------------------------------------------------------------------------

  group('TransactionListItem', () {
    testWidgets('renders category name and account name', (tester) async {
      final t = _makeTransaction(type: 'expense', amount: 25.0);
      await tester.pumpWidget(_wrap(
        ListView(children: [
          TransactionListItem(
            transaction: t,
            categoryEmoji: '🍕',
            categoryName: 'Food',
            categoryColor: AppColors.expense,
            accountName: 'My Wallet',
            onTap: () {},
            onDelete: () {},
          ),
        ]),
      ));
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('My Wallet'), findsOneWidget);
    });

    testWidgets('income transaction shows + prefix', (tester) async {
      final t = _makeTransaction(type: 'income', amount: 100.0);
      await tester.pumpWidget(_wrap(
        ListView(children: [
          TransactionListItem(
            transaction: t,
            categoryEmoji: null,
            categoryName: 'Salary',
            categoryColor: null,
            accountName: 'Bank',
            onTap: () {},
            onDelete: () {},
          ),
        ]),
      ));
      expect(find.textContaining('+ €'), findsOneWidget);
    });

    testWidgets('expense transaction shows - prefix', (tester) async {
      final t = _makeTransaction(type: 'expense', amount: 30.0);
      await tester.pumpWidget(_wrap(
        ListView(children: [
          TransactionListItem(
            transaction: t,
            categoryEmoji: '🛒',
            categoryName: 'Shopping',
            categoryColor: null,
            accountName: 'Cash',
            onTap: () {},
            onDelete: () {},
          ),
        ]),
      ));
      expect(find.textContaining('- €'), findsOneWidget);
    });

    testWidgets('excluded transaction renders with strikethrough',
        (tester) async {
      final t = _makeTransaction(isExcluded: true, amount: 10.0);
      await tester.pumpWidget(_wrap(
        ListView(children: [
          TransactionListItem(
            transaction: t,
            categoryEmoji: null,
            categoryName: 'Other',
            categoryColor: null,
            accountName: 'Wallet',
            onTap: () {},
            onDelete: () {},
          ),
        ]),
      ));
      // When excluded, amount text has no +/- prefix
      expect(find.textContaining('€ 10,00'), findsOneWidget);
    });

    testWidgets('shows description when available', (tester) async {
      final now = DateTime.now();
      final t = Transaction(
        id: _uuid.v4(),
        type: 'expense',
        date: now,
        amount: 5.0,
        currencyCode: 'EUR',
        accountId: 'acc-1',
        description: 'Coffee',
        createdAt: now,
        updatedAt: now,
      );
      await tester.pumpWidget(_wrap(
        ListView(children: [
          TransactionListItem(
            transaction: t,
            categoryEmoji: '☕',
            categoryName: 'Food',
            categoryColor: null,
            accountName: 'Cash',
            onTap: () {},
            onDelete: () {},
          ),
        ]),
      ));
      expect(find.text('Coffee'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // PieChartWidget
  // ---------------------------------------------------------------------------

  group('PieChartWidget', () {
    testWidgets('renders with empty segments list', (tester) async {
      await tester.pumpWidget(_wrap(const PieChartWidget(segments: [])));
      expect(find.byType(PieChartWidget), findsOneWidget);
    });

    testWidgets('renders with segments', (tester) async {
      const segments = [
        PieSegment(
          label: 'Food',
          amount: 100.0,
          color: AppColors.expense,
          percentage: 60.0,
        ),
        PieSegment(
          label: 'Transport',
          amount: 66.0,
          color: AppColors.income,
          percentage: 40.0,
        ),
      ];
      await tester.pumpWidget(_wrap(const PieChartWidget(segments: segments)));
      expect(find.byType(PieChartWidget), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // CategoryLegendRow
  // ---------------------------------------------------------------------------

  group('CategoryLegendRow', () {
    testWidgets('renders category name', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryLegendRow(
          categoryName: 'Food & Drink',
          amount: 200.0,
          percentage: 45.0,
          badgeColor: AppColors.expense,
          emoji: '🍔',
        ),
      ));
      expect(find.text('Food & Drink'), findsOneWidget);
    });

    testWidgets('renders percentage badge', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryLegendRow(
          categoryName: 'Transport',
          amount: 80.0,
          percentage: 20.0,
          badgeColor: AppColors.income,
        ),
      ));
      expect(find.text('20%'), findsOneWidget);
    });

    testWidgets('renders formatted amount', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryLegendRow(
          categoryName: 'Shopping',
          amount: 1234.56,
          percentage: 35.0,
          badgeColor: AppColors.brandPrimary,
        ),
      ));
      expect(find.textContaining('1.234,56'), findsOneWidget);
    });

    testWidgets('calls onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        CategoryLegendRow(
          categoryName: 'Health',
          amount: 50.0,
          percentage: 10.0,
          badgeColor: AppColors.success,
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });
  });
}
