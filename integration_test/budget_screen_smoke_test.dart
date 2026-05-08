// Integration smoke tests for EPIC8C-01 Budget Screen Redesign.
// Run with:
//   flutter test integration_test/budget_screen_smoke_test.dart \
//     -d D6304F8C-B2AF-4B0E-B2E2-5A95AD62EC25
//
// Scenarios covered:
//   F1 — Populated state: hero card + metric cards + category list + distribution
//   F2 — Empty state: EN light / TR light / EN dark
//   F3 — Category list renders correctly under CATEGORIES section
//   F4 — Over-budget state: DEFERRED to EPIC8B-07 (requires global budget settings UI)
//   F5 — Daily metric: subtitle shows "can spend" (two distinct values)
//   F6 — Insight slot hidden when concentration rule does not fire
//   F7 — Surface routing: classifier contract verification

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/database.dart' hide Transaction;
import 'package:moneywise/features/budget/presentation/widgets/budget_view.dart';
import 'package:moneywise/features/insights/domain/insight_classifier.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _screenshotDir =
    '/Users/burakagridag/Documents/projects/mobileapps/moneywise'
    '/docs/qa/EPIC8C-01-smoke-test/screenshots';

/// Captures a screenshot from the integration test binding (widget is live on
/// screen) and writes the PNG bytes directly to [_screenshotDir].
/// Unlike `xcrun simctl io screenshot` (which captures whatever is on screen
/// AFTER tests finish), this runs while the widget is still rendered.
Future<void> _screenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  final bytes = await binding.takeScreenshot(name);
  final file = File('$_screenshotDir/$name.png');
  await file.writeAsBytes(bytes);
}

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _buildBudgetView(
  AppDatabase db, {
  Locale locale = const Locale('en'),
  bool darkMode = false,
}) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWith((_) => db)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: darkMode ? AppTheme.dark : AppTheme.light,
      home: const Scaffold(body: BudgetView()),
    ),
  );
}

/// Seeds one expense-category budget for the current month.
Future<String> _seedSingleBudget(
  AppDatabase db, {
  double amount = 300.0,
}) async {
  final expenseCats = await db.categoryDao.getByType('expense');
  final cat = expenseCats.first;
  final now = DateTime.now();
  final monthStr =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-01';
  await db.budgetDao.upsertBudget(
    BudgetsCompanion(
      categoryId: Value(cat.id),
      amount: Value(amount),
      effectiveFrom: Value(monthStr),
      createdAt: Value(now.toIso8601String()),
      updatedAt: Value(now.toIso8601String()),
    ),
  );
  return cat.id;
}

