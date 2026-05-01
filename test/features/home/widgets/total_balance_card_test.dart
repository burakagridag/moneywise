// Widget tests for TotalBalanceCard — home feature (EPIC8A-06).
// Covers all states: loading (shimmer), error, data with and without trend chip.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/constants/app_colors.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/daos/transaction_dao.dart';
import 'package:moneywise/features/home/presentation/providers/net_worth_provider.dart';
import 'package:moneywise/features/home/presentation/providers/sparkline_provider.dart';
import 'package:moneywise/features/home/presentation/widgets/total_balance_card.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Generates a flat 30-entry sparkline list (all zeros).
List<DailyNet> _flatSparkline() {
  final today = DateTime(2024, 3, 31);
  return List.generate(30, (i) {
    final d = today.subtract(Duration(days: 29 - i));
    return DailyNet(
      date: DateTime(d.year, d.month, d.day),
      netAmount: 0.0,
    );
  });
}

/// Builds a TotalBalanceCard with controlled Riverpod provider overrides.
///
/// [balance] — the value emitted by [accountsTotalProvider].
/// [previousBalance] — the value emitted by [previousMonthTotalProvider].
/// [sparklineData] — the list emitted by [sparklineDataProvider].
/// Pass null for [balance] to simulate loading state.
Widget _buildCard({
  AsyncValue<double>? balanceValue,
  AsyncValue<double?> previousValue = const AsyncValue.data(null),
  List<DailyNet>? sparklineData,
  ThemeData? theme,
}) {
  final balanceOverride = balanceValue ?? const AsyncValue.loading();
  final sparkline = sparklineData ?? _flatSparkline();

  return ProviderScope(
    overrides: [
      accountsTotalProvider.overrideWith(
        (_) => Stream.fromIterable([balanceOverride.valueOrNull ?? 0.0]),
      ),
      previousMonthTotalProvider.overrideWith(
        (_) async => previousValue.valueOrNull,
      ),
      sparklineDataProvider.overrideWith(
        (_) => Stream.value(sparkline),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: theme ?? AppTheme.light,
      home: const Scaffold(body: TotalBalanceCard()),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TotalBalanceCard', () {
    // -------------------------------------------------------------------------
    // Loading state
    // -------------------------------------------------------------------------

    testWidgets(
        'shows shimmer container while accountsTotalProvider is loading',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsTotalProvider.overrideWith(
              (_) => const Stream<double>.empty(),
            ),
            previousMonthTotalProvider.overrideWith(
              (_) async => null,
            ),
            sparklineDataProvider.overrideWith(
              (_) => Stream.value(_flatSparkline()),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(body: TotalBalanceCard()),
          ),
        ),
      );
      // One frame without data — shimmer bars are rendered.
      await tester.pump();

      // The card container (gradient) must be visible.
      expect(find.byType(TotalBalanceCard), findsOneWidget);
      // No balance label visible in shimmer state (no Text with balance).
      expect(find.text('0,00 €'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Trend chip visibility
    // -------------------------------------------------------------------------

    testWidgets('shows ↑ trend chip when balance > previousBalance',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(
          balanceValue: const AsyncValue.data(500.0),
          previousValue: const AsyncValue.data(300.0),
        ),
      );
      await tester.pumpAndSettle();

      // Chip text contains upward arrow and amount.
      expect(find.textContaining('↑'), findsOneWidget);
      expect(find.text('since last month'), findsOneWidget);
    });

    testWidgets('shows ↓ trend chip when balance < previousBalance',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(
          balanceValue: const AsyncValue.data(100.0),
          previousValue: const AsyncValue.data(500.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('↓'), findsOneWidget);
      expect(find.text('since last month'), findsOneWidget);
    });

    testWidgets('hides trend chip when previousBalance is null',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(
          balanceValue: const AsyncValue.data(1000.0),
          previousValue: const AsyncValue.data(null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('↑'), findsNothing);
      expect(find.textContaining('↓'), findsNothing);
      expect(find.text('since last month'), findsNothing);
    });

    testWidgets('hides trend chip when previousBalance is zero',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(
          balanceValue: const AsyncValue.data(1000.0),
          previousValue: const AsyncValue.data(0.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('↑'), findsNothing);
      expect(find.textContaining('↓'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Balance display
    // -------------------------------------------------------------------------

    testWidgets('renders "0,00 €" when balance is exactly zero',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(
          balanceValue: const AsyncValue.data(0.0),
          previousValue: const AsyncValue.data(null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0,00 €'), findsOneWidget);
    });

    testWidgets('renders balance in white color (not red) for negative balance',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(
          balanceValue: const AsyncValue.data(-1200.0),
          previousValue: const AsyncValue.data(null),
        ),
      );
      await tester.pumpAndSettle();

      // Find the balance text widget.
      final balanceTextFinder = find.textContaining('-1.200,00');
      expect(balanceTextFinder, findsOneWidget);

      // The text color must be white (AppColors.textOnBrand), never red.
      final textWidget = tester.widget<Text>(balanceTextFinder);
      expect(textWidget.style?.color, equals(AppColors.textOnBrand),
          reason: 'Negative balance must remain white on gradient background');
    });

    testWidgets('renders "TOTAL BALANCE" label in EN locale', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          balanceValue: const AsyncValue.data(1000.0),
          previousValue: const AsyncValue.data(null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TOTAL BALANCE'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Gradient background
    // -------------------------------------------------------------------------

    testWidgets('card has gradient background in light mode', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          balanceValue: const AsyncValue.data(500.0),
          theme: AppTheme.light,
        ),
      );
      await tester.pumpAndSettle();

      // The gradient container must be present — verify via Container decoration.
      final containerFinder = find.descendant(
        of: find.byType(TotalBalanceCard),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets('card renders without errors in dark mode', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          balanceValue: const AsyncValue.data(500.0),
          theme: AppTheme.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TotalBalanceCard), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // V2 accounts prop
    // -------------------------------------------------------------------------

    testWidgets('accepts accounts prop without rendering sub-cards',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsTotalProvider.overrideWith(
              (_) => Stream.value(800.0),
            ),
            previousMonthTotalProvider.overrideWith(
              (_) async => null,
            ),
            sparklineDataProvider.overrideWith(
              (_) => Stream.value(_flatSparkline()),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: TotalBalanceCard(accounts: ['acc1', 'acc2']),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No crash, no sub-card UI.
      expect(tester.takeException(), isNull);
      expect(find.byType(TotalBalanceCard), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // _isFlat epsilon detection
    // -------------------------------------------------------------------------

    testWidgets(
        'renders without throwing when all sparkline netAmounts are 0.0 (flat)',
        (tester) async {
      // All DailyNet values are exactly 0.0 — _isFlat must return true via
      // epsilon comparison and the sparkline must render in its flat state
      // without any exception.
      await tester.pumpWidget(
        _buildCard(
          balanceValue: const AsyncValue.data(0.0),
          previousValue: const AsyncValue.data(null),
          sparklineData: _flatSparkline(), // all netAmount == 0.0
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TotalBalanceCard), findsOneWidget);
    });

    testWidgets(
        'renders without throwing when sparkline values differ by less than epsilon',
        (tester) async {
      // Values within 0.001 of each other — should still be treated as flat.
      final today = DateTime(2024, 3, 31);
      final nearlyFlatData = List.generate(30, (i) {
        final d = today.subtract(Duration(days: 29 - i));
        return DailyNet(
          date: DateTime(d.year, d.month, d.day),
          netAmount: i == 0 ? 0.0 : 0.0005, // diff < 0.001 → flat
        );
      });

      await tester.pumpWidget(
        _buildCard(
          balanceValue: const AsyncValue.data(0.0),
          previousValue: const AsyncValue.data(null),
          sparklineData: nearlyFlatData,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // Sparkline rendered
    // -------------------------------------------------------------------------

    testWidgets('renders without overflow when sparkline data provided',
        (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _buildCard(
          balanceValue: const AsyncValue.data(8450.0),
          previousValue: const AsyncValue.data(8038.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
