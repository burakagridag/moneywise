// Unit tests for CurrencyFormatter — core/utils feature.
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/utils/currency_formatter.dart';

void main() {
  // ---------------------------------------------------------------------------
  // CurrencyFormatter.format — default locale tr_TR (symbol after, EU separators)
  // ---------------------------------------------------------------------------

  group('CurrencyFormatter.format', () {
    test('formats zero correctly', () {
      expect(CurrencyFormatter.format(0), '0,00 €');
    });

    test('formats small positive amount', () {
      expect(CurrencyFormatter.format(53.95), '53,95 €');
    });

    test('formats amount with thousands separator', () {
      expect(CurrencyFormatter.format(1234.56), '1.234,56 €');
    });

    test('uses custom symbol when provided', () {
      expect(CurrencyFormatter.format(100.0, symbol: r'$'), r'100,00 $');
    });

    test('formats negative amount', () {
      expect(CurrencyFormatter.format(-42.0), '-42,00 €');
    });

    test('symbol placed before number for en locale', () {
      expect(
        CurrencyFormatter.format(1234.56, symbol: '€', locale: 'en_US'),
        '€1,234.56',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // CurrencyFormatter.formatCompact — default locale tr_TR
  // ---------------------------------------------------------------------------

  group('CurrencyFormatter.formatCompact', () {
    test('amounts below 1000 show full decimals', () {
      expect(CurrencyFormatter.formatCompact(53.95), '53,95 €');
    });

    test('exact 1000 shows 1 decimal K notation', () {
      expect(CurrencyFormatter.formatCompact(1000.0), '1.0K €');
    });

    test('amounts 1000–9999 show K with 1 decimal', () {
      expect(CurrencyFormatter.formatCompact(1500.0), '1.5K €');
    });

    test('amounts 10000–999999 show K with 0 decimals', () {
      expect(CurrencyFormatter.formatCompact(12000.0), '12K €');
    });

    test('amounts >= 1000000 show M notation', () {
      expect(CurrencyFormatter.formatCompact(1200000.0), '1.2M €');
    });

    test('zero is formatted without K or M', () {
      expect(CurrencyFormatter.formatCompact(0), '0,00 €');
    });

    test('negative amount below 1000 shows negative sign', () {
      expect(CurrencyFormatter.formatCompact(-50.0), '-50,00 €');
    });

    test('negative amount above 1000 uses abs value for threshold check', () {
      expect(CurrencyFormatter.formatCompact(-1500.0), '-1.5K €');
    });
  });

  // ---------------------------------------------------------------------------
  // CurrencyFormatter.formatSigned — default locale tr_TR
  // ---------------------------------------------------------------------------

  group('CurrencyFormatter.formatSigned', () {
    test('positive amount shows + prefix', () {
      expect(CurrencyFormatter.formatSigned(179.50), '+179,50 €');
    });

    test('negative amount shows - prefix', () {
      expect(CurrencyFormatter.formatSigned(-151.13), '-151,13 €');
    });

    test('zero shows + prefix', () {
      expect(CurrencyFormatter.formatSigned(0), '+0,00 €');
    });

    test('uses custom symbol when provided', () {
      expect(
        CurrencyFormatter.formatSigned(100.0, symbol: '£'),
        '+100,00 £',
      );
    });
  });
}
