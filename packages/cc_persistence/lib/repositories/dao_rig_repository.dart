import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig_action_log_entry.dart';
import 'package:cc_domain/features/rigs/domain/repositories/rig_repository.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/rig_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/rig_mapper.dart';

/// Drift-backed [RigRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves `_dbs.of(workspaceId)
/// .rigDao` per call — never a cached DAO field, which would pin the first
/// workspace it saw and answer every later caller from that workspace's file.
class DaoRigRepository implements RigRepository {
  /// Creates a [DaoRigRepository] over the per-workspace databases.
  DaoRigRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final RigMapper _mapper = const RigMapper();

  RigDao _dao(String workspaceId) => _dbs.of(workspaceId).rigDao;

  @override
  Future<void> save(String workspaceId, Rig rig) {
    if (rig.workspaceId != workspaceId) {
      // The entity carries its own workspace, so a disagreement here means a
      // caller threaded the wrong id. Writing either one would put the row in
      // a file it does not belong to.
      throw ArgumentError(
        'Rig ${rig.id} belongs to workspace ${rig.workspaceId}, not '
        '$workspaceId',
      );
    }
    return _dao(workspaceId).upsertSession(_mapper.rigToCompanion(rig));
  }

  @override
  Future<Rig?> getById(String workspaceId, String rigId) async {
    final row = await _dao(workspaceId).sessionById(workspaceId, rigId);
    return row == null ? null : _mapper.rigFromRow(row);
  }

  @override
  Future<List<Rig>> list(
    String workspaceId, {
    bool includeClosed = true,
  }) async => (await _dao(
    workspaceId,
  ).sessions(workspaceId, includeClosed: includeClosed))
      .map(_mapper.rigFromRow)
      .toList();

  @override
  Future<List<Rig>> listLive(String workspaceId) async =>
      (await _dao(workspaceId).liveSessions(workspaceId))
          .map(_mapper.rigFromRow)
          .toList();

  @override
  Future<List<Rig>> listAllLive() async {
    // CROSS-WORKSPACE BY DESIGN: the idle/TTL reaper and the shutdown sweep
    // must find every running hypervisor process on this host. An orphaned VM
    // holds gigabytes of RAM and a disk overlay and nothing left running knows
    // it exists, so "which workspace owned it" is the wrong question here.
    // Workspace-scoped callers use `listLive`.
    final perWorkspace = await CrossWorkspaceQueries(
      _dbs,
    ).fanOut((db) => db.rigDao.allLiveSessions());
    return [
      for (final rows in perWorkspace)
        for (final row in rows) _mapper.rigFromRow(row),
    ];
  }

  @override
  Stream<List<Rig>> watch(String workspaceId) => _dao(workspaceId)
      .watchSessions(workspaceId)
      .map((rows) => rows.map(_mapper.rigFromRow).toList());

  @override
  Future<RigActionLogEntry> appendAction(
    String workspaceId,
    RigActionLogEntry entry,
  ) async {
    if (entry.workspaceId != workspaceId) {
      // The same guard `save` enforces, and for the same reason: the entity
      // carries its own workspace, so a disagreement means a caller threaded
      // the wrong id — and this is the AUDIT table, where a row filed under
      // the wrong workspace is worse than a missing one.
      throw ArgumentError(
        'Rig action log entry ${entry.id} belongs to workspace '
        '${entry.workspaceId}, not $workspaceId',
      );
    }
    final db = _dbs.of(workspaceId);
    // Allocating the sequence and inserting the row must be one transaction:
    // two concurrent actions would otherwise read the same `max(seq)` and
    // collide on the `(rig_id, seq)` unique key. The key turns that race into
    // a loud failure instead of two rows claiming the same moment in history,
    // and the transaction stops it happening at all.
    return db.transaction(() async {
      final seq = await db.rigDao.nextActionSeq(workspaceId, entry.rigId);
      final stamped = RigActionLogEntry(
        id: entry.id,
        workspaceId: entry.workspaceId,
        rigId: entry.rigId,
        seq: seq,
        verb: entry.verb,
        args: entry.args,
        summary: entry.summary,
        actor: entry.actor,
        isTakeOver: entry.isTakeOver,
        isError: entry.isError,
        resultText: entry.resultText,
        imageHash: entry.imageHash,
        durationMs: entry.durationMs,
        createdAt: entry.createdAt,
      );
      await db.rigDao.insertAction(_mapper.actionToCompanion(stamped));
      return stamped;
    });
  }

  @override
  Future<List<RigActionLogEntry>> actions(
    String workspaceId,
    String rigId, {
    int limit = 200,
  }) async =>
      (await _dao(workspaceId).actions(workspaceId, rigId, limit: limit))
          .map(_mapper.actionFromRow)
          .toList();

  @override
  Stream<List<RigActionLogEntry>> watchActions(
    String workspaceId,
    String rigId, {
    int limit = 200,
  }) => _dao(workspaceId)
      .watchActions(workspaceId, rigId, limit: limit)
      .map((rows) => rows.map(_mapper.actionFromRow).toList());

  @override
  Future<int> purgeClosedBefore(String workspaceId, DateTime before) =>
      _dao(workspaceId).purgeClosedBefore(workspaceId, before);
}
