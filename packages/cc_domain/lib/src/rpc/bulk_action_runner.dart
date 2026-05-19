/// Runs a bulk action as N independent idempotent mutations (PRD 19 §9 + the
/// "bulk actions key per item" clarification).
library;

import 'package:cc_domain/src/rpc/action_determinism.dart';

/// The outcome of one item in a bulk action.
class BulkItemResult<T> {
  /// Creates a [BulkItemResult].
  const BulkItemResult({
    required this.item,
    required this.idempotencyKey,
    required this.ok,
    this.error,
  });

  /// The item this result is for.
  final T item;

  /// The per-item idempotency key it ran under (derived `bulkKey/itemId`).
  final String idempotencyKey;

  /// Whether the item's action succeeded.
  final bool ok;

  /// The failure, when [ok] is false.
  final Object? error;
}

/// The aggregate outcome of a bulk action.
class BulkActionOutcome<T> {
  /// Creates a [BulkActionOutcome].
  const BulkActionOutcome(this.results);

  /// Per-item results, in submission order.
  final List<BulkItemResult<T>> results;

  /// Items that succeeded.
  List<T> get succeeded => [
    for (final r in results)
      if (r.ok) r.item,
  ];

  /// Items that failed (retry only these — each keeps its independent key).
  List<T> get failed => [
    for (final r in results)
      if (!r.ok) r.item,
  ];

  /// How many items applied.
  int get successCount => succeeded.length;

  /// Whether every item applied.
  bool get allSucceeded => results.every((r) => r.ok);
}

/// Runs [action] over [items], each under its own idempotency key derived as
/// `bulkKey/itemId` (PRD 19). A per-item failure is isolated — it never aborts
/// the others, and only the failed items need retrying (with the SAME
/// [bulkKey], so their keys are stable and a partial re-run dedupes the
/// already-applied ones).
///
/// [bulkKey] is one logical action id for the whole operation (mint it once
/// with [newIdempotencyKey]); reuse it across retries of the same bulk intent.
Future<BulkActionOutcome<T>> runBulkAction<T>({
  required String bulkKey,
  required List<T> items,
  required String Function(T) itemId,
  required Future<void> Function(T item, String idempotencyKey) action,
}) async {
  final results = <BulkItemResult<T>>[];
  for (final item in items) {
    final key = bulkItemIdempotencyKey(bulkKey, itemId(item));
    try {
      await action(item, key);
      results.add(BulkItemResult(item: item, idempotencyKey: key, ok: true));
    } catch (e) {
      results.add(
        BulkItemResult(item: item, idempotencyKey: key, ok: false, error: e),
      );
    }
  }
  return BulkActionOutcome(results);
}
