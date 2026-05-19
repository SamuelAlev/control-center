import 'package:cc_persistence/database/tables/rigs_tables.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'rig_dao.g.dart';

/// Data access for enclosure (rig) sessions and their action log.
///
/// Every read filters by `workspaceId`. Inside a workspace file that filter is
/// redundant — the file holds one workspace — but it keeps the queries
/// self-describing and matches every other DAO here.
@DriftAccessor(tables: [RigSessionsTable, RigActionLogTable])
class RigDao extends DatabaseAccessor<WorkspaceDatabase> with _$RigDaoMixin {
  /// Creates a [RigDao].
  RigDao(super.db);

  /// Inserts or replaces a session by id.
  Future<void> upsertSession(RigSessionsTableCompanion entry) =>
      into(rigSessionsTable).insertOnConflictUpdate(entry);

  /// One session by id within [workspaceId], or null.
  Future<RigSessionsTableData?> sessionById(String workspaceId, String id) =>
      (select(rigSessionsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.id.equals(id),
          ))
          .getSingleOrNull();

  /// Sessions in [workspaceId], newest first.
  Future<List<RigSessionsTableData>> sessions(
    String workspaceId, {
    bool includeClosed = true,
  }) {
    final q = select(rigSessionsTable)
      ..where((t) => t.workspaceId.equals(workspaceId));
    if (!includeClosed) {
      q.where((t) => t.phase.isNotIn(_terminalPhases));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  /// Live sessions in [workspaceId] — the ones still holding a machine.
  Future<List<RigSessionsTableData>> liveSessions(String workspaceId) =>
      (select(rigSessionsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.phase.isNotIn(_terminalPhases),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// Live sessions in this workspace file, regardless of workspace column.
  ///
  /// CROSS-WORKSPACE BY DESIGN: called through `CrossWorkspaceQueries.fanOut`
  /// by the reaper and the shutdown sweep, which must find every running
  /// hypervisor process on the host — an orphaned VM does not care which
  /// workspace opened it. The workspace-scoped alternative is [liveSessions]
  /// and that is what all feature code uses.
  Future<List<RigSessionsTableData>> allLiveSessions() =>
      (select(rigSessionsTable)
            ..where((t) => t.phase.isNotIn(_terminalPhases)))
          .get();

  /// Live view of [workspaceId]'s sessions, newest first.
  Stream<List<RigSessionsTableData>> watchSessions(String workspaceId) =>
      (select(rigSessionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Appends an action-log row.
  Future<void> insertAction(RigActionLogTableCompanion entry) =>
      into(rigActionLogTable).insert(entry);

  /// The next free `seq` for [rigId] — `max(seq) + 1`, or 1 for a fresh rig.
  ///
  /// Callers MUST hold a write transaction across this and the insert, or two
  /// concurrent actions can read the same max and collide on the
  /// `(rigId, seq)` unique key. The unique key is what turns that race into a
  /// loud failure rather than two rows claiming the same position in history.
  Future<int> nextActionSeq(String workspaceId, String rigId) async {
    final maxSeq = rigActionLogTable.seq.max();
    final row =
        await (selectOnly(rigActionLogTable)
              ..addColumns([maxSeq])
              // Scoped by workspace as well as rig, like every other read in
              // this DAO. Redundant inside a workspace file — which is the
              // point: the day one of these reads runs against the wrong
              // database, the redundant predicate is what finds nothing
              // instead of something.
              ..where(
                rigActionLogTable.workspaceId.equals(workspaceId) &
                    rigActionLogTable.rigId.equals(rigId),
              ))
            .getSingle();
    return (row.read(maxSeq) ?? 0) + 1;
  }

  /// Action log for one rig, oldest first.
  Future<List<RigActionLogTableData>> actions(
    String workspaceId,
    String rigId, {
    int limit = 200,
  }) =>
      (select(rigActionLogTable)
            ..where(
              (t) => t.workspaceId.equals(workspaceId) & t.rigId.equals(rigId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.seq)])
            ..limit(limit))
          .get();

  /// Live action log for one rig.
  Stream<List<RigActionLogTableData>> watchActions(
    String workspaceId,
    String rigId, {
    int limit = 200,
  }) =>
      (select(rigActionLogTable)
            ..where(
              (t) => t.workspaceId.equals(workspaceId) & t.rigId.equals(rigId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.seq)])
            ..limit(limit))
          .watch();

  /// Deletes closed sessions (and their actions) created before [before].
  /// Returns the number of sessions removed.
  Future<int> purgeClosedBefore(String workspaceId, DateTime before) async {
    final stale =
        await (select(rigSessionsTable)..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.phase.isIn(_terminalPhases) &
                  t.createdAt.isSmallerThanValue(before),
            ))
            .get();
    if (stale.isEmpty) {
      return 0;
    }
    final ids = [for (final s in stale) s.id];
    await transaction(() async {
      // Chunked so a long-running workspace with thousands of stale rigs does
      // not build one enormous `IN` list.
      for (var i = 0; i < ids.length; i += 200) {
        final chunk = ids.sublist(i, (i + 200).clamp(0, ids.length));
        await (delete(rigActionLogTable)..where(
              (t) => t.workspaceId.equals(workspaceId) & t.rigId.isIn(chunk),
            ))
            .go();
        await (delete(rigSessionsTable)..where(
              (t) => t.workspaceId.equals(workspaceId) & t.id.isIn(chunk),
            ))
            .go();
      }
    });
    return ids.length;
  }

  /// Phases that mean the machine is gone.
  static const List<String> _terminalPhases = ['closed', 'failed'];
}
