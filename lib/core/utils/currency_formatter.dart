// Utility for formatting monetary amounts — core/utils feature.
import 'package:intl/intl.dart';

/// Formats [amount] with [symbol] and [locale] following local conventions.
///
/// Symbol position: English locales → before ("€1,234.56");
///                  all others      → after ("1.234,56 €").
/// Abbreviated compact forms are used in calendar cells.
class CurrencyFormatter {
  CurrencyFormatter._();

  static NumberFormat _fmt(String locale) =>
      NumberFormat('#,##0.00', locale);

  static bool _symbolAfter(String locale) =>
      locale.split('_').first != 'en';

  static String _compose(String number, String symbol, String locale) {
    return _symbolAfter(locale) ? '$number $symbol' : '$symbol$number';
  }

  /// Returns the full formatted string, e.g. "1.234,56 €" (tr) or "€1,234.56" (en).
  static String format(
    double amount, {
    String symbol = '€',
    String locale = 'tr_TR',
  }) {
    return _compose(_fmt(locale).format(amount), symbol, locale);
  }

  /// Returns a compact abbreviated string for tight UI contexts (calendar).
  static String formatCompact(
    double amount, {
    String symbol = '€',
    String locale = 'tr_TR',
  }) {
    final abs = amount.abs();
    final String number;
    if (abs < 1000) {
      number = _fmt(locale).format(amount);
    } else if (abs < 10000) {
      number = '${(amount / 1000).toStringAsFixed(1)}K';
    } else if (abs < 1000000) {
      number = '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      number = '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    return _compose(number, symbol, locale);
  }

  /// Formats a signed total, e.g. "+1.234,56 €" or "-151,13 €".
  static String formatSigned(
    double amount, {
    String symbol = '€',
    String locale = 'tr_TR',
  }) {
    final sign = amount >= 0 ? '+' : '-';
    return '$sign${format(amount.abs(), symbol: symbol, locale: locale)}';
  }
}
