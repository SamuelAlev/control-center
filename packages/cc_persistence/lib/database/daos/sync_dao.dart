import 'package:cc_persistence/database/tables/sync_changes_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'sync_dao.g.dart';

/// Data access object for the deterministic-sync change feed (PRD 16 §6).
///
/// The feed is APPEND-ONLY and written exclusively by the SQLite triggers
/// installed in `WorkspaceDatabase._createSyncTriggers` — never by Dart code — so a
/// change row and its mutation commit atomically. Reads here power the
/// `sync.watch` delta stream and the `sync.pull` gap-fill; [pruneBefore]
/// enforces retention (a pull past the retained horizon answers
/// `snapshot_required`).
@DriftAccessor(tables: [SyncChangesTable, SyncSequencesTable])
class SyncDao extends DatabaseAccessor<WorkspaceDatabase> with _$SyncDaoMixin {
  /// Creates a [SyncDao] for the given database.
  SyncDao(super.attachedDatabase);

  /// The latest allocated sequence for [workspaceId] (0 when none yet).
  Future<int> currentSeq(String workspaceId) async {
    final row = await (select(
      syncSequencesTable,
    )..where((t) => t.workspaceId.equals(workspaceId))).getSingleOrNull();
    return row == null ? 0 : row.nextSeq - 1;
  }

  /// The oldest retained change seq for [workspaceId], or null when the feed
  /// is empty (pruned or never written).
  Future<int?> oldestSeq(String workspaceId) async {
    final row =
        await (select(syncChangesTable)
              ..where((t) => t.workspaceId.equals(workspaceId))
              ..orderBy([(t) => OrderingTerm.asc(t.seq)])
              ..limit(1))
            .getSingleOrNull();
    return row?.seq;
  }

  /// Changes for [workspaceId] with `seq > fromSeq`, ascending, capped at
  /// [limit].
  Future<List<SyncChangesTableData>> changesSince(
    String workspaceId,
    int fromSeq, {
    int limit = 500,
  }) =>
      (select(syncChangesTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.seq.isBiggerThanValue(fromSeq),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.seq)])
            ..limit(limit))
          .get();

  /// Deletes this workspace's feed rows older than [cutoff] (retention).
  ///
  /// The server-wide sweep is `CrossWorkspaceQueries.forEachWorkspace` calling
  /// this once per workspace — the cross-workspace form the shared database
  /// needed is gone.
  Future<int> pruneBefore(DateTime cutoff) =>
      (delete(syncChangesTable)..where(
            (t) =>
                t.createdAtMs.isSmallerThanValue(cutoff.millisecondsSinceEpoch),
          ))
          .go();
}
