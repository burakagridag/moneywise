// Widget tests for TransactionListItem — delete confirmation dialog and
// transfer type rendering — transactions feature.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/domain/entities/transaction.dart';
import 'package:moneywise/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: ListView(children: [child])),
    );

Transaction _makeTransaction({
  String type = 'expense',
  double amount = 50.0,
  bool isExcluded = false,
  String? description,
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
    description: description,
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // Transfer type
  // ---------------------------------------------------------------------------

  group('TransactionListItem — transfer type', () {
    testWidgets('transfer transaction has no +/- prefix', (tester) async {
      final t = _makeTransaction(type: 'transfer', amount: 200.0);
      await tester.pumpWidget(_wrap(
        TransactionListItem(
          transaction: t,
          categoryEmoji: null,
          categoryName: 'Transfer',
          categoryColor: null,
          accountName: 'Savings',
          currencySymbol: '€',
          onTap: () {},
          onDelete: () {},
        ),
      ));

      // Amount shows without +/- for transfer type.
      expect(find.textContaining('€ 200,00'), findsOneWidget);
      expect(find.textContaining('+ €'), findsNothing);
      expect(find.textContaining('- €'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // No emoji — shows swap icon
  // ---------------------------------------------------------------------------

  group('TransactionListItem — no emoji fallback', () {
    testWidgets('shows swap icon when categoryEmoji is null', (tester) async {
      final t = _makeTransaction(type: 'income', amount: 500.0);
      await tester.pumpWidget(_wrap(
        TransactionListItem(
          transaction: t,
          categoryEmoji: null,
          categoryName: 'Salary',
          categoryColor: null,
          accountName: 'Bank',
          onTap: () {},
          onDelete: () {},
        ),
      ));

      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Delete confirmation dialog
  // ---------------------------------------------------------------------------

  group('TransactionListItem — delete confirmation dialog', () {
    testWidgets('swipe reveals delete background', (tester) async {
      final t = _makeTransaction(type: 'expense', amount: 25.0);
      await tester.pumpWidget(_wrap(
        TransactionListItem(
          transaction: t,
          categoryEmoji: '🍕',
          categoryName: 'Food',
          categoryColor: null,
          accountName: 'Wallet',
          onTap: () {},
          onDelete: () {},
        ),
      ));

      // Drag to reveal dismiss background.
      await tester.drag(
        find.byType(Dismissible),
        const Offset(-300, 0),
      );
      await tester.pump();

      // Delete background icon appears.
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('confirms delete dialog shows Cancel and Delete buttons',
        (tester) async {
      final t = _makeTransaction(type: 'expense', amount: 30.0);
      await tester.pumpWidget(_wrap(
        TransactionListItem(
          transaction: t,
          categoryEmoji: '🛒',
          categoryName: 'Shopping',
          categoryColor: null,
          accountName: 'Cash',
          onTap: () {},
          onDelete: () {},
        ),
      ));

      // Perform a full swipe to trigger confirmDismiss callback.
      await tester.drag(
        find.byType(Dismissible),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // The confirmation dialog must be shown.
      expect(find.text('Delete transaction?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('tapping Cancel dismisses the dialog without deleting',
        (tester) async {
      bool deleted = false;
      final t = _makeTransaction(type: 'expense', amount: 30.0);
      await tester.pumpWidget(_wrap(
        TransactionListItem(
          transaction: t,
          categoryEmoji: null,
          categoryName: 'Other',
          categoryColor: null,
          accountName: 'Wallet',
          onTap: () {},
          onDelete: () => deleted = true,
        ),
      ));

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deleted, isFalse);
      // Dialog closed — item is still visible.
      expect(find.text('Delete transaction?'), findsNothing);
    });

    testWidgets('tapping Delete in dialog triggers onDelete callback',
        (tester) async {
      bool deleted = false;
      final t = _makeTransaction(type: 'expense', amount: 15.0);
      await tester.pumpWidget(_wrap(
        TransactionListItem(
          transaction: t,
          categoryEmoji: null,
          categoryName: 'Bills',
          categoryColor: null,
          accountName: 'Bank',
          onTap: () {},
          onDelete: () => deleted = true,
        ),
      ));

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });
}
