import 'package:cc_domain/features/governance/domain/entities/agent_runtime_state.dart';
import 'package:cc_domain/features/governance/domain/repositories/agent_runtime_state_repository.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/agent_runtime_state_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/agent_runtime_state_mapper.dart';

/// Drift-backed [AgentRuntimeStateRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).agentRuntimeStateDao` per call: heartbeat rows live in
/// their workspace's own database file. [listAll] is the one read that spans
/// files.
class DaoAgentRuntimeStateRepository implements AgentRuntimeStateRepository {
  /// Creates a [DaoAgentRuntimeStateRepository] over the per-workspace
  /// databases.
  DaoAgentRuntimeStateRepository(this._dbs)
    : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  final AgentRuntimeStateMapper _mapper = const AgentRuntimeStateMapper();

  AgentRuntimeStateDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).agentRuntimeStateDao;

  @override
  Stream<List<AgentRuntimeState>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId).watchByWorkspace(workspaceId).map(_mapper.toDomainList);

  @override
  Future<List<AgentRuntimeState>> listByWorkspace(String workspaceId) async =>
      _mapper.toDomainList(await _dao(workspaceId).getByWorkspace(workspaceId));

  @override
  Future<AgentRuntimeState?> getForAgent(
    String workspaceId,
    String agentId,
  ) async {
    final row = await _dao(workspaceId).getForAgent(workspaceId, agentId);
    return row == null ? null : _mapper.toDomain(row);
  }

  /// CROSS-WORKSPACE BY DESIGN: the runtime-health GC sweeper has to see every
  /// workspace's heartbeat rows to expire the stale ones, so this read opens
  /// every workspace file. A workspace-scoped surface uses [listByWorkspace].
  @override
  Future<List<AgentRuntimeState>> listAll() async {
    final perWorkspace = await _cross.fanOut(
      (db) => db.agentRuntimeStateDao.getAll(),
    );
    return _mapper.toDomainList([for (final rows in perWorkspace) ...rows]);
  }

  @override
  Future<void> upsert(AgentRuntimeState state) =>
      // The state row carries its own workspace, so the file is picked from the
      // entity rather than from a parameter that could disagree with it.
      _dao(state.workspaceId).upsert(_mapper.toCompanion(state));

  @override
  Future<void> delete(String workspaceId, String agentId) =>
      _dao(workspaceId).deleteForAgent(workspaceId, agentId).then((_) {});
}
