import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates agents over the RPC client instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one.
/// Mirrors the `agents.*` ops + `agents.watchForWorkspace` / `agents.watchAll`
/// subscriptions in the host catalog.
class RemoteAgentRepository {
  /// Creates a [RemoteAgentRepository] over [_client].
  RemoteAgentRepository(this._client);

  final RemoteRpcClient _client;

  /// A single agent by id (scoped to the bound workspace server-side), or null.
  Future<AgentDto?> get(String agentId) async {
    final data = await _client.call('agents.get', {'agent_id': agentId});
    final agent = data['agent'];
    return agent is Map
        ? AgentDto.fromJson(agent.cast<String, dynamic>())
        : null;
  }

  /// The agent named [name] in the bound workspace, or null.
  Future<AgentDto?> findByName(String name) async {
    final data = await _client.call('agents.findByName', {'name': name});
    final agent = data['agent'];
    return agent is Map
        ? AgentDto.fromJson(agent.cast<String, dynamic>())
        : null;
  }

  /// Inserts or updates [agent] (the host owns persistence).
  Future<void> upsert(AgentDto agent) =>
      _client.call('agents.upsert', {'agent': agent.toJson()});

  /// Deletes the agent [agentId].
  Future<void> delete(String agentId) =>
      _client.call('agents.delete', {'agent_id': agentId});

  /// Live agents in the bound workspace — a fresh snapshot on every change.
  Stream<List<AgentDto>> watch() =>
      _client.subscribe('agents.watchForWorkspace', const {}).map(_agents);

  /// Live agents across ALL workspaces (the dashboard's global view).
  Stream<List<AgentDto>> watchAll() =>
      _client.subscribe('agents.watchAll', const {}).map(_agents);

  List<AgentDto> _agents(Map<String, dynamic> data) =>
      ((data['agents'] as List?) ?? const [])
          .whereType<Map>()
          .map((a) => AgentDto.fromJson(a.cast<String, dynamic>()))
          .toList();
}
