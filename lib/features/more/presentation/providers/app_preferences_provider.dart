// App-level preferences (theme, currency, language) backed by SharedPreferences — more feature.
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_preferences_provider.g.dart';

// ---------------------------------------------------------------------------
// Keys
// ---------------------------------------------------------------------------

const _kThemeMode = 'pref_theme_mode';
const _kCurrencyCode = 'pref_currency_code';
const _kLanguageCode = 'pref_language_code';

// ---------------------------------------------------------------------------
// Value class
// ---------------------------------------------------------------------------

/// Immutable snapshot of all persisted app preferences.
class AppPreferences {
  const AppPreferences({
    required this.themeMode,
    required this.currencyCode,
    required this.languageCode,
  });

  final ThemeMode themeMode;

  /// ISO 4217 currency code, e.g. 'EUR', 'USD'.
  final String currencyCode;

  /// BCP-47 language code, e.g. 'en', 'tr'.
  final String languageCode;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    String? currencyCode,
    String? languageCode,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      currencyCode: currencyCode ?? this.currencyCode,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ThemeMode _themeModeFromString(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String _themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Async notifier that reads/writes app preferences via [SharedPreferences].
/// Defaults: ThemeMode.system, 'EUR', 'en'.
@riverpod
class AppPreferencesNotifier extends _$AppPreferencesNotifier {
  SharedPreferences? _prefs;

  /// Safe accessor — throws [StateError] if accessed before [build] completes.
  SharedPreferences get _safePrefs {
    assert(
        _prefs != null, 'SharedPreferences accessed before build() completed');
    return _prefs!;
  }

  @override
  Future<AppPreferences> build() async {
    _prefs = await SharedPreferences.getInstance();
    return AppPreferences(
      themeMode: _themeModeFromString(_safePrefs.getString(_kThemeMode)),
      currencyCode: _safePrefs.getString(_kCurrencyCode) ?? 'EUR',
      languageCode: _safePrefs.getString(_kLanguageCode) ?? 'en',
    );
  }

  /// Persists and applies a new [ThemeMode].
  Future<void> setThemeMode(ThemeMode mode) async {
    await _safePrefs.setString(_kThemeMode, _themeModeToString(mode));
    state = AsyncData(
      state.requireValue.copyWith(themeMode: mode),
    );
  }

  /// Persists and applies a new currency [code] (ISO 4217).
  Future<void> setCurrencyCode(String code) async {
    await _safePrefs.setString(_kCurrencyCode, code);
    state = AsyncData(state.requireValue.copyWith(currencyCode: code));
  }

  /// Persists and applies a new language [code] (BCP-47).
  Future<void> setLanguageCode(String code) async {
    await _safePrefs.setString(_kLanguageCode, code);
    state = AsyncData(state.requireValue.copyWith(languageCode: code));
  }
}
