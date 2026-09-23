import 'package:cc_domain/features/messaging/domain/entities/space_stack_entry.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_stack_repository.dart';
import 'package:cc_persistence/database/daos/space_stack_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [SpaceStackRepository].
///
/// Holds the manager and resolves `_dbs.of(workspaceId).spaceStackDao` per
/// call. A cached DAO would answer every later caller from the first
/// workspace it saw.
class DaoSpaceStackRepository implements SpaceStackRepository {
  /// Creates a [DaoSpaceStackRepository] over the per-workspace databases.
  DaoSpaceStackRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  SpaceStackDao _dao(String workspaceId) => _dbs.of(workspaceId).spaceStackDao;

  @override
  Future<List<SpaceStackEntry>> forSpace(
    String workspaceId,
    String spaceId,
  ) async {
    final rows = await _dao(workspaceId).forSpace(workspaceId, spaceId);
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<SpaceStackEntry>> forRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async {
    final rows = await _dao(
      workspaceId,
    ).forRepo(workspaceId, spaceId, repoId);
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> upsert(SpaceStackEntry entry) =>
      _dao(entry.workspaceId).upsert(_companion(entry));

  @override
  Future<void> deleteForRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) => _dao(workspaceId).deleteForRepo(workspaceId, spaceId, repoId);

  @override
  Future<void> deleteById(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(workspaceId, id);

  static SpaceStackEntriesTableCompanion _companion(SpaceStackEntry entry) =>
      SpaceStackEntriesTableCompanion(
        id: Value(entry.id),
        workspaceId: Value(entry.workspaceId),
        spaceId: Value(entry.spaceId),
        repoId: Value(entry.repoId),
        position: Value(entry.position),
        branch: Value(entry.branch),
        baseBranch: Value(entry.baseBranch),
        prNumber: Value(entry.prNumber),
        prExternalId: Value(entry.prExternalId),
        rewritten: Value(entry.rewritten),
        createdAt: Value(entry.createdAt),
      );

  static SpaceStackEntry _fromRow(SpaceStackEntriesTableData row) =>
      SpaceStackEntry(
        id: row.id,
        workspaceId: row.workspaceId,
        spaceId: row.spaceId,
        repoId: row.repoId,
        position: row.position,
        branch: row.branch,
        baseBranch: row.baseBranch,
        prNumber: row.prNumber,
        prExternalId: row.prExternalId,
        rewritten: row.rewritten,
        createdAt: row.createdAt,
      );
}
