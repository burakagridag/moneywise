// Full integration smoke test suite for EPIC8D-01 Transactions Screen Redesign.
// Sponsor directive: Pre-PR Full Regression Smoke Gate
//
// Run with:
//   flutter test integration_test/epic8d01_full_test.dart \
//     -d D6304F8C-B2AF-4B0E-B2E2-5A95AD62EC25
//
// Test categories:
//   F1–F10 — Functional (Liste/Takvim/Özet × locale × theme matrix)
//   E1–E3  — Edge cases (income-only, large amounts, dark TR Özet)

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/database.dart' hide Transaction;
import 'package:moneywise/features/transactions/presentation/widgets/transactions_view.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Screenshot helpers
// ---------------------------------------------------------------------------

const _screenshotDir =
    '/Users/burakagridag/Documents/projects/mobileapps/moneywise'
    '/docs/qa/EPIC8D-01-smoke-test/screenshots/full-test';

Future<void> _screenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  try {
    final bytes = await binding.takeScreenshot(name);
    final file = File('$_screenshotDir/$name.png');
    await file.writeAsBytes(bytes);
    print('Screenshot saved: $name.png');
  } catch (e) {
    print('Screenshot failed for $name: $e');
  }
}

// ---------------------------------------------------------------------------
// Test DB + widget helpers
// ---------------------------------------------------------------------------

const _uuid = Uuid();

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Builds a [TransactionsView] under a minimal host scaffold that satisfies
/// both go_router (needed by TransactionsEmptyState and TransactionsListTab)
/// and the TabController requirement of TransactionsView.
///
/// A stub GoRouter with a single '/' route is used — navigation calls from
/// the FAB / empty-state CTA are not exercised in these smoke tests.
Widget _buildTransactionsView(
  AppDatabase db, {
  Locale locale = const Locale('en'),
  bool darkMode = false,
}) {
  // Stub router: one route renders the actual view. Navigation pushes (e.g.
  // Routes.transactionAddEdit) will silently no-op because GoRouter.go('/404')
  // falls through to the error builder, which we leave as the default.
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => _TransactionsTestHost(db: db),
      ),
    ],
  );

  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWith((_) => db)],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: darkMode ? AppTheme.dark : AppTheme.light,
    ),
  );
}

/// Internal host widget that owns the [TabController] and passes it to
/// [TransactionsView], matching the pattern used by [TransactionsScreen].
class _TransactionsTestHost extends StatefulWidget {
  const _TransactionsTestHost({required this.db});

  final AppDatabase db;

  @override
  State<_TransactionsTestHost> createState() => _TransactionsTestHostState();
}

class _TransactionsTestHostState extends State<_TransactionsTestHost>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: kTabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransactionsView(tabController: _tabController),
    );
  }
}

// ---------------------------------------------------------------------------
// Seeding helpers
// ---------------------------------------------------------------------------

/// Seeds a test cash account. Returns its ID.
Future<String> _seedAccount(AppDatabase db) async {
  final groups = await db.accountDao.getGroups();
  final group = groups.first;
  final accountId = _uuid.v4();
  await db.accountDao.insertAccount(
    AccountsCompanion(
      id: Value(accountId),
      groupId: Value(group.id),
      name: const Value('Test Wallet'),
      currencyCode: const Value('EUR'),
      initialBalance: const Value(0.0),
      sortOrder: const Value(0),
      includeInTotals: const Value(true),
      isDeleted: const Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ),
  );
  return accountId;
}

/// Returns the ID of the first income category.
Future<String> _incomeCategory(AppDatabase db) async {
  final cats = await db.categoryDao.getByType('income');
  return cats.first.id;
}

/// Returns the ID of the first expense category.
Future<String> _expenseCategory(AppDatabase db) async {
  final cats = await db.categoryDao.getByType('expense');
  return cats.first.id;
}

/// Seeds an income transaction for the current month.
Future<void> _seedIncome(
  AppDatabase db, {
  required String accountId,
  required String categoryId,
  double amount = 1000.0,
}) async {
  await db.transactionDao.insertTransaction(
    TransactionsCompanion(
      id: Value(_uuid.v4()),
      type: const Value('income'),
      date: Value(DateTime.now()),
      amount: Value(amount),
      currencyCode: const Value('EUR'),
      exchangeRate: const Value(1.0),
      accountId: Value(accountId),
      categoryId: Value(categoryId),
      isExcluded: const Value(false),
      isDeleted: const Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ),
  );
}

