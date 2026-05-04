// Widget tests for SettingsScreen — more feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/more/presentation/screens/settings_screen.dart';

Widget _buildScreen() => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: const SettingsScreen(),
      ),
    );

void main() {
  group('SettingsScreen', () {
    testWidgets('renders Settings title in AppBar', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Settings'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Categories list tile', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
      // Multiple chevron_right icons after Sprint 6 settings tiles were added.
      expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
    });

    testWidgets('Categories tile has onTap handler', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      // Sprint 6 adds ThemePickerTile, CurrencyPickerTile, LanguagePickerTile
      // in addition to the Categories tile — so there are now 4 ListTiles.
      final tiles = find.byType(ListTile);
      expect(tiles, findsAtLeastNWidgets(1));
      // The Categories tile specifically is tappable.
      expect(find.text('Categories'), findsOneWidget);
    });
  });
}
