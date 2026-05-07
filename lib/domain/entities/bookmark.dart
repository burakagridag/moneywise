// Plain Dart domain entity for a transaction bookmark (template) — domain/entities feature.

/// Represents a saved transaction template that can be used to pre-fill the
/// add-transaction form. No dependency on any data-layer types.
class Bookmark {
  const Bookmark({
    required this.id,
    required this.name,
    required this.type,
    this.amount,
    this.currencyCode = 'EUR',
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.note,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// Transaction direction: 'income', 'expense', or 'transfer'.
  final String type;

  /// Pre-filled amount — null means the user must enter one each time.
  final double? amount;

  /// ISO 4217 currency code. Defaults to 'EUR'.
  final String currencyCode;

  final String? accountId;
  final String? toAccountId;
  final String? categoryId;
  final String? note;

  /// Display sort order. Defaults to 0.
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bookmark copyWith({
    String? id,
    String? name,
    String? type,
    double? amount,
    String? currencyCode,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    String? note,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
