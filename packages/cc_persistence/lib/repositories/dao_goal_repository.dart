import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_persistence/database/daos/goal_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/goal_mapper.dart';

/// Drift-backed [GoalRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).goalDao` per call: org goals live in their workspace's
/// own database file, so the workspace id picks the file before any SQL runs.
class DaoGoalRepository implements GoalRepository {
  /// Creates a [DaoGoalRepository] over the per-workspace databases.
  DaoGoalRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final GoalMapper _mapper = const GoalMapper();

  GoalDao _dao(String workspaceId) => _dbs.of(workspaceId).goalDao;

  @override
  Stream<List<OrgGoal>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId).watchByWorkspace(workspaceId).map(_mapper.toDomainList);

  @override
  Future<List<OrgGoal>> listByWorkspace(String workspaceId) async =>
      _mapper.toDomainList(await _dao(workspaceId).getByWorkspace(workspaceId));

  @override
  Future<List<OrgGoal>> childrenOf(
    String workspaceId,
    String parentGoalId,
  ) async => _mapper.toDomainList(
    await _dao(workspaceId).childrenOf(workspaceId, parentGoalId),
  );

  @override
  Future<OrgGoal?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(workspaceId, id);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<void> upsert(OrgGoal goal) =>
      // The goal carries its own workspace, so the file is picked from the
      // entity rather than from a parameter that could disagree with it.
      _dao(goal.workspaceId).upsert(_mapper.toCompanion(goal));

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(workspaceId, id).then((_) {});
}
