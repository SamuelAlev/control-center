import 'dart:collection';

/// Reuses the entity built for a row Map across delta emissions.
///
/// `SyncedStore` emits a fresh whole-table list on every delta frame, and each
/// repository pipeline mapped every row through `Dto.fromJson` + an entity
/// constructor on every one — so a single field change on a single ticket cost
/// N full row decodes (a ticket alone parses seven `DateTime`s) and N entity
/// builds, on the UI isolate. A busy agent writing 20 tickets a minute into a
/// 2,000-ticket workspace burned that continuously.
///
/// The store hands back the very same `Map` INSTANCE for a row it did not
/// touch, so identity is an exact, free "is this row unchanged?" test — no
/// field comparison, no risk of a stale entity for a row that did change.
/// A row carrying an optimistic overlay is a freshly merged map, so it
/// correctly misses and rebuilds.
///
/// One instance per SUBSCRIPTION (it is per-listener state, like the store's
/// own fan-out), and it holds only what the last emission contained: entities
/// for rows that disappeared are dropped on the next pass.
class RowEntityCache<T> {
  Map<Map<String, dynamic>, T> _previous = _identityMap<T>();

  static Map<Map<String, dynamic>, T> _identityMap<T>() =>
      HashMap<Map<String, dynamic>, T>(
        equals: identical,
        hashCode: identityHashCode,
      );

  /// Maps [rows] through [build], reusing the entity from the previous call
  /// for any row Map that is [identical] to one seen then.
  List<T> map(
    List<Map<String, dynamic>> rows,
    T Function(Map<String, dynamic> row) build,
  ) {
    final next = _identityMap<T>();
    final out = List<T>.generate(rows.length, (i) {
      final row = rows[i];
      final entity = _previous[row] ?? build(row);
      next[row] = entity;
      return entity;
    }, growable: false);
    _previous = next;
    return out;
  }

  /// Drops every retained entity.
  void clear() => _previous = _identityMap<T>();
}
