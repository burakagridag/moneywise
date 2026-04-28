// Immutable domain entity for an income or expense category — domain/entities feature.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

/// Pure domain representation of a transaction category.
/// Has no dependency on any data-layer types.
@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,

    /// Transaction direction: 'income' or 'expense'.
    required String type,

    /// Id of parent category for sub-categories (null for top-level).
    String? parentId,
    String? iconEmoji,
    String? colorHex,
    required int sortOrder,
    required bool isDefault,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isDeleted,
  }) = _Category;
}
