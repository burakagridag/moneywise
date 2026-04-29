// Immutable domain entity for a financial transaction — domain/entities feature.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';

/// Transaction direction — stored as raw string ('income', 'expense',
/// 'transfer') in the database for human-readable SQLite files.
enum TransactionType {
  income,
  expense,
  transfer;

  /// Maps a raw database string to [TransactionType].
  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown TransactionType: $value'),
    );
  }
}

/// Pure domain representation of a financial transaction.
/// Has no dependency on any data-layer types.
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,

    /// Transaction direction: 'income', 'expense', or 'transfer'.
    required String type,
    required DateTime date,
    required double amount,

    /// ISO 4217 currency code, e.g. "EUR", "TRY".
    required String currencyCode,

    /// Exchange rate to base currency.
    @Default(1.0) double exchangeRate,

    /// Source account id (required).
    required String accountId,

    /// Destination account id — only set for transfer transactions.
    String? toAccountId,

    /// Primary category id (optional).
    String? categoryId,

    /// Sub-category id (optional).
    String? subcategoryId,

    /// Optional free-text note / description.
    String? description,

    /// When true, transaction is visible but excluded from balance calculations.
    @Default(false) bool isExcluded,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isDeleted,
  }) = _Transaction;

  const Transaction._();

  /// Convenience getter that parses [type] string to [TransactionType] enum.
  TransactionType get transactionType => TransactionType.fromString(type);
}
