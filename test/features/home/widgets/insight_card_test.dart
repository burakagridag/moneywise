// Widget tests for InsightCard — home feature (EPIC8A-08).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/constants/app_colors.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/home/presentation/widgets/insight_card.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildCard({
  ThemeData? theme,
  required String title,
  required String subtitle,
  VoidCallback? onTap,
  IconData icon = Icons.info,
  Color iconColor = AppColors.brandPrimary,
  Color iconBackgroundColor = AppColors.brandSurface,
}) =>
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: InsightCard(
            icon: icon,
            iconColor: iconColor,
            iconBackgroundColor: iconBackgroundColor,
            title: title,
            subtitle: subtitle,
            onTap: onTap,
          ),
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('InsightCard', () {
    // -----------------------------------------------------------------------
    // Rendering
    // -----------------------------------------------------------------------

    testWidgets('renders title and subtitle texts', (tester) async {
      await tester.pumpWidget(
        _buildCard(
            title: 'Spend less on food', subtitle: '62% of monthly budget'),
      );

      expect(find.text('Spend less on food'), findsOneWidget);
      expect(find.text('62% of monthly budget'), findsOneWidget);
    });

    testWidgets('renders icon inside a 36x36 container', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          title: 'Title',
          subtitle: 'Subtitle',
          icon: Icons.trending_up,
        ),
      );

      // Icon is rendered inside the card.
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          theme: AppTheme.dark,
          title: 'Dark theme title',
          subtitle: 'Dark subtitle',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Dark theme title'), findsOneWidget);
    });

    testWidgets('does not overflow on narrow screen', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 600 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _buildCard(
          title: 'A very very very very very long title that might overflow',
          subtitle:
              'A very very very very very long subtitle that might overflow',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    // -----------------------------------------------------------------------
    // Tappable variant (onTap provided)
    // -----------------------------------------------------------------------

    testWidgets('with onTap — card is wrapped in InkWell', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildCard(
          title: 'Tappable',
          subtitle: 'Sub',
          onTap: () => tapped = true,
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('with onTap — InkWell has matching border radius',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(
          title: 'Tappable',
          subtitle: 'Sub',
          onTap: () {},
        ),
      );

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(
        inkWell.borderRadius,
        equals(BorderRadius.circular(14)), // AppRadius.lg
      );
    });

    testWidgets('with onTap — Semantics has button: true', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          title: 'Tappable title',
          subtitle: 'Tappable sub',
          onTap: () {},
        ),
      );

      // Verify tappable card has isButton flag in its semantic node.
      final semNode = tester.getSemantics(find.byType(InsightCard));
      expect(semNode.label, contains('Tap for details'));
    });

    testWidgets('with onTap — semantic label includes "Tap for details"',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(
          title: 'Food spending',
          subtitle: '62% of budget',
          onTap: () {},
        ),
      );

      final semantics = tester.getSemantics(find.byType(InsightCard));
      expect(
        semantics.label,
        contains('Tap for details'),
      );
    });

    // -----------------------------------------------------------------------
    // Non-tappable variant (onTap = null)
    // -----------------------------------------------------------------------

    testWidgets('without onTap — no InkWell is rendered', (tester) async {
      await tester.pumpWidget(
        _buildCard(title: 'Non-tappable', subtitle: 'Sub'),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('without onTap — Semantics does not have button flag',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(title: 'Static title', subtitle: 'Static sub'),
      );

      // Verify non-tappable card does NOT contain 'Tap for details' in label.
      final semNode = tester.getSemantics(find.byType(InsightCard));
      expect(semNode.label, isNot(contains('Tap for details')));
    });

    testWidgets(
        'without onTap — semantic label does NOT contain "Tap for details"',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(title: 'Info card', subtitle: 'Sub'),
      );

      final semantics = tester.getSemantics(find.byType(InsightCard));
      expect(semantics.label, isNot(contains('Tap for details')));
    });

    testWidgets('without onTap — card is not tappable (no exception)',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(title: 'Static', subtitle: 'Sub'),
      );

      // Attempting to tap the card should not throw.
      await tester.tap(find.byType(InsightCard), warnIfMissed: false);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    // -----------------------------------------------------------------------
    // Title / subtitle ellipsis
    // -----------------------------------------------------------------------

    testWidgets('title Text widget uses fontSize: 14', (tester) async {
      await tester.pumpWidget(
        _buildCard(title: 'Spend less on food', subtitle: '62% of budget'),
      );

      // The first Text widget in the card is the title.
      final titleWidget = tester.widgetList<Text>(find.byType(Text)).first;
      expect(
        titleWidget.style?.fontSize,
        equals(14.0),
        reason: 'InsightCard title must use fontSize 14 per redlines.md',
      );
    });

    testWidgets('title text has maxLines: 1 and ellipsis overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(
          title: 'Long title that should be clipped by ellipsis overflow',
          subtitle: 'Sub',
        ),
      );

      final titleWidget = tester.widgetList<Text>(find.byType(Text)).first;
      expect(titleWidget.maxLines, equals(1));
      expect(titleWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('subtitle text has maxLines: 1 and ellipsis overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(
          title: 'Title',
          subtitle: 'Long subtitle that should be clipped by ellipsis overflow',
        ),
      );

      final subtitleWidget = tester.widgetList<Text>(find.byType(Text)).last;
      expect(subtitleWidget.maxLines, equals(1));
      expect(subtitleWidget.overflow, equals(TextOverflow.ellipsis));
    });
  });
}
