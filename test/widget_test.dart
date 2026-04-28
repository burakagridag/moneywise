// Widget and unit tests for Sprint 1 foundation.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/app.dart';
import 'package:moneywise/core/constants/app_colors.dart';
import 'package:moneywise/core/constants/app_spacing.dart';
import 'package:moneywise/core/constants/app_typography.dart';
import 'package:moneywise/core/router/routes.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:moneywise/features/more/presentation/providers/theme_mode_provider.dart';
import 'package:moneywise/features/more/presentation/screens/more_screen.dart';
import 'package:moneywise/features/stats/presentation/screens/stats_screen.dart';
import 'package:moneywise/features/transactions/presentation/screens/transactions_screen.dart';

void main() {
  group('App smoke test', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: MoneyWiseApp()));
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Placeholder screens', () {
    Widget buildScreen(Widget screen) => ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: screen,
          ),
        );

    testWidgets('TransactionsScreen renders', (tester) async {
      await tester.pumpWidget(buildScreen(const TransactionsScreen()));
      expect(find.text('Transactions'), findsOneWidget);
    });

    testWidgets('StatsScreen renders', (tester) async {
      await tester.pumpWidget(buildScreen(const StatsScreen()));
      expect(find.text('Stats'), findsOneWidget);
    });

    testWidgets('AccountsScreen renders', (tester) async {
      await tester.pumpWidget(buildScreen(const AccountsScreen()));
      expect(find.text('Accounts'), findsOneWidget);
    });

    testWidgets('MoreScreen renders', (tester) async {
      await tester.pumpWidget(buildScreen(const MoreScreen()));
      expect(find.text('More'), findsOneWidget);
    });
  });

  group('AppColors', () {
    test('brand primary is coral', () {
      expect(AppColors.brandPrimary, const Color(0xFFFF6B5C));
    });

    test('dark bg primary is darkest background', () {
      expect(AppColors.bgPrimary, const Color(0xFF1A1B1E));
    });

    test('income is blue', () {
      expect(AppColors.income, const Color(0xFF4A90E2));
    });
  });

  group('AppSpacing', () {
    test('spacing scale is ordered', () {
      expect(AppSpacing.xs, lessThan(AppSpacing.sm));
      expect(AppSpacing.sm, lessThan(AppSpacing.md));
      expect(AppSpacing.md, lessThan(AppSpacing.lg));
      expect(AppSpacing.lg, lessThan(AppSpacing.xl));
    });

    test('button height meets minimum tap target', () {
      expect(AppHeights.button, greaterThanOrEqualTo(44.0));
    });
  });

  group('AppTypography', () {
    test('large title has correct font size', () {
      expect(AppTypography.largeTitle.fontSize, 34.0);
    });

    test('money styles use tabular figures', () {
      expect(AppTypography.moneyLarge.fontFeatures, isNotEmpty);
    });
  });

  group('Routes', () {
    test('all route paths start with /', () {
      expect(Routes.transactions, startsWith('/'));
      expect(Routes.stats, startsWith('/'));
      expect(Routes.accounts, startsWith('/'));
      expect(Routes.more, startsWith('/'));
    });

    test('all routes are unique', () {
      final routes = [
        Routes.transactions,
        Routes.stats,
        Routes.accounts,
        Routes.more,
      ];
      expect(routes.toSet().length, routes.length);
    });
  });

  group('AppTheme', () {
    test('dark theme has correct scaffold background', () {
      expect(
        AppTheme.dark.scaffoldBackgroundColor,
        AppColors.bgPrimary,
      );
    });

    test('light theme has correct scaffold background', () {
      expect(
        AppTheme.light.scaffoldBackgroundColor,
        AppColors.bgPrimaryLight,
      );
    });

    test('both themes use brand primary as primary color', () {
      expect(AppTheme.dark.colorScheme.primary, AppColors.brandPrimary);
      expect(AppTheme.light.colorScheme.primary, AppColors.brandPrimary);
    });
  });

  group('AppThemeMode provider', () {
    test('defaults to dark mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(appThemeModeProvider), ThemeMode.dark);
    });

    test('toggle switches to light mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appThemeModeProvider.notifier).toggle();
      expect(container.read(appThemeModeProvider), ThemeMode.light);
    });

    test('double toggle returns to dark mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appThemeModeProvider.notifier).toggle();
      container.read(appThemeModeProvider.notifier).toggle();
      expect(container.read(appThemeModeProvider), ThemeMode.dark);
    });
  });
}