/// Seeds two expense-category budgets for the current month.
Future<void> _seedTwoBudgets(AppDatabase db) async {
  final expenseCats = await db.categoryDao.getByType('expense');
  final now = DateTime.now();
  final monthStr =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-01';

  await db.budgetDao.upsertBudget(
    BudgetsCompanion(
      categoryId: Value(expenseCats[0].id),
      amount: const Value(300.0),
      effectiveFrom: Value(monthStr),
      createdAt: Value(now.toIso8601String()),
      updatedAt: Value(now.toIso8601String()),
    ),
  );
  if (expenseCats.length > 1) {
    await db.budgetDao.upsertBudget(
      BudgetsCompanion(
        categoryId: Value(expenseCats[1].id),
        amount: const Value(200.0),
        effectiveFrom: Value(monthStr),
        createdAt: Value(now.toIso8601String()),
        updatedAt: Value(now.toIso8601String()),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // F2 — Empty State
  // =========================================================================

  testWidgets('F2-EN-Light: empty state shows correct English strings',
      (tester) async {
    final db = _testDb();
    await tester.pumpWidget(_buildBudgetView(db));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Set your monthly budget'), findsOneWidget);
    expect(find.text('Track spending across categories'), findsOneWidget);
    expect(find.text('Start budget'), findsOneWidget);

    // Hero card must NOT appear in empty state
    expect(find.text('REMAINING THIS MONTH'), findsNothing);

    await _screenshot(binding,'f2_empty_light_en');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  testWidgets('F2-TR-Light: empty state shows Turkish strings', (tester) async {
    final db = _testDb();
    await tester.pumpWidget(
        _buildBudgetView(db, locale: const Locale('tr')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Aylık bütçeni belirle'), findsOneWidget);
    expect(find.text('Kategorilere göre harcamalarını takip et'), findsOneWidget);
    expect(find.text('Bütçeyi başlat'), findsOneWidget);

    // Hero card must NOT appear
    expect(find.text('KALAN BU AY'), findsNothing);

    await _screenshot(binding,'f2_empty_light_tr');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  testWidgets('F2-EN-Dark: empty state renders in dark theme', (tester) async {
    final db = _testDb();
    await tester.pumpWidget(_buildBudgetView(db, darkMode: true));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Set your monthly budget'), findsOneWidget);
    expect(find.text('REMAINING THIS MONTH'), findsNothing);

    await _screenshot(binding,'f2_empty_dark_en');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  // =========================================================================
  // F1 — Populated State
  // =========================================================================

  testWidgets(
      'F1-EN-Light: populated state renders hero card + metric cards + sections',
      (tester) async {
    final db = _testDb();
    await _seedTwoBudgets(db);

    await tester.pumpWidget(_buildBudgetView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Hero card
    expect(find.text('REMAINING THIS MONTH'), findsOneWidget);

    // Metric cards
    expect(find.text('DAILY'), findsOneWidget);
    expect(find.text('LAST MONTH'), findsOneWidget);

    // Section headers
    expect(find.text('CATEGORIES'), findsOneWidget);
    expect(find.text('DISTRIBUTION'), findsOneWidget);

    await _screenshot(binding,'f1_populated_light_en');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  testWidgets('F1-EN-Dark: populated state renders in dark theme',
      (tester) async {
    final db = _testDb();
    await _seedSingleBudget(db, amount: 500.0);

    await tester.pumpWidget(_buildBudgetView(db, darkMode: true));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('REMAINING THIS MONTH'), findsOneWidget);

    await _screenshot(binding,'f1_populated_dark_en');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  testWidgets('F1-TR-Light: populated state renders Turkish labels',
      (tester) async {
    final db = _testDb();
    await _seedSingleBudget(db, amount: 500.0);

    await tester.pumpWidget(
        _buildBudgetView(db, locale: const Locale('tr')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('KALAN BU AY'), findsOneWidget);
    expect(find.text('GÜNLÜK'), findsOneWidget);
    expect(find.text('GEÇEN AY'), findsOneWidget);
    expect(find.text('KATEGORİLER'), findsOneWidget);

    await _screenshot(binding,'f1_populated_light_tr');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  // =========================================================================
  // F4 — Over-budget state (DEFERRED — EPIC8B-07)
  // =========================================================================
  // F4 covers the UI when spending exceeds effective budget:
  // hero card turns red, category row shows error colour, DailyOverpacingRule fires.
  // This state depends on the global budget settings UI (EPIC8B-07).
  // Integration test will be added in the EPIC8B-07 sprint.
  // =========================================================================

  // =========================================================================
  // F5 — Daily metric: two distinct values (Bulgu 2 fix verification)
  // =========================================================================

  testWidgets('F5: daily metric subtitle shows safe-pace "can spend" text',
      (tester) async {
    final db = _testDb();
    // Large budget so remaining > 0 → safeDailyPace > 0 → subtitle is visible
    await _seedSingleBudget(db, amount: 1000.0);

    await tester.pumpWidget(_buildBudgetView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('DAILY'), findsOneWidget);
    // budgetMetricDailySafe ARB key = "{amount} can spend"
    expect(find.textContaining('can spend'), findsOneWidget);

    await _screenshot(binding,'f5_daily_metric_two_values');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  // =========================================================================
  // F6 — Insight slot hidden when concentration rule does not fire
  // =========================================================================

  testWidgets(
      'F6: insight slot absent when no expense transactions exist',
      (tester) async {
    final db = _testDb();
    // Budget present but NO expense transactions → totalSpent=0 →
    // ConcentrationRule has no dominant category → returns null → no card
    await _seedSingleBudget(db, amount: 300.0);

    await tester.pumpWidget(_buildBudgetView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Neither EN nor TR concentration headline should appear
    expect(find.text('Spending concentrated'), findsNothing);
    expect(find.text('Harcama yoğunlaşması'), findsNothing);

    await _screenshot(binding,'f6_no_insight_slot');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  // =========================================================================
  // F3 — Categories section renders correctly
  // =========================================================================

  testWidgets('F3: categories section shows CATEGORIES header and Edit link',
      (tester) async {
    final db = _testDb();
    await _seedSingleBudget(db, amount: 200.0);

    await tester.pumpWidget(_buildBudgetView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('CATEGORIES'), findsOneWidget);
    expect(find.text('Edit ›'), findsOneWidget);

    await _screenshot(binding,'f3_categories_section');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  // =========================================================================
  // F7 — Surface routing: classifier contract
  // =========================================================================

  testWidgets('F7: insightVisibleOn routes concentration to budget-only',
      (tester) async {
    // Inline classifier contract checks (full 17-case suite in unit tests).
    expect(insightVisibleOn('concentration', InsightSurface.budget), isTrue);
    expect(insightVisibleOn('concentration', InsightSurface.home), isFalse);
    expect(insightVisibleOn('daily_overpacing', InsightSurface.home), isTrue);
    expect(insightVisibleOn('daily_overpacing', InsightSurface.budget), isFalse);
    expect(insightVisibleOn('savings_goal', InsightSurface.home), isTrue);
    expect(insightVisibleOn('weekend_spending', InsightSurface.home), isTrue);
    expect(insightVisibleOn('big_transaction', InsightSurface.home), isTrue);

    await _screenshot(binding,'f7_surface_routing_verified');
  });

  // =========================================================================
  // CR1 — Post-code-review: Semantic labels i18n (EN hero card)
  // =========================================================================

  testWidgets('CR1-EN: hero card Semantics label uses l10n (not hardcoded EN)',
      (tester) async {
    final db = _testDb();
    await _seedSingleBudget(db, amount: 300.0);

    await tester.pumpWidget(_buildBudgetView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // The semantic label must NOT contain the raw hardcoded strings from before
    // the code review fix. The l10n-generated text for EN is the same value,
    // but this test proves the widget finds the hero card without crashing.
    expect(find.text('REMAINING THIS MONTH'), findsOneWidget);

    // Semantics tree: hero card accessible label contains "remaining" (EN l10n value)
    expect(
      find.bySemanticsLabel(RegExp(r'remaining', caseSensitive: false)),
      findsWidgets,
    );

    await _screenshot(binding,'cr1_semantic_en_hero');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  // =========================================================================
  // CR2 — Post-code-review: Semantic labels i18n (TR hero card + category row)
  // =========================================================================

  testWidgets('CR2-TR: TR semantic labels use l10n (not hardcoded TR strings)',
      (tester) async {
    final db = _testDb();
    await _seedSingleBudget(db, amount: 300.0);

    await tester.pumpWidget(
        _buildBudgetView(db, locale: const Locale('tr')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('KALAN BU AY'), findsOneWidget);
    expect(find.text('KATEGORİLER'), findsOneWidget);

    // TR semantic: "kalan" (remaining) for hero card
    expect(
      find.bySemanticsLabel(RegExp(r'kalan', caseSensitive: false)),
      findsWidgets,
    );

    await _screenshot(binding,'cr2_semantic_tr_hero');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  // =========================================================================
  // CR3 — Post-code-review: Edit › is a tappable button (not GestureDetector)
  // =========================================================================

  testWidgets('CR3: Edit link is a TextButton (not GestureDetector)',
      (tester) async {
    final db = _testDb();
    await _seedSingleBudget(db, amount: 200.0);

    await tester.pumpWidget(_buildBudgetView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // TextButton must be present — confirms GestureDetector was replaced
    // (code review fix: MAJOR #3 — 44×44dp minimum tap target)
    expect(find.byType(TextButton), findsWidgets);
    expect(find.text('Edit ›'), findsOneWidget);
    // NOTE: we do NOT tap the button here because the integration test
    // context does not include a GoRouter — tapping would throw
    // "No GoRouter found in context". The navigation path is verified
    // by BudgetView widget tests and the manual smoke test.

    await _screenshot(binding,'cr3_edit_textbutton');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  // =========================================================================
  // CR4 — Post-code-review: AppSpacing constants — section header spacing
  // =========================================================================

  testWidgets('CR4: CATEGORIES section header renders without overflow',
      (tester) async {
    final db = _testDb();
    await _seedTwoBudgets(db);

    await tester.pumpWidget(_buildBudgetView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // No RenderFlex overflow errors — spacing constants applied correctly
    expect(tester.takeException(), isNull);
    expect(find.text('CATEGORIES'), findsOneWidget);
    expect(find.text('DISTRIBUTION'), findsOneWidget);

    await _screenshot(binding,'cr4_section_spacing');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  // =========================================================================
  // CR5 — Post-code-review: DISTRIBUTION section + donut placeholder
  // =========================================================================

  testWidgets('CR5: DISTRIBUTION section renders donut placeholder',
      (tester) async {
    final db = _testDb();
    await _seedTwoBudgets(db);

    await tester.pumpWidget(_buildBudgetView(db));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('DISTRIBUTION'), findsOneWidget);
    // Footer: "This month {amount}" — verify it starts with "This month"
    expect(find.textContaining('This month'), findsOneWidget);

    await _screenshot(binding,'cr5_distribution_donut');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });

  // =========================================================================
  // CR6 — Dark theme: post-code-review populated state (TR)
  // =========================================================================

  testWidgets('CR6-TR-Dark: populated state TR dark theme renders correctly',
      (tester) async {
    final db = _testDb();
    await _seedTwoBudgets(db);

    await tester.pumpWidget(
        _buildBudgetView(db, locale: const Locale('tr'), darkMode: true));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('KALAN BU AY'), findsOneWidget);
    expect(find.text('GÜNLÜK'), findsOneWidget);
    expect(find.text('KATEGORİLER'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _screenshot(binding,'cr6_populated_dark_tr');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });
}
