// Immutable domain entity for an individual account — domain/entities feature.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';

/// Pure domain representation of a single user account (wallet, bank account,
/// credit card, etc.). Has no dependency on any data-layer types.
@freezed
class Account with _$Account {
  const factory Account({
    required String id,
    required String groupId,
    required String name,
    String? description,

    /// ISO 4217 currency code, e.g. "EUR".
    required String currencyCode,
    required double initialBalance,
    required int sortOrder,
    required bool isHidden,
    required bool includeInTotals,
    String? iconKey,
    String? colorHex,

    /// Day of month on which credit-card statement closes (1–31).
    int? statementDay,

    /// Day of month on which credit-card payment is due (1–31).
    int? paymentDueDay,
    double? creditLimit,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isDeleted,
  }) = _Account;
}
