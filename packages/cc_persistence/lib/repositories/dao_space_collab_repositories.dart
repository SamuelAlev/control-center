import 'dart:convert';

import 'package:cc_domain/features/messaging/domain/entities/space_takeover.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_checker_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_takeover_repository.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [SpaceTakeoverRepository] over each workspace's
/// `space_takeovers` table, resolved per call.
class DaoSpaceTakeoverRepository implements SpaceTakeoverRepository {
  /// Creates the repository over the per-workspace databases.
  DaoSpaceTakeoverRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  @override
  Future<SpaceTakeover?> get(String workspaceId, String spaceId) async {
    final db = _dbs.of(workspaceId);
    final row = await (db.select(
      db.spaceTakeoversTable,
    )..where((t) => t.spaceId.equals(spaceId))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Stream<SpaceTakeover?> watch(String workspaceId, String spaceId) {
    final db = _dbs.of(workspaceId);
    return (db.select(db.spaceTakeoversTable)
          ..where((t) => t.spaceId.equals(spaceId)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _fromRow(row))
        .distinct();
  }

  @override
  Future<bool> claim(String workspaceId, SpaceTakeover takeover) async {
    final db = _dbs.of(workspaceId);
    // `INSERT … ON CONFLICT DO NOTHING RETURNING`: the key is the space, so
    // the claim and the "is one already standing" check are one statement,
    // and of two concurrent claims only the first returns a row.
    final inserted = await db
        .into(db.spaceTakeoversTable)
        .insertReturningOrNull(
          SpaceTakeoversTableCompanion.insert(
            spaceId: takeover.spaceId,
            userId: takeover.userId,
            displayName: takeover.displayName,
            since: takeover.since,
            pausedRunIds: Value(jsonEncode(takeover.pausedRunIds)),
            stoppedRunIds: Value(jsonEncode(takeover.stoppedRunIds)),
          ),
          onConflict: DoNothing(),
        );
    return inserted != null;
  }

  @override
  Future<void> recordHeldRuns(
    String workspaceId,
    String spaceId, {
    required List<String> paused,
    required List<String> stopped,
  }) async {
    final db = _dbs.of(workspaceId);
    await (db.update(
      db.spaceTakeoversTable,
    )..where((t) => t.spaceId.equals(spaceId))).write(
      SpaceTakeoversTableCompanion(
        pausedRunIds: Value(jsonEncode(paused)),
        stoppedRunIds: Value(jsonEncode(stopped)),
      ),
    );
  }

  @override
  Future<void> release(String workspaceId, String spaceId) async {
    final db = _dbs.of(workspaceId);
    await (db.delete(
      db.spaceTakeoversTable,
    )..where((t) => t.spaceId.equals(spaceId))).go();
  }

  static SpaceTakeover _fromRow(SpaceTakeoversTableData row) => SpaceTakeover(
    spaceId: row.spaceId,
    userId: row.userId,
    displayName: row.displayName,
    since: row.since,
    pausedRunIds: _ids(row.pausedRunIds),
    stoppedRunIds: _ids(row.stoppedRunIds),
  );

  /// The column is checked to hold a JSON array, so only its elements' types
  /// are left to trust.
  static List<String> _ids(String json) => [
    for (final id in jsonDecode(json) as List)
      if (id is String) id,
  ];
}

/// Drift-backed [SpaceCheckerRepository] over each workspace's
/// `space_checkers` table, resolved per call.
class DaoSpaceCheckerRepository implements SpaceCheckerRepository {
  /// Creates the repository over the per-workspace databases.
  DaoSpaceCheckerRepository(this._dbs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final WorkspaceDatabaseManager _dbs;
  final DateTime Function() _now;

  @override
  Future<String?> checkerOf(String workspaceId, String spaceId) async {
    final db = _dbs.of(workspaceId);
    final row = await (db.select(
      db.spaceCheckersTable,
    )..where((t) => t.spaceId.equals(spaceId))).getSingleOrNull();
    return row?.agentId;
  }

  @override
  Future<void> setChecker(
    String workspaceId,
    String spaceId,
    String agentId,
  ) async {
    if (agentId.isEmpty) {
      throw ArgumentError.value(agentId, 'agentId', 'must not be empty');
    }
    final db = _dbs.of(workspaceId);
    await db
        .into(db.spaceCheckersTable)
        .insertOnConflictUpdate(
          SpaceCheckersTableCompanion.insert(
            spaceId: spaceId,
            agentId: agentId,
            updatedAt: _now(),
          ),
        );
  }

  @override
  Future<void> clearChecker(String workspaceId, String spaceId) async {
    final db = _dbs.of(workspaceId);
    await (db.delete(
      db.spaceCheckersTable,
    )..where((t) => t.spaceId.equals(spaceId))).go();
  }
}
