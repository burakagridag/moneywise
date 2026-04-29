// App-wide constants used across features — core/constants.
// Centralises magic values so they can be updated in one place.

/// General application constants.
class AppConstants {
  AppConstants._();

  /// Default currency symbol shown when no per-account symbol is resolved.
  /// Phase 2 will replace this with a user-configurable currency preference.
  static const String defaultCurrencySymbol = '€';
}
