import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/agent_dao.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/features/agents/data/mappers/agent_mapper.dart';
import 'package:drift/drift.dart' as drift;

/// Dao agent repository.
class DaoAgentRepository implements AgentRepository {
  /// Creates a new [Dao agent repository].
  DaoAgentRepository(this._dao);

  final AgentDao _dao;
  final AgentMapper _mapper = const AgentMapper();

  @override
  Stream<List<Agent>> watchAll() => _dao.watchAll().map(_mapper.toDomainList);

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      _dao.watchByWorkspace(workspaceId).map(_mapper.toDomainList);

  @override
  Future<Agent?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async {
    final row = await _dao.getByWorkspaceAndName(workspaceId, name);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<void> upsert(Agent agent) => _dao.upsert(
    AgentsTableCompanion(
      id: drift.Value(agent.id),
      name: drift.Value(agent.name),
      title: drift.Value(agent.title),
      agentMdPath: drift.Value(agent.agentMdPath),
      workspaceId: drift.Value.absentIfNull(agent.workspaceId),
      reportsTo: drift.Value.absentIfNull(agent.reportsTo),
      skills: drift.Value(agent.skills.join(',')),
      persona: drift.Value.absentIfNull(agent.persona),
      systemPrompt: drift.Value.absentIfNull(agent.systemPrompt),
      adapterId: drift.Value.absentIfNull(agent.adapterId),
      modelId: drift.Value.absentIfNull(agent.modelId),
      strictMode: drift.Value(agent.strictMode),
      effort: drift.Value.absentIfNull(agent.effort?.name),
      contextSize: drift.Value.absentIfNull(agent.contextSize),
      sandboxCapabilitiesJson: drift.Value(
        agent.capabilities?.toJsonString() ?? '',
      ),
      role: drift.Value.absentIfNull(agent.role?.name),
      monthlyBudgetCents: drift.Value(agent.monthlyBudgetCents),
      createdAt: drift.Value(agent.createdAt),
    ),
  );

  @override
  Future<void> delete(String id) => _dao.deleteById(id).then((_) {});
}

