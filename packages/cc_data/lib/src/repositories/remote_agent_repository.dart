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

  /// Creates an agent on the host. Duplicate-name refusal, id minting and
  /// `AGENTS.md` generation run server-side (`agents.create`).
  Future<AgentDto> create({
    required String workspaceId,
    required String name,
    required String title,
    List<String> skills = const [],
    String? reportsTo,
    String? persona,
    String? systemPrompt,
    String? adapterId,
    String? modelId,
    bool strictMode = false,
    String? effort,
    int? contextSize,
  }) async {
    final data = await _client.call('agents.create', {
      'workspace_id': workspaceId,
      'name': name,
      'title': title,
      'skills': skills,
      'reportsTo': ?reportsTo,
      'persona': ?persona,
      'systemPrompt': ?systemPrompt,
      'adapterId': ?adapterId,
      'modelId': ?modelId,
      'strictMode': strictMode,
      'effort': ?effort,
      'contextSize': ?contextSize,
    });
    final agent = data['agent'];
    if (agent is! Map) {
      throw StateError('agents.create returned no agent');
    }
    return AgentDto.fromJson(agent.cast<String, dynamic>());
  }

  /// Updates an existing agent (the host owns persistence). The workspace
  /// comes from [AgentDto.workspaceId] — an agent's own workspace is the only
  /// authoritative answer, so it is never threaded separately. Creating a new
  /// row this way is refused — use [create].
  Future<void> upsert(AgentDto agent) => _client.call('agents.upsert', {
    'workspace_id': agent.workspaceId,
    'agent': agent.toJson(),
  });

  /// Deletes the agent [agentId] from [workspaceId].
  Future<void> delete(String workspaceId, String agentId) => _client.call(
    'agents.delete',
    {'workspace_id': workspaceId, 'agent_id': agentId},
  );

  /// Stops every host process belonging to [agentId] and marks its live runs
  /// killed, returning how many processes were signalled.
  ///
  /// Host work by construction: the processes are in the SERVER's process
  /// table. A client that killed pids itself only ever worked when it happened
  /// to share a machine with the server — against a remote one it silently
  /// no-op'd, or killed an unrelated recycled pid locally.
  Future<int> killProcesses(String workspaceId, String agentId) async {
    final data = await _client.call('agents.killProcesses', {
      'workspace_id': workspaceId,
      'agent_id': agentId,
    });
    return (data['killed'] as num?)?.toInt() ?? 0;
  }

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