/// Seeds an expense transaction for the current month.
Future<void> _seedExpense(
  AppDatabase db, {
  required String accountId,
  required String categoryId,
  double amount = 50.0,
}) async {
  await db.transactionDao.insertTransaction(
    TransactionsCompanion(
      id: Value(_uuid.v4()),
      type: const Value('expense'),
      date: Value(DateTime.now()),
      amount: Value(amount),
      currencyCode: const Value('EUR'),
      exchangeRate: const Value(1.0),
      accountId: Value(accountId),
      categoryId: Value(categoryId),
      isExcluded: const Value(false),
      isDeleted: const Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ),
  );
}

// ---------------------------------------------------------------------------
// Teardown helper
// ---------------------------------------------------------------------------

Future<void> _teardown(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(Duration.zero);
  await db.close();
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // F1 — Liste tab, populated, light mode (EN)
  // Seed: 1 income (€1000) + 1 expense (€50)
  // =========================================================================

  testWidgets(
      'F1: Liste tab populated — summary strip shows Income/Expense/Net, '
      'day-grouped card visible, amounts rendered (EN light)', (tester) async {
    final db = _testDb();
    final accountId = await _seedAccount(db);
    final incomeCatId = await _incomeCategory(db);
    final expenseCatId = await _expenseCategory(db);
    await _seedIncome(db, accountId: accountId, categoryId: incomeCatId);
    await _seedExpense(db, accountId: accountId, categoryId: expenseCatId);

    await tester.pumpWidget(_buildTransactionsView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Summary strip labels
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Net'), findsOneWidget);

    // Tab bar visible (transactions exist)
    expect(find.text('List'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);

    // Income amount rendered — locale formats may vary (1.000 or 1,000)
    final hasIncomeAmount = tester.any(find.textContaining('1,000')) ||
        tester.any(find.textContaining('1.000')) ||
        tester.any(find.textContaining('1000'));
    expect(hasIncomeAmount, isTrue,
        reason: 'Income amount €1000 should appear in the summary strip');

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'f1_liste_light_en');
    await _teardown(tester, db);
  });

  // =========================================================================
  // F2 — Liste tab, empty state, light mode (EN)
  // No transactions seeded
  // =========================================================================

  testWidgets(
      'F2: Empty state — "No transactions yet" + CTA visible, '
      'tab bar NOT shown (EN light)', (tester) async {
    final db = _testDb();

    await tester.pumpWidget(_buildTransactionsView(db));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Add first transaction'), findsOneWidget);

    // Tab bar must NOT be visible in empty state per AC (no tab bar rendered)
    expect(find.text('List'), findsNothing);
    expect(find.text('Calendar'), findsNothing);
    expect(find.text('Summary'), findsNothing);

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'f2_empty_light_en');
    await _teardown(tester, db);
  });

  // =========================================================================
  // F3 — Takvim tab, light mode (EN)
  // Seed: 1 expense (€75)
  // =========================================================================

  testWidgets(
      'F3: Takvim tab — weekday headers Mo/Tu/We/Th/Fr/Sa/Su visible (EN light)',
      (tester) async {
    final db = _testDb();
    final accountId = await _seedAccount(db);
    final expenseCatId = await _expenseCategory(db);
    await _seedExpense(db,
        accountId: accountId, categoryId: expenseCatId, amount: 75.0);

    await tester.pumpWidget(_buildTransactionsView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Switch to tab index 1 (Takvim / Calendar)
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Weekday header letters
    expect(find.text('Mo'), findsOneWidget);
    expect(find.text('Tu'), findsOneWidget);
    expect(find.text('We'), findsOneWidget);
    expect(find.text('Th'), findsOneWidget);
    expect(find.text('Fr'), findsOneWidget);
    expect(find.text('Sa'), findsOneWidget);
    expect(find.text('Su'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'f3_calendar_light_en');
    await _teardown(tester, db);
  });

  // =========================================================================
  // F4 — Özet tab, light mode (EN)
  // Seed: 1 income (€1000) + 1 expense (€50)
  // =========================================================================

  testWidgets(
      'F4: Özet tab — NET THIS MONTH hero, income/expense footers, '
      'TOP CATEGORIES + WEEK TREND sections visible (EN light)',
      (tester) async {
    final db = _testDb();
    final accountId = await _seedAccount(db);
    final incomeCatId = await _incomeCategory(db);
    final expenseCatId = await _expenseCategory(db);
    await _seedIncome(db, accountId: accountId, categoryId: incomeCatId);
    await _seedExpense(db, accountId: accountId, categoryId: expenseCatId);

    await tester.pumpWidget(_buildTransactionsView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Switch to tab index 2 (Özet / Summary)
    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('NET THIS MONTH'), findsOneWidget);
    expect(find.textContaining('income'), findsWidgets);
    expect(find.textContaining('expense'), findsWidgets);
    expect(find.text('TOP CATEGORIES'), findsOneWidget);
    expect(find.text('WEEK TREND'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'f4_summary_light_en');
    await _teardown(tester, db);
  });

  // =========================================================================
  // F5 — Dark mode, Liste tab (EN)
  // Seed: 1 expense (€30)
  // =========================================================================

  testWidgets(
      'F5: Dark mode — Liste tab renders without exception, '
      'transaction visible (EN dark)', (tester) async {
    final db = _testDb();
    final accountId = await _seedAccount(db);
    final expenseCatId = await _expenseCategory(db);
    await _seedExpense(db,
        accountId: accountId, categoryId: expenseCatId, amount: 30.0);

    await tester.pumpWidget(_buildTransactionsView(db, darkMode: true));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Tab bar visible (transactions exist)
    expect(find.text('List'), findsOneWidget);

    // Summary strip rendered
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'f5_liste_dark_en');
    await _teardown(tester, db);
  });

  // =========================================================================
  // F6 — Dark mode, Özet tab (EN)
  // Seed: 1 income (€500) + 1 expense (€200)
  // =========================================================================

  testWidgets(
      'F6: Dark mode — Özet tab renders without exception, '
      'NET THIS MONTH visible (EN dark)', (tester) async {
    final db = _testDb();
    final accountId = await _seedAccount(db);
    final incomeCatId = await _incomeCategory(db);
    final expenseCatId = await _expenseCategory(db);
    await _seedIncome(db,
        accountId: accountId, categoryId: incomeCatId, amount: 500.0);
    await _seedExpense(db,
        accountId: accountId, categoryId: expenseCatId, amount: 200.0);

    await tester.pumpWidget(_buildTransactionsView(db, darkMode: true));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Switch to Özet tab
    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('NET THIS MONTH'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'f6_summary_dark_en');
    await _teardown(tester, db);
  });

  // =========================================================================
  // F7 — Turkish locale, Liste tab
  // Seed: 1 expense (€25)
  // =========================================================================

  testWidgets(
      'F7: Turkish locale — tab labels Liste/Takvim/Özet, '
      'strip labels Gelir/Gider visible', (tester) async {
    final db = _testDb();
    final accountId = await _seedAccount(db);
    final expenseCatId = await _expenseCategory(db);
    await _seedExpense(db,
        accountId: accountId, categoryId: expenseCatId, amount: 25.0);

    await tester.pumpWidget(
      _buildTransactionsView(db, locale: const Locale('tr')),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // TR tab labels
    expect(find.text('Liste'), findsOneWidget);
    expect(find.text('Takvim'), findsOneWidget);
    expect(find.text('Özet'), findsOneWidget);

    // TR summary strip labels
    expect(find.text('Gelir'), findsOneWidget);
    expect(find.text('Gider'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'f7_liste_light_tr');
    await _teardown(tester, db);
  });

  // =========================================================================
  // F8 — Turkish locale, empty state
  // No transactions
  // =========================================================================

  testWidgets(
      'F8: Turkish locale empty state — "Henüz işlem yok" + "İlk işlemi ekle" '
      'visible, tab bar NOT shown', (tester) async {
    final db = _testDb();

    await tester.pumpWidget(
      _buildTransactionsView(db, locale: const Locale('tr')),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Henüz işlem yok'), findsOneWidget);
    expect(find.text('İlk işlemi ekle'), findsOneWidget);

    // Tab bar must NOT be visible in empty state
    expect(find.text('Liste'), findsNothing);
    expect(find.text('Takvim'), findsNothing);
    expect(find.text('Özet'), findsNothing);

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'f8_empty_light_tr');
    await _teardown(tester, db);
  });

  // =========================================================================
  // F9 — Turkish locale, Takvim tab
  // Seed: 1 expense (€40)
  // =========================================================================

  testWidgets(
      'F9: Turkish locale Takvim tab — weekday headers Pt/Ça/Pe visible',
      (tester) async {
    final db = _testDb();
    final accountId = await _seedAccount(db);
    final expenseCatId = await _expenseCategory(db);
    await _seedExpense(db,
        accountId: accountId, categoryId: expenseCatId, amount: 40.0);

    await tester.pumpWidget(
      _buildTransactionsView(db, locale: const Locale('tr')),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Switch to Takvim tab
    await tester.tap(find.text('Takvim'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // TR weekday abbreviations
    expect(find.text('Pt'), findsOneWidget); // Pazartesi (Mon)
    expect(find.text('Ça'), findsOneWidget); // Çarşamba (Wed)
    expect(find.text('Pe'), findsOneWidget); // Perşembe (Thu)

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'f9_calendar_light_tr');
    await _teardown(tester, db);
  });

  // =========================================================================
  // F10 — Turkish locale, Özet tab
  // Seed: 1 income (€800) + 1 expense (€100)
  // =========================================================================

  testWidgets(
      'F10: Turkish locale Özet tab — "NET BU AY", '
      '"ÜST KATEGORİLER", "HAFTA TRENDİ" visible', (tester) async {
    final db = _testDb();
    final accountId = await _seedAccount(db);
    final incomeCatId = await _incomeCategory(db);
    final expenseCatId = await _expenseCategory(db);
    await _seedIncome(db,
        accountId: accountId, categoryId: incomeCatId, amount: 800.0);
    await _seedExpense(db,
        accountId: accountId, categoryId: expenseCatId, amount: 100.0);

    await tester.pumpWidget(
      _buildTransactionsView(db, locale: const Locale('tr')),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Switch to Özet tab
    await tester.tap(find.text('Özet'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('NET BU AY'), findsOneWidget);
    expect(find.text('ÜST KATEGORİLER'), findsOneWidget);
    expect(find.text('HAFTA TRENDİ'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'f10_summary_light_tr');
    await _teardown(tester, db);
  });

  // =========================================================================
  // E1 — Income-only month, Özet tab
  // Seed: 2 income (€500 + €300), no expenses
  // =========================================================================

  testWidgets(
      'E1: Income-only month Özet tab — NET THIS MONTH visible, '
      'no exception on zero-expense state', (tester) async {
    final db = _testDb();
    final accountId = await _seedAccount(db);
    final incomeCatId = await _incomeCategory(db);
    await _seedIncome(db,
        accountId: accountId, categoryId: incomeCatId, amount: 500.0);
    await _seedIncome(db,
        accountId: accountId, categoryId: incomeCatId, amount: 300.0);

    await tester.pumpWidget(_buildTransactionsView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Switch to Summary tab
    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('NET THIS MONTH'), findsOneWidget);

    // Strip: Expense shows zero (€0.00 or equivalent)
    expect(find.text('Expense'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'e1_income_only_summary');
    await _teardown(tester, db);
  });

  // =========================================================================
  // E2 — Large amount formatting
  // Seed: 1 expense (€99999.99)
  // =========================================================================

  testWidgets(
      'E2: Large amount (€99999.99) — renders without overflow crash, '
      'amount text containing "99" visible', (tester) async {
    final db = _testDb();
    final accountId = await _seedAccount(db);
    final expenseCatId = await _expenseCategory(db);
    await _seedExpense(db,
        accountId: accountId, categoryId: expenseCatId, amount: 99999.99);

    await tester.pumpWidget(_buildTransactionsView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Amount text rendered somewhere — "99" appears in all locale formats
    expect(find.textContaining('99'), findsWidgets);

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'e2_large_amount');
    await _teardown(tester, db);
  });

  // =========================================================================
  // E3 — Özet tab, dark mode TR
  // Seed: 1 income (€200) + 1 expense (€80)
  // =========================================================================

  testWidgets(
      'E3: Dark mode TR Özet tab — "NET BU AY" + "ÜST KATEGORİLER" visible, '
      'no exception', (tester) async {
    final db = _testDb();
    final accountId = await _seedAccount(db);
    final incomeCatId = await _incomeCategory(db);
    final expenseCatId = await _expenseCategory(db);
    await _seedIncome(db,
        accountId: accountId, categoryId: incomeCatId, amount: 200.0);
    await _seedExpense(db,
        accountId: accountId, categoryId: expenseCatId, amount: 80.0);

    await tester.pumpWidget(
      _buildTransactionsView(db, darkMode: true, locale: const Locale('tr')),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Switch to Özet tab
    await tester.tap(find.text('Özet'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('NET BU AY'), findsOneWidget);
    expect(find.text('ÜST KATEGORİLER'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await _screenshot(binding, 'e3_summary_dark_tr');
    await _teardown(tester, db);
  });
}
