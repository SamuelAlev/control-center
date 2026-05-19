import 'package:cc_data/src/repositories/remote_agent_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [AgentRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `agents.*` ops + the
/// `agents.watchForWorkspace` / `agents.watchAll` subscriptions, mapping the
/// [AgentDto] wire shape back to [Agent]. The host owns persistence (including
/// the AGENTS.md file side-effects of higher-level use-cases); this client
/// never touches a database. Reads, watches, and the direct upsert/delete
/// row writes are served.
class RpcAgentRepository implements AgentRepository {
  /// Creates an [RpcAgentRepository] over [client].
  RpcAgentRepository(RemoteRpcClient client)
    : _remote = RemoteAgentRepository(client);

  final RemoteAgentRepository _remote;

  /// Rebuilds an [Agent] from its wire DTO. Enum fields are encoded as `.name`;
  /// a missing `createdAt` falls back to the epoch so the entity stays valid.
  static Agent _fromDto(AgentDto d) => Agent(
    id: d.id,
    name: d.name,
    title: d.title,
    agentMdPath: d.agentMdPath,
    workspaceId: d.workspaceId,
    skills: AgentSkills(d.skills),
    reportsTo: d.reportsTo,
    persona: d.persona,
    systemPrompt: d.systemPrompt,
    adapterId: d.adapterId,
    modelId: d.modelId,
    strictMode: d.strictMode,
    effort: d.effort,
    contextSize: d.contextSize,
    role: d.role == null ? null : AgentRole.values.asNameMap()[d.role],
    capabilities: d.capabilities == null
        ? null
        : AgentCapabilities.fromJson(d.capabilities!),
    monthlyBudgetCents: d.monthlyBudgetCents,
    silenceTimeoutMinutes: d.silenceTimeoutMinutes,
    createdAt: d.createdAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.createdAt!),
  );

  static AgentDto _toDto(Agent a) => AgentDto(
    id: a.id,
    name: a.name,
    title: a.title,
    agentMdPath: a.agentMdPath,
    workspaceId: a.workspaceId,
    skills: a.skills.toList(),
    reportsTo: a.reportsTo,
    persona: a.persona,
    systemPrompt: a.systemPrompt,
    adapterId: a.adapterId,
    modelId: a.modelId,
    strictMode: a.strictMode,
    effort: a.effort,
    contextSize: a.contextSize,
    role: a.role?.name,
    capabilities: a.capabilities?.toJson(),
    monthlyBudgetCents: a.monthlyBudgetCents,
    silenceTimeoutMinutes: a.silenceTimeoutMinutes,
    createdAt: a.createdAt.toIso8601String(),
  );

  @override
  Stream<List<Agent>> watchAll() =>
      _remote.watchAll().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      _remote.watch().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<Agent?> getById(String id) async {
    try {
      final dto = await _remote.get(id);
      return dto == null ? null : _fromDto(dto);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) async {
    final dto = await _remote.findByName(name);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<void> upsert(Agent agent) => _remote.upsert(_toDto(agent));

  @override
  Future<void> delete(String id) => _remote.delete(id);
}
