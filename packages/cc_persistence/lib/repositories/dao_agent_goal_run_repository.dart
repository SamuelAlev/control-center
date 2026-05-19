import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/agent_goal_run_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/agent_goal_run_mapper.dart';

/// Drift-backed [AgentGoalRunRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).agentGoalRunDao` per call: supervised goals live in
/// their workspace's own database file, so the workspace id picks the file
/// before any SQL runs. [listActive] is the one read that spans files.
class DaoAgentGoalRunRepository implements AgentGoalRunRepository {
  /// Creates a [DaoAgentGoalRunRepository] over the per-workspace databases.
  DaoAgentGoalRunRepository(this._dbs) : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  final AgentGoalRunMapper _mapper = const AgentGoalRunMapper();

  AgentGoalRunDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).agentGoalRunDao;

  @override
  Future<AgentGoalRun?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(workspaceId, id);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<List<AgentGoalRun>> listByWorkspace(String workspaceId) async =>
      _mapper.toDomainList(
        await _dao(workspaceId).listByWorkspace(workspaceId),
      );

  @override
  Stream<List<AgentGoalRun>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId).watchByWorkspace(workspaceId).map(_mapper.toDomainList);

  /// CROSS-WORKSPACE BY DESIGN: the supervisor's startup reconciler must resume
  /// every active goal regardless of workspace, so this read opens every
  /// workspace file. Each resulting re-dispatch is itself workspace-scoped. The
  /// scoped read path is [listByWorkspace].
  @override
  Future<List<AgentGoalRun>> listActive() async {
    final perWorkspace = await _cross.fanOut(
      (db) => db.agentGoalRunDao.listActive(),
    );
    return _mapper.toDomainList([for (final rows in perWorkspace) ...rows]);
  }

  @override
  Future<AgentGoalRun?> getActiveForAgent(
    String workspaceId,
    String agentId,
  ) async {
    final row = await _dao(workspaceId).getActiveForAgent(workspaceId, agentId);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<void> upsert(AgentGoalRun goal) =>
      // The goal carries its own workspace, so the file is picked from the
      // entity rather than from a parameter that could disagree with it.
      _dao(goal.workspaceId).upsert(_mapper.toCompanion(goal));
}
