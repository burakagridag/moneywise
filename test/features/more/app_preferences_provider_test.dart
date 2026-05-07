// Unit tests for AppPreferencesNotifier — SharedPreferences backed — more feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/features/more/presentation/providers/app_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Provide a clean, in-memory SharedPreferences for each test.
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('AppPreferencesNotifier', () {
    test('initial state returns defaults when no stored prefs exist', () async {
      final container = buildContainer();
      final prefs = await container.read(appPreferencesNotifierProvider.future);
      expect(prefs.themeMode, equals(ThemeMode.system));
      expect(prefs.currencyCode, equals('EUR'));
      expect(prefs.languageCode, equals('en'));
    });

    test('setThemeMode persists and updates state', () async {
      final container = buildContainer();
      // Wait for initial build.
      await container.read(appPreferencesNotifierProvider.future);
      await container
          .read(appPreferencesNotifierProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      final updated =
          container.read(appPreferencesNotifierProvider).requireValue;
      expect(updated.themeMode, equals(ThemeMode.dark));
    });

    test('setCurrencyCode persists and updates state', () async {
      final container = buildContainer();
      await container.read(appPreferencesNotifierProvider.future);
      await container
          .read(appPreferencesNotifierProvider.notifier)
          .setCurrencyCode('TRY');
      final updated =
          container.read(appPreferencesNotifierProvider).requireValue;
      expect(updated.currencyCode, equals('TRY'));
    });

    test('setLanguageCode persists and updates state', () async {
      final container = buildContainer();
      await container.read(appPreferencesNotifierProvider.future);
      await container
          .read(appPreferencesNotifierProvider.notifier)
          .setLanguageCode('tr');
      final updated =
          container.read(appPreferencesNotifierProvider).requireValue;
      expect(updated.languageCode, equals('tr'));
    });

    test('stored prefs are loaded on rebuild', () async {
      // Pre-seed SharedPreferences with non-default values.
      SharedPreferences.setMockInitialValues({
        'pref_theme_mode': ThemeMode.light.index,
        'pref_currency_code': 'USD',
        'pref_language_code': 'tr',
      });

      final container = buildContainer();
      final prefs = await container.read(appPreferencesNotifierProvider.future);
      expect(prefs.themeMode, equals(ThemeMode.light));
      expect(prefs.currencyCode, equals('USD'));
      expect(prefs.languageCode, equals('tr'));
    });
  });

  group('AppPreferences.copyWith', () {
    test('returns new instance with updated fields', () {
      const original = AppPreferences(
        themeMode: ThemeMode.system,
        currencyCode: 'EUR',
        languageCode: 'en',
      );
      final updated = original.copyWith(themeMode: ThemeMode.dark);
      expect(updated.themeMode, equals(ThemeMode.dark));
      expect(updated.currencyCode, equals('EUR'));
    });
  });
}
