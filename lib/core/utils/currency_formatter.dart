// Utility for formatting monetary amounts — core/utils feature.
import 'package:intl/intl.dart';

/// Formats a [amount] with [currencySymbol] according to app display rules.
///
/// * < 1,000 → "€ 53,95"
/// * 1,000–9,999 → "€ 1.2K"
/// * ≥ 10,000 → "€ 12K"
/// * ≥ 1,000,000 → "€ 1.2M"
///
/// The abbreviated forms are used in compact contexts (calendar cells).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _fullFmt = NumberFormat('#,##0.00');

  /// Returns the full formatted string, e.g. "€ 1,234.56".
  static String format(double amount, {String symbol = '€'}) {
    return '$symbol ${_fullFmt.format(amount)}';
  }

  /// Returns a compact abbreviated string for tight UI contexts (calendar).
  static String formatCompact(double amount, {String symbol = '€'}) {
    if (amount.abs() < 1000) {
      return '$symbol${_fullFmt.format(amount)}';
    } else if (amount.abs() < 10000) {
      final k = amount / 1000;
      return '$symbol${k.toStringAsFixed(1)}K';
    } else if (amount.abs() < 1000000) {
      final k = amount / 1000;
      return '$symbol${k.toStringAsFixed(0)}K';
    } else {
      final m = amount / 1000000;
      return '$symbol${m.toStringAsFixed(1)}M';
    }
  }

  /// Formats a signed total, e.g. "+€ 179.50" or "-€ 151.13".
  static String formatSigned(double amount, {String symbol = '€'}) {
    if (amount >= 0) {
      return '+${format(amount, symbol: symbol)}';
    } else {
      return '-${format(amount.abs(), symbol: symbol)}';
    }
  }
}
