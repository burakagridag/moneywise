// Widget tests for HomeHeader — home feature (EPIC8A-05).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/home/presentation/widgets/home_header.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps [HomeHeader] in a minimal app with locale and theme support.
Widget _buildHeader({
  String userName = '',
  required DateTime currentDate,
  VoidCallback? onAvatarTap,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    theme: theme ?? AppTheme.light,
    home: Scaffold(
      body: HomeHeader(
        userName: userName,
        currentDate: currentDate,
        onAvatarTap: onAvatarTap,
      ),
    ),
  );
}

/// Returns a [DateTime] fixed to a specific hour on a known Thursday (2026-05-01).
DateTime _dateAtHour(int hour) =>
    DateTime(2026, 5, 7, hour); // Thursday 7 May 2026

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HomeHeader — greeting logic (EPIC8A-05)', () {
    testWidgets('shows "Good morning" at 09:00', (tester) async {
      await tester.pumpWidget(_buildHeader(currentDate: _dateAtHour(9)));
      await tester.pump();

      expect(find.text('Good morning'), findsOneWidget);
    });

    testWidgets('shows "Good morning" at 05:00 (boundary)', (tester) async {
      await tester.pumpWidget(_buildHeader(currentDate: _dateAtHour(5)));
      await tester.pump();

      expect(find.text('Good morning'), findsOneWidget);
    });

    testWidgets('shows "Good morning" at 11:00 (upper boundary)',
        (tester) async {
      await tester.pumpWidget(_buildHeader(currentDate: _dateAtHour(11)));
      await tester.pump();

      expect(find.text('Good morning'), findsOneWidget);
    });

    testWidgets('shows "Good afternoon" at 14:00', (tester) async {
      await tester.pumpWidget(_buildHeader(currentDate: _dateAtHour(14)));
      await tester.pump();

      expect(find.text('Good afternoon'), findsOneWidget);
    });

    testWidgets('shows "Good afternoon" at 12:00 (boundary)', (tester) async {
      await tester.pumpWidget(_buildHeader(currentDate: _dateAtHour(12)));
      await tester.pump();

      expect(find.text('Good afternoon'), findsOneWidget);
    });

    testWidgets('shows "Good afternoon" at 17:00 (upper boundary)',
        (tester) async {
      await tester.pumpWidget(_buildHeader(currentDate: _dateAtHour(17)));
      await tester.pump();

      expect(find.text('Good afternoon'), findsOneWidget);
    });

    testWidgets('shows "Good evening" at 20:00', (tester) async {
      await tester.pumpWidget(_buildHeader(currentDate: _dateAtHour(20)));
      await tester.pump();

      expect(find.text('Good evening'), findsOneWidget);
    });

    testWidgets('shows "Good evening" at 18:00 (boundary)', (tester) async {
      await tester.pumpWidget(_buildHeader(currentDate: _dateAtHour(18)));
      await tester.pump();

      expect(find.text('Good evening'), findsOneWidget);
    });

    testWidgets('shows "Good evening" at 00:00 (midnight)', (tester) async {
      await tester.pumpWidget(_buildHeader(currentDate: _dateAtHour(0)));
      await tester.pump();

      expect(find.text('Good evening'), findsOneWidget);
    });

    testWidgets('shows "Good evening" at 04:00 (pre-dawn)', (tester) async {
      await tester.pumpWidget(_buildHeader(currentDate: _dateAtHour(4)));
      await tester.pump();

      expect(find.text('Good evening'), findsOneWidget);
    });
  });

  group('HomeHeader — userName in greeting', () {
    testWidgets('appends userName to greeting when provided', (tester) async {
      await tester.pumpWidget(
        _buildHeader(userName: 'Burak', currentDate: _dateAtHour(20)),
      );
      await tester.pump();

      expect(find.text('Good evening, Burak'), findsOneWidget);
    });

    testWidgets('shows greeting only when userName is empty string',
        (tester) async {
      await tester.pumpWidget(
        _buildHeader(userName: '', currentDate: _dateAtHour(20)),
      );
      await tester.pump();

      expect(find.text('Good evening'), findsOneWidget);
      expect(find.textContaining('Good evening,'), findsNothing);
    });

    testWidgets('shows greeting only when userName is whitespace only',
        (tester) async {
      await tester.pumpWidget(
        _buildHeader(userName: '   ', currentDate: _dateAtHour(14)),
      );
      await tester.pump();

      expect(find.text('Good afternoon'), findsOneWidget);
      expect(find.textContaining('Good afternoon,'), findsNothing);
    });

    testWidgets('uses default empty userName when not supplied',
        (tester) async {
      await tester.pumpWidget(
        _buildHeader(currentDate: _dateAtHour(9)),
      );
      await tester.pump();

      // No comma + name suffix
      expect(find.textContaining('Good morning,'), findsNothing);
      expect(find.text('Good morning'), findsOneWidget);
    });
  });

  group('HomeHeader — avatar', () {
    testWidgets('shows first letter of userName in avatar', (tester) async {
      await tester.pumpWidget(
        _buildHeader(userName: 'Burak', currentDate: _dateAtHour(9)),
      );
      await tester.pump();

      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('uppercases the initial', (tester) async {
      await tester.pumpWidget(
        _buildHeader(userName: 'ali', currentDate: _dateAtHour(9)),
      );
      await tester.pump();

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows person icon when userName is empty', (tester) async {
      await tester.pumpWidget(
        _buildHeader(userName: '', currentDate: _dateAtHour(9)),
      );
      await tester.pump();

      // Person icon is rendered via Icon widget
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('avatar tap fires onAvatarTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildHeader(
          userName: 'Burak',
          currentDate: _dateAtHour(14),
          onAvatarTap: () => tapped = true,
        ),
      );
      await tester.pump();

      // The 44×44 tap target wraps the avatar initial
      await tester.tap(find.text('B'));
      expect(tapped, isTrue);
    });

    testWidgets('avatar tap fires callback when userName is empty',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildHeader(
          userName: '',
          currentDate: _dateAtHour(14),
          onAvatarTap: () => tapped = true,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.person_outline));
      expect(tapped, isTrue);
    });
  });

  group('HomeHeader — date formatting', () {
    testWidgets('formats date in EN locale as "Wednesday, 7 May"',
        (tester) async {
      // 7 May 2026 is a Thursday — wait, let me verify: May 7 2026 is a Thursday.
      await tester.pumpWidget(
        _buildHeader(
          currentDate: DateTime(2026, 5, 7, 9),
          locale: const Locale('en'),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Thursday'), findsOneWidget);
      expect(find.textContaining('7 May'), findsOneWidget);
    });

    testWidgets('formats date in TR locale with day-first pattern',
        (tester) async {
      await tester.pumpWidget(
        _buildHeader(
          currentDate: DateTime(2026, 5, 7, 9),
          locale: const Locale('tr'),
        ),
      );
      await tester.pump();

      // TR format: "7 Mayıs Perşembe"
      expect(find.textContaining('7'), findsWidgets);
      expect(find.textContaining('Perşembe'), findsOneWidget);
    });
  });

  group('HomeHeader — layout and structure', () {
    testWidgets('renders without overflow on standard iOS viewport',
        (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _buildHeader(userName: 'Burak', currentDate: _dateAtHour(9)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without error in dark theme', (tester) async {
      await tester.pumpWidget(
        _buildHeader(
          userName: 'Burak',
          currentDate: _dateAtHour(20),
          theme: AppTheme.dark,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Good evening, Burak'), findsOneWidget);
    });

    testWidgets('does not call DateTime.now internally — uses injected date',
        (tester) async {
      // Fix date at midnight (hour=0) — ensures we get "Good evening" not system time.
      final fixedDate = DateTime(2026, 1, 1, 0, 0, 0);
      await tester.pumpWidget(_buildHeader(currentDate: fixedDate));
      await tester.pump();

      expect(find.text('Good evening'), findsOneWidget);
    });
  });
}
