import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/agent_mapper.dart';
import 'package:drift/drift.dart' as drift;

/// Drift DAO-backed implementation of [AgentRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).agentDao` per call: agents live in their workspace's
/// own database file, so the workspace id picks the file before any SQL runs.
/// [watchAll] is the one read that spans files.
class DaoAgentRepository implements AgentRepository {
  /// Creates a [DaoAgentRepository] over the per-workspace databases.
  DaoAgentRepository(this._dbs) : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  final AgentMapper _mapper = const AgentMapper();

  AgentDao _dao(String workspaceId) => _dbs.of(workspaceId).agentDao;

  /// CROSS-WORKSPACE BY DESIGN: the dashboard's all-agents view (plus process
  /// detection and the startup reconcilers) is defined over every workspace, so
  /// this watch merges one stream per workspace file. Sorted by name to restore
  /// the global order concatenation loses. A workspace-scoped surface uses
  /// [watchByWorkspace].
  @override
  Stream<List<Agent>> watchAll() => _cross
      .mergeStreams(
        (db) => db.agentDao.watchAll(),
        sort: (a, b) => a.name.compareTo(b.name),
      )
      .map(_mapper.toDomainList);

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId).watchByWorkspace(workspaceId).map(_mapper.toDomainList);

  @override
  Future<Agent?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(id);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) async {
    final row = await _dao(
      workspaceId,
    ).getByWorkspaceAndName(workspaceId, name);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<void> upsert(Agent agent) =>
      // Every agent belongs to exactly one workspace, so the file is picked from
      // the entity rather than from a parameter that could disagree with it.
      _dao(agent.workspaceId).upsert(
        AgentsTableCompanion(
          id: drift.Value(agent.id),
          name: drift.Value(agent.name),
          title: drift.Value(agent.title),
          agentMdPath: drift.Value(agent.agentMdPath),
          workspaceId: drift.Value(agent.workspaceId),
          reportsTo: drift.Value.absentIfNull(agent.reportsTo),
          skills: drift.Value(agent.skills.join(',')),
          persona: drift.Value.absentIfNull(agent.persona),
          systemPrompt: drift.Value.absentIfNull(agent.systemPrompt),
          adapterId: drift.Value.absentIfNull(agent.adapterId),
          modelId: drift.Value.absentIfNull(agent.modelId),
          strictMode: drift.Value(agent.strictMode),
          effort: drift.Value.absentIfNull(agent.effort),
          contextSize: drift.Value.absentIfNull(agent.contextSize),
          sandboxCapabilitiesJson: drift.Value(
            agent.capabilities?.toJsonString() ?? '',
          ),
          role: drift.Value.absentIfNull(agent.role?.name),
          monthlyBudgetCents: drift.Value(agent.monthlyBudgetCents),
          silenceTimeoutMinutes: drift.Value.absentIfNull(
            agent.silenceTimeoutMinutes,
          ),
          maxConcurrentTasks: drift.Value(agent.maxConcurrentTasks),
          visibility: drift.Value(agent.visibility.name),
          lifecycleStatus: drift.Value(agent.lifecycleStatus.name),
          budgetPolicyId: drift.Value.absentIfNull(agent.budgetPolicyId),
          runtimeProfileId: drift.Value.absentIfNull(agent.runtimeProfileId),
          createdAt: drift.Value(agent.createdAt),
        ),
      );

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(id).then((_) {});
}
