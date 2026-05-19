import 'package:cc_persistence/database/tables/caches.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'cache_dao.g.dart';

/// Data access object for the generic [CachesTable].
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

  /// Upserts the payload for `(workspaceId, kind, key)`.
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

  /// Deletes every cache entry not touched since [cutoff], across all
  /// workspaces and kinds.
  ///
  /// Retention maintenance for this workspace, not a read path.
  ///
  /// The caches table is an SWR staleness buffer (PR diffs/files/HTML blobs can
  /// run to megabytes per row); entries that haven't been refreshed in weeks are
  /// dead weight on disk. The nightly sweep runs this once per workspace.
  Future<int> deleteOlderThan(DateTime cutoff) => (delete(
    cachesTable,
  )..where((t) => t.updatedAt.isSmallerThanValue(cutoff))).go();

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
