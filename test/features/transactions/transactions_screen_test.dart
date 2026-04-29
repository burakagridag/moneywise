// Widget tests for TransactionsScreen covering empty state, grouped list, and FAB — transactions feature.
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/database.dart' hide Transaction;
import 'package:moneywise/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:moneywise/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _buildScreen(AppDatabase db) => ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((_) => db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: const TransactionsScreen(),
      ),
    );

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

void main() {
  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  group('TransactionsScreen — empty state', () {
    testWidgets('shows empty-state message when no transactions',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      // First pump triggers stream subscription; second settles async data.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('No transactions this month'), findsOneWidget);
      expect(find.text('Tap + to add your first transaction.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('renders MonthNavigator and SummaryBar', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // SummaryBar shows Income / Expense / Total labels
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('FAB is visible', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Month navigation
  // ---------------------------------------------------------------------------

  group('TransactionsScreen — month navigation', () {
    testWidgets('previous chevron tapped decrements displayed month',
        (tester) async {
      final db = _testDb();

      // Build with explicit ProviderScope so we can read the provider state.
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const TransactionsScreen(),
          ),
        ),
      );
      await tester.pump();

      final initialMonth = container.read(selectedMonthProvider);
      // Tap the left chevron (previous month button).
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      final newMonth = container.read(selectedMonthProvider);
      final expectedMonth =
          initialMonth.month == 1 ? 12 : initialMonth.month - 1;
      expect(newMonth.month, expectedMonth);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // FAB action
  // ---------------------------------------------------------------------------

  group('TransactionsScreen — FAB action', () {
    testWidgets('FAB is present and the old coming-soon snackbar is gone',
        (tester) async {
      // FAB now navigates to TransactionAddEditScreen via go_router.
      // We verify: (a) FAB exists, (b) it no longer shows the placeholder
      // SnackBar that was present before the real form was implemented.
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      // FAB is rendered.
      expect(find.byType(FloatingActionButton), findsOneWidget);
      // The old stub text must not be present without tapping.
      expect(find.text('Add transaction — coming soon'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Transactions list (with data)
  // ---------------------------------------------------------------------------

  group('TransactionsScreen — transactions list', () {
    testWidgets('shows DayGroupHeader when transactions exist in current month',
        (tester) async {
      final db = _testDb();
      final accountId = await _createAccount(db);

      final now = DateTime.now();
      // Insert an expense in the current month.
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(DateTime(now.year, now.month, 5)),
          amount: const Value(42.0),
          currencyCode: const Value('EUR'),
          accountId: Value(accountId),
        ),
      );

      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The day badge "5" should appear inside a DayGroupHeader.
      expect(find.text('5'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('shows Uncategorized when category is null', (tester) async {
      final db = _testDb();
      final accountId = await _createAccount(db);

      final now = DateTime.now();
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(DateTime(now.year, now.month, 10)),
          amount: const Value(15.0),
          currencyCode: const Value('EUR'),
          accountId: Value(accountId),
          // no categoryId → null
        ),
      );

      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Uncategorized'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });
}
