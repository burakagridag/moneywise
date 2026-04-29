// Widget tests for MonthNavigator — features/transactions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/transactions/presentation/widgets/month_navigator.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildNav({bool showYearOnly = false}) {
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MonthNavigator — month mode', () {
    testWidgets('should_call_onPrevious_when_back_arrow_tapped',
        (tester) async {
      await tester.pumpWidget(_buildNav());
      await tester.pump();

      // Read the initial month label (e.g. "April 2026").
      final now = DateTime.now();
      final expectedPrev = DateTime(
        now.month == 1 ? now.year - 1 : now.year,
        now.month == 1 ? 12 : now.month - 1,
      );
      final prevLabel = DateFormat.yMMMM().format(expectedPrev);

      // Tap the left chevron.
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      // The navigator label should now show the previous month.
      expect(find.text(prevLabel), findsOneWidget,
          reason: 'Tapping previous should navigate to the prior month');
    });

    testWidgets('should_call_onNext_when_forward_arrow_tapped', (tester) async {
      await tester.pumpWidget(_buildNav());
      await tester.pump();

      final now = DateTime.now();
      final expectedNext = DateTime(
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
      );
      final nextLabel = DateFormat.yMMMM().format(expectedNext);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text(nextLabel), findsOneWidget,
          reason: 'Tapping next should navigate to the following month');
    });

    testWidgets('should_display_month_and_year_in_title', (tester) async {
      await tester.pumpWidget(_buildNav());
      await tester.pump();

      final now = DateTime.now();
      final label = DateFormat.yMMMM().format(now);

      expect(find.text(label), findsOneWidget,
          reason: 'Navigator should display current month and year');
    });
  });

  group('MonthNavigator — year-only mode', () {
    testWidgets('should_display_year_only_when_showYearOnly_is_true',
        (tester) async {
      await tester.pumpWidget(_buildNav(showYearOnly: true));
      await tester.pump();

      final year = DateTime.now().year.toString();
      expect(find.text(year), findsOneWidget,
          reason: 'In year-only mode the label must be a 4-digit year string');
    });

    testWidgets('navigates to previous year when back arrow tapped',
        (tester) async {
      await tester.pumpWidget(_buildNav(showYearOnly: true));
      await tester.pump();

      final prevYear = (DateTime.now().year - 1).toString();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      expect(find.text(prevYear), findsOneWidget);
    });

    testWidgets('navigates to next year when forward arrow tapped',
        (tester) async {
      await tester.pumpWidget(_buildNav(showYearOnly: true));
      await tester.pump();

      final nextYear = (DateTime.now().year + 1).toString();

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text(nextYear), findsOneWidget);
    });
  });
}
