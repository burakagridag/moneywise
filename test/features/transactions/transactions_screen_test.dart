// Widget tests for TransactionsScreen and sub-widgets — features/transactions.
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:moneywise/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:moneywise/features/transactions/presentation/widgets/income_summary_bar.dart';
import 'package:moneywise/features/transactions/presentation/widgets/month_navigator.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Wraps [child] with the full scaffold needed for transactions feature.
Widget _buildWithDb(AppDatabase db, Widget child) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWith((_) => db)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: AppTheme.light,
      home: child,
    ),
  );
}

/// Disposes the widget tree and drains all Drift timer callbacks.
Future<void> _dispose(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 4; i++) {
    await tester.pump(Duration.zero);
  }
  await db.close();
}

/// Creates a test account inside the in-memory DB.
Future<String> _createAccount(AppDatabase db) async {
  final groups = await db.accountDao.getGroups();
  final id = _uuid.v4();
  final now = DateTime.now();
  await db.accountDao.insertAccount(
    AccountsCompanion(
      id: Value(id),
      groupId: Value(groups.first.id),
      name: const Value('Wallet'),
      currencyCode: const Value('EUR'),
      initialBalance: const Value(0.0),
      sortOrder: const Value(0),
      isHidden: const Value(false),
      includeInTotals: const Value(true),
      isDeleted: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );
  return id;
}

// ---------------------------------------------------------------------------
// TransactionsScreen — structure tests
// ---------------------------------------------------------------------------

void main() {
  group('TransactionsScreen structure', () {
    testWidgets('renders without crashing', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildWithDb(db, const TransactionsScreen()));
      await tester.pump();
      expect(find.byType(TransactionsScreen), findsOneWidget);
      await _dispose(tester, db);
    });

    testWidgets('shows Trans. title in AppBar', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildWithDb(db, const TransactionsScreen()));
      await tester.pump();
      expect(find.text('Trans.'), findsOneWidget);
      await _dispose(tester, db);
    });

    testWidgets('shows MonthNavigator widget', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildWithDb(db, const TransactionsScreen()));
      await tester.pump();
      expect(find.byType(MonthNavigator), findsOneWidget);
      await _dispose(tester, db);
    });

    testWidgets('shows TabBar with 5 tabs including Description',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildWithDb(db, const TransactionsScreen()));
      await tester.pump();
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      await _dispose(tester, db);
    });

    testWidgets('shows IncomeSummaryBar', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildWithDb(db, const TransactionsScreen()));
      await tester.pump();
      expect(find.byType(IncomeSummaryBar), findsOneWidget);
      await _dispose(tester, db);
    });

    testWidgets('shows primary FAB to add transaction', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildWithDb(db, const TransactionsScreen()));
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsAtLeastNWidgets(1));
      await _dispose(tester, db);
    });

    testWidgets('shows search icon button in AppBar', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildWithDb(db, const TransactionsScreen()));
      await tester.pump();
      // The search icon may appear in both the AppBar action and the
      // TransactionSearchBar widget — verify at least one is present.
      expect(find.byIcon(Icons.search), findsAtLeastNWidgets(1));
      await _dispose(tester, db);
    });

    testWidgets('shows bookmark FAB on all tabs (BUG-011 fix)', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildWithDb(db, const TransactionsScreen()));
      await tester.pump();
      // Both FABs are always rendered — bookmark and add-transaction.
      expect(find.byType(FloatingActionButton), findsNWidgets(2));
      await _dispose(tester, db);
    });

    testWidgets('Description tab shows Coming soon placeholder (BUG-001 fix)',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildWithDb(db, const TransactionsScreen()));
      await tester.pump();
      // The IndexedStack always renders all children — the placeholder text is
      // present in the widget tree even before the tab is tapped.
      // After tapping Description, the IndexedStack shows index 4.
      await tester.tap(find.text('Description'));
      await tester.pumpAndSettle();
      expect(find.text('Coming soon'), findsOneWidget);
      await _dispose(tester, db);
    });

    testWidgets('shows income and expense labels in summary bar',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildWithDb(db, const TransactionsScreen()));
      await tester.pump();
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Exp.'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      await _dispose(tester, db);
    });
  });

  // ---------------------------------------------------------------------------
  // IncomeSummaryBar — unit-level widget tests
  // ---------------------------------------------------------------------------

  group('IncomeSummaryBar', () {
    Widget buildBar({required double income, required double expense}) {
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

    testWidgets('renders IncomeSummaryBar widget', (tester) async {
      await tester.pumpWidget(buildBar(income: 0, expense: 0));
      expect(find.byType(IncomeSummaryBar), findsOneWidget);
    });

    testWidgets('shows Income, Exp., Total column labels', (tester) async {
      await tester.pumpWidget(buildBar(income: 0, expense: 0));
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Exp.'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('formats positive income amount', (tester) async {
      await tester.pumpWidget(buildBar(income: 1234.56, expense: 0));
      expect(find.textContaining('1,234.56'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows + prefix in Total when income > expense',
        (tester) async {
      await tester.pumpWidget(buildBar(income: 500.0, expense: 200.0));
      await tester.pump();
      expect(find.textContaining('+'), findsAtLeastNWidgets(1));
    });
  });

  // ---------------------------------------------------------------------------
  // MonthNavigator — widget tests
  // ---------------------------------------------------------------------------

  group('MonthNavigator', () {
    Widget buildNav({bool showYearOnly = false}) {
      return ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: AppTheme.light,
          home: Scaffold(
            body: MonthNavigator(showYearOnly: showYearOnly),
          ),
        ),
      );
    }

    testWidgets('renders MonthNavigator in month mode', (tester) async {
      await tester.pumpWidget(buildNav());
      expect(find.byType(MonthNavigator), findsOneWidget);
    });

    testWidgets('shows previous arrow icon', (tester) async {
      await tester.pumpWidget(buildNav());
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });

    testWidgets('shows next arrow icon', (tester) async {
      await tester.pumpWidget(buildNav());
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows current month and year in label', (tester) async {
      await tester.pumpWidget(buildNav());
      final now = DateTime.now();
      // Label contains the year digits at minimum
      expect(find.textContaining(now.year.toString()), findsAtLeastNWidgets(1));
    });

    testWidgets('in year-only mode shows 4-digit year', (tester) async {
      await tester.pumpWidget(buildNav(showYearOnly: true));
      final now = DateTime.now();
      expect(find.text(now.year.toString()), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // DailyView — transactions list with data
  // ---------------------------------------------------------------------------

  group('DailyView — transactions list', () {
    testWidgets('transaction with category renders category name',
        (tester) async {
      final db = _testDb();
      final accountId = await _createAccount(db);

      // Insert a category with a colorHex.
      final catId = _uuid.v4();
      final catNow = DateTime.now();
      await db.into(db.categories).insert(
            CategoriesCompanion(
              id: Value(catId),
              name: const Value('Food'),
              type: const Value('expense'),
              iconEmoji: const Value('🍕'),
              colorHex: const Value('FF5733'),
              sortOrder: const Value(99),
              isDefault: const Value(false),
              isDeleted: const Value(false),
              createdAt: Value(catNow),
              updatedAt: Value(catNow),
            ),
          );

      final now = DateTime.now();
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(DateTime(now.year, now.month, 12)),
          amount: const Value(88.0),
          currencyCode: const Value('EUR'),
          accountId: Value(accountId),
          categoryId: Value(catId),
        ),
      );

      await tester.pumpWidget(_buildWithDb(db, const TransactionsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Food'), findsOneWidget);
      await _dispose(tester, db);
    });

    testWidgets('transaction with invalid colorHex still renders',
        (tester) async {
      final db = _testDb();
      final accountId = await _createAccount(db);

      final catId = _uuid.v4();
      final catNow = DateTime.now();
      // Intentionally invalid hex → _parseColor catches the error and returns null.
      await db.into(db.categories).insert(
            CategoriesCompanion(
              id: Value(catId),
              name: const Value('Transport'),
              type: const Value('expense'),
              colorHex: const Value('GGGGGG'),
              sortOrder: const Value(100),
              isDefault: const Value(false),
              isDeleted: const Value(false),
              createdAt: Value(catNow),
              updatedAt: Value(catNow),
            ),
          );

      final now = DateTime.now();
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(DateTime(now.year, now.month, 14)),
          amount: const Value(22.0),
          currencyCode: const Value('EUR'),
          accountId: Value(accountId),
          categoryId: Value(catId),
        ),
      );

      await tester.pumpWidget(_buildWithDb(db, const TransactionsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Transport'), findsOneWidget);
      await _dispose(tester, db);
    });
  });
}
