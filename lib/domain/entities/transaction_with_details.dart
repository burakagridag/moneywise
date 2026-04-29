// TransactionWithDetails entity — domain/entities feature.
// Aggregates a Transaction with resolved category and account display fields.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'transaction.dart';

part 'transaction_with_details.freezed.dart';

/// A [Transaction] enriched with resolved human-readable names for category
/// and account — used by DailyView and CalendarView to avoid UI fallbacks.
@freezed
class TransactionWithDetails with _$TransactionWithDetails {
  const factory TransactionWithDetails({
    required Transaction transaction,
    String? categoryName,
    String? categoryEmoji,
    String? categoryColorHex,
    String? accountName,
    String? toAccountName,
  }) = _TransactionWithDetails;
}
