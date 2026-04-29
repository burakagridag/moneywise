// TransactionType enum for classifying financial transactions — domain/enums feature.

/// Classifies a transaction as an income, expense, or account-to-account
/// transfer. Stored as the raw [value] string in the database ('income',
/// 'expense', 'transfer') to remain human-readable in the SQLite file.
enum TransactionType {
  income('income'),
  expense('expense'),
  transfer('transfer');

  const TransactionType(this.value);

  /// The raw string stored in the database column.
  final String value;

  /// Returns the [TransactionType] matching [raw], or throws if unknown.
  static TransactionType fromValue(String raw) =>
      TransactionType.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw ArgumentError('Unknown TransactionType value: $raw'),
      );
}
