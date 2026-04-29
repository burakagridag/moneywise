// Riverpod providers for NoteView — grouping transactions by note — stats feature.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../domain/entities/transaction.dart';
import '../../presentation/providers/stats_provider.dart';

export '../../../../domain/entities/transaction.dart' show Transaction;

part 'note_provider.g.dart';

// ---------------------------------------------------------------------------
// Sort mode
// ---------------------------------------------------------------------------

/// Controls how note groups are sorted: 'amount' or 'count'.
@riverpod
class NoteSortMode extends _$NoteSortMode {
  @override
  String build() => 'amount';

  void setAmount() => state = 'amount';
  void setCount() => state = 'count';

  void toggle() => state = state == 'amount' ? 'count' : 'amount';
}

// ---------------------------------------------------------------------------
// Note group data class
// ---------------------------------------------------------------------------

/// Represents a group of transactions sharing the same note value.
class NoteGroup {
  const NoteGroup({
    required this.note,
    required this.transactions,
  });

  /// The note text. Null represents the "(no note)" group.
  final String? note;

  /// Transactions in this group, sorted by amount descending.
  final List<Transaction> transactions;

  int get count => transactions.length;

  double get totalAmount => transactions.fold(0.0, (s, t) => s + t.amount);
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Emits grouped note data for the selected month and stats type.
///
/// Groups are sorted per [NoteSortMode]. The "(no note)" group is always last.
@riverpod
Future<List<NoteGroup>> noteGroups(NoteGroupsRef ref) async {
  final type = ref.watch(statsTypeProvider);
  final sortMode = ref.watch(noteSortModeProvider);
  final txns = await ref.watch(statsTxnsProvider.future);

  // Filter by type and exclude excluded transactions.
  final filtered = txns.where((t) => t.type == type && !t.isExcluded).toList();

  // Group by note (trimmed; blank → null).
  final groups = <String?, List<Transaction>>{};
  for (final t in filtered) {
    final key =
        (t.description?.trim().isEmpty ?? true) ? null : t.description!.trim();
    (groups[key] ??= []).add(t);
  }

  // Sort transactions within each group by amount descending.
  for (final list in groups.values) {
    list.sort((a, b) => b.amount.compareTo(a.amount));
  }

  // Convert to list of NoteGroup objects.
  final noteGroups = groups.entries
      .map((e) => NoteGroup(note: e.key, transactions: e.value))
      .toList();

  // Separate the "(no note)" group from named groups.
  final noNoteGroup = noteGroups.where((g) => g.note == null).toList();
  final namedGroups = noteGroups.where((g) => g.note != null).toList();

  // Sort named groups.
  if (sortMode == 'amount') {
    namedGroups.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  } else {
    namedGroups.sort((a, b) {
      final cmp = b.count.compareTo(a.count);
      if (cmp != 0) return cmp;
      // Secondary sort: alphabetical by note text.
      return (a.note ?? '').compareTo(b.note ?? '');
    });
  }

  // "(no note)" always pinned last.
  return [...namedGroups, ...noNoteGroup];
}
