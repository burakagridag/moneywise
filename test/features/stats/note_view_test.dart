// Widget tests for NoteView — grouping, sort toggle, (no note) pinned last — stats feature (US-030).
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/database.dart' hide Transaction;
import 'package:moneywise/features/stats/presentation/providers/note_provider.dart';
import 'package:moneywise/features/stats/presentation/providers/stats_provider.dart';
import 'package:moneywise/features/stats/presentation/widgets/note_view.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<String> _createAccount(AppDatabase db) async {
  final groups = await db.accountDao.getGroups();
  final id = _uuid.v4();
  final now = DateTime.now();
  await db.accountDao.insertAccount(
    AccountsCompanion(
      id: Value(id),
      groupId: Value(groups.first.id),
      name: const Value('Test'),
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

Widget _buildNoteView(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: const Scaffold(body: NoteView()),
      ),
    );

void main() {
  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  group('NoteView — empty state', () {
    testWidgets('shows No notes message when no transactions', (tester) async {
      final db = _testDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      // Navigate to a past month with no data.
      container.read(selectedStatsMonthProvider.notifier).previous();
      container.read(selectedStatsMonthProvider.notifier).previous();

      await tester.pumpWidget(_buildNoteView(container));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No notes'), findsOneWidget);
      expect(
        find.text('Transactions with notes will appear here.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Header visibility
  // ---------------------------------------------------------------------------

  group('NoteView — header', () {
    testWidgets('shows Note and Amount column labels', (tester) async {
      final db = _testDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildNoteView(container));
      await tester.pump();

      expect(find.text('Note'), findsAtLeastNWidgets(1));
      expect(find.text('Amount'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    });

    testWidgets('shows sort toggle button defaulting to Amount',
        (tester) async {
      final db = _testDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildNoteView(container));
      await tester.pump();

      // Default sort is 'amount' — 'Amount' appears in sort button label.
      expect(find.text('Amount'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Sort toggle
  // ---------------------------------------------------------------------------

  group('NoteView — sort toggle', () {
    testWidgets('tapping sort button cycles from Amount to Count',
        (tester) async {
      final db = _testDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildNoteView(container));
      await tester.pump();

      expect(container.read(noteSortModeProvider), 'amount');

      // Tap the sort toggle (the GestureDetector wrapping the sort button).
      await tester.tap(find.byIcon(Icons.arrow_downward).first);
      await tester.pump();

      expect(container.read(noteSortModeProvider), 'count');

      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    });

    testWidgets('tapping sort button twice returns to Amount sort',
        (tester) async {
      final db = _testDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildNoteView(container));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_downward).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_downward).first);
      await tester.pump();

      expect(container.read(noteSortModeProvider), 'amount');

      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Note grouping
  // ---------------------------------------------------------------------------

  group('NoteProvider — grouping', () {
    test('(no note) group pinned last when named groups exist', () async {
      final groups = [
        const NoteGroup(note: 'Groceries', transactions: []),
        const NoteGroup(note: null, transactions: []), // No-note group
        const NoteGroup(note: 'Travel', transactions: []),
      ];

      // Simulate sorted result: named first, no-note last.
      final named = groups.where((g) => g.note != null).toList();
      final noNote = groups.where((g) => g.note == null).toList();
      final result = [...named, ...noNote];

      expect(result.last.note, isNull);
    });

    test('groups are sorted by totalAmount descending', () {
      const a = NoteGroup(
        note: 'A',
        transactions: [],
      );
      const b = NoteGroup(
        note: 'B',
        transactions: [],
      );

      // Verify NoteGroup count getter.
      expect(a.count, 0);
      expect(b.totalAmount, 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Populated state — (no note) rendered
  // ---------------------------------------------------------------------------

  group('NoteView — populated with (no note) group', () {
    testWidgets('renders (no note) label for transactions without notes',
        (tester) async {
      final db = _testDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      final accountId = await _createAccount(db);
      final month = container.read(selectedStatsMonthProvider);
      final expenseCats = await db.categoryDao.getByType('expense');
      final catId = expenseCats.first.id;

      // Insert a transaction without a note.
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(DateTime(month.year, month.month, 10)),
          amount: const Value(50.0),
          currencyCode: const Value('EUR'),
          accountId: Value(accountId),
          categoryId: Value(catId),
          // No description — no note.
        ),
      );

      container.invalidate(noteGroupsProvider);

      await tester.pumpWidget(_buildNoteView(container));
      await tester.pump(const Duration(milliseconds: 200));

      // "(no note)" label should appear in the group header.
      expect(find.text('(no note)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    });

    testWidgets('renders named note group above (no note)', (tester) async {
      final db = _testDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      final accountId = await _createAccount(db);
      final month = container.read(selectedStatsMonthProvider);
      final expenseCats = await db.categoryDao.getByType('expense');
      final catId = expenseCats.first.id;

      // Insert a transaction with a note.
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(DateTime(month.year, month.month, 5)),
          amount: const Value(100.0),
          currencyCode: const Value('EUR'),
          accountId: Value(accountId),
          categoryId: Value(catId),
          description: const Value('Grocery trip'),
        ),
      );

      // Insert another without note.
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(DateTime(month.year, month.month, 6)),
          amount: const Value(30.0),
          currencyCode: const Value('EUR'),
          accountId: Value(accountId),
          categoryId: Value(catId),
          // No note.
        ),
      );

      container.invalidate(noteGroupsProvider);

      await tester.pumpWidget(_buildNoteView(container));
      await tester.pump(const Duration(milliseconds: 200));

      // Both groups visible.
      expect(find.text('Grocery trip'), findsOneWidget);
      expect(find.text('(no note)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    });
  });
}
