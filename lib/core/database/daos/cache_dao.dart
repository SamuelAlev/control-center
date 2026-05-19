import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/caches.dart';
import 'package:drift/drift.dart';

part 'cache_dao.g.dart';

/// Data access object for the generic [CachesTable].
@DriftAccessor(tables: [CachesTable])
class CacheDao extends DatabaseAccessor<AppDatabase> with _$CacheDaoMixin {
  /// Creates a [CacheDao] for the given database.
  CacheDao(super.attachedDatabase);

  /// Watches the payload for `(workspaceId, kind, key)`. Emits `null` when
  /// the entry is absent, and re-emits whenever the row changes.
  Stream<String?> watch(String workspaceId, String kind, String key) {
    return (select(cachesTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.kind.equals(kind) &
              t.key.equals(key),
        ))
        .watchSingleOrNull()
        .map((row) => row?.payload);
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
