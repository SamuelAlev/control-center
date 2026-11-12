import 'package:cc_domain/core/domain/services/cache_kind_registry.dart';
import 'package:cc_persistence/database/tables/caches.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'cache_dao.g.dart';

/// Data access object for the generic [CachesTable].
///
/// Holds only kinds declared in [CacheKindRegistry]: the table's `CHECK` on
/// `kind` refuses any other, so state whose loss would change behaviour
/// cannot be parked in a table the retention sweep empties.
@DriftAccessor(tables: [CachesTable])
class CacheDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$CacheDaoMixin {
  /// Creates a [CacheDao] for the given database.
  CacheDao(super.attachedDatabase);

  /// Watches the payload for `(workspaceId, kind, key)`. Emits `null` when
  /// the entry is absent and re-emits whenever the row changes.
  ///
  /// `.distinct()` is load-bearing. Drift invalidation is table-granular, so
  /// ANY write to `caches` re-runs every watched key's query and re-emits its
  /// UNCHANGED payload — and PR-review payloads (a diff, a file list with
  /// patches) run to megabytes per row, so a single unrelated cache write
  /// pushed all of them through decode, encode and the socket again.
  ///
  /// Watching a cheap version column instead — so the payload is not even READ
  /// unless it changed — was considered and rejected: `updated_at` is stored
  /// at second resolution, so two writes inside one second share a stamp and
  /// the second one would be silently dropped. Losing a cache write is worse
  /// than re-reading a row.
  Stream<String?> watch(String workspaceId, String kind, String key) {
    return (select(cachesTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.kind.equals(kind) &
              t.key.equals(key),
        ))
        .watchSingleOrNull()
        .map((row) => row?.payload)
        .distinct();
  }

  /// Reads the current payload for `(workspaceId, kind, key)`, or `null`.
  Future<String?> read(String workspaceId, String kind, String key) async {
    final row =
        await (select(cachesTable)..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.kind.equals(kind) &
                  t.key.equals(key),
            ))
            .getSingleOrNull();
    return row?.payload;
  }

  /// Upserts the payload for `(workspaceId, kind, key)`. Throws when [kind]
  /// is not declared in [CacheKindRegistry]: declare it beside its owner if a
  /// deleted row only costs a refetch; give it a table of its own if losing
  /// it changes what the server does.
  Future<void> put(
    String workspaceId,
    String kind,
    String key,
    String payload,
  ) async {
    await into(cachesTable).insertOnConflictUpdate(
      CachesTableCompanion(
        workspaceId: Value(workspaceId),
        kind: Value(kind),
        key: Value(key),
        payload: Value(payload),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes a single entry. No-op when absent.
  Future<void> deleteEntry(String workspaceId, String kind, String key) async {
    await (delete(cachesTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.kind.equals(kind) &
              t.key.equals(key),
        ))
        .go();
  }

  /// Deletes every entry matching `(workspaceId, kind)`. Used to bust an
  /// entire entity kind at once after a write.
  Future<void> deleteKind(String workspaceId, String kind) async {
    await (delete(cachesTable)..where(
          (t) => t.workspaceId.equals(workspaceId) & t.kind.equals(kind),
        ))
        .go();
  }

  /// Deletes every row of [kind] not written since [cutoff].
  ///
  /// Retention maintenance for this file, not a read path: the sweep calls it
  /// once per declared kind with that kind's own window.
  Future<int> deleteKindOlderThan(String kind, DateTime cutoff) =>
      (delete(cachesTable)..where(
            (t) => t.kind.equals(kind) & t.updatedAt.isSmallerThanValue(cutoff),
          ))
          .go();

  /// Deletes every entry whose key starts with [keyPrefix] within a
  /// `(workspaceId, kind)`. Useful when one logical entity spans multiple
  /// cache rows (e.g. PR-scoped invalidation).
  Future<void> deleteKindWithPrefix(
    String workspaceId,
    String kind,
    String keyPrefix,
  ) async {
    await (delete(cachesTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.kind.equals(kind) &
              t.key.like('$keyPrefix%'),
        ))
        .go();
  }
}
