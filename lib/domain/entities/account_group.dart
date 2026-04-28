// Immutable domain entity for an account group — domain/entities feature.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_group.freezed.dart';

/// Pure domain representation of an account group (e.g. Cash, Bank, Card).
/// Has no dependency on any data-layer types.
@freezed
class AccountGroup with _$AccountGroup {
  const factory AccountGroup({
    required String id,
    required String name,

    /// Discriminator string: cash|accounts|card|debitCard|savings|
    /// topUpPrepaid|investments|overdrafts|loan|insurance|others
    required String type,
    required int sortOrder,
    String? iconKey,
    required bool includeInTotals,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isDeleted,
  }) = _AccountGroup;
}
