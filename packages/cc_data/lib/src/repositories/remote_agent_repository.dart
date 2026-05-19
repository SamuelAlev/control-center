import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates agents over the RPC client instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. Every agent belongs to
/// exactly one workspace and a workspace id selects the database file
/// server-side, so each workspace-scoped call names its `workspace_id` — an
/// agent id from another workspace must not resolve. [watchAll] is the
/// documented cross-workspace exception. Mirrors the `agents.*` ops +
/// `agents.watchForWorkspace` / `agents.watchAll` subscriptions in the host
/// catalog.
class RemoteAgentRepository {
  /// Creates a [RemoteAgentRepository] over [_client].
  RemoteAgentRepository(this._client);

  final RemoteRpcClient _client;

  /// A single agent by id within [workspaceId], or null.
  Future<AgentDto?> get(String workspaceId, String agentId) async {
    final data = await _client.call('agents.get', {
      'workspace_id': workspaceId,
      'agent_id': agentId,
    });
    final agent = data['agent'];
    return agent is Map
        ? AgentDto.fromJson(agent.cast<String, dynamic>())
        : null;
  }

  /// The agent named [name] in [workspaceId], or null.
  Future<AgentDto?> findByName(String workspaceId, String name) async {
    final data = await _client.call('agents.findByName', {
      'workspace_id': workspaceId,
      'name': name,
    });
    final agent = data['agent'];
    return agent is Map
        ? AgentDto.fromJson(agent.cast<String, dynamic>())
        : null;
  }

  /// Inserts or updates [agent] (the host owns persistence). The workspace
  /// comes from [AgentDto.workspaceId] — an agent's own workspace is the only
  /// authoritative answer, so it is never threaded separately.
  Future<void> upsert(AgentDto agent) => _client.call('agents.upsert', {
    'workspace_id': agent.workspaceId,
    'agent': agent.toJson(),
  });

  /// Deletes the agent [agentId] from [workspaceId].
  Future<void> delete(String workspaceId, String agentId) => _client.call(
    'agents.delete',
    {'workspace_id': workspaceId, 'agent_id': agentId},
  );

  /// Live agents in [workspaceId] — a fresh snapshot on every change.
  Stream<List<AgentDto>> watch(String workspaceId) => _client
      .subscribe('agents.watchForWorkspace', {'workspace_id': workspaceId})
      .map(_agents);

  /// Live agents across ALL workspaces (the dashboard's global view).
  Stream<List<AgentDto>> watchAll() =>
      _client.subscribe('agents.watchAll', const {}).map(_agents);

  List<AgentDto> _agents(Map<String, dynamic> data) =>
      ((data['agents'] as List?) ?? const [])
          .whereType<Map>()
          .map((a) => AgentDto.fromJson(a.cast<String, dynamic>()))
          .toList();
}
