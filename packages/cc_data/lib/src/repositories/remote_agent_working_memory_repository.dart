import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates agent working memory over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one.
/// Mirrors the `agent_working_memory.*` ops + the
/// `agent_working_memory.watchByAgent` / `agent_working_memory.watchByWorkspace`
/// subscriptions in the host catalog.
class RemoteAgentWorkingMemoryRepository {
  /// Creates a [RemoteAgentWorkingMemoryRepository] over [_client].
  RemoteAgentWorkingMemoryRepository(this._client);

  final RemoteRpcClient _client;

  /// A single agent's working memory (scoped to the bound workspace
  /// server-side), or null.
  Future<AgentWorkingMemoryDto?> getByAgent(String agentId) async {
    final data = await _client.call('agent_working_memory.getByAgent', {
      'agent_id': agentId,
    });
    final memory = data['memory'];
    return memory is Map
        ? AgentWorkingMemoryDto.fromJson(memory.cast<String, dynamic>())
        : null;
  }

  /// Inserts or updates [memory] (the host owns persistence).
  Future<void> upsert(AgentWorkingMemoryDto memory) =>
      _client.call('agent_working_memory.upsert', {'memory': memory.toJson()});

  /// Live working memory for a single agent in the bound workspace — a fresh
  /// snapshot on every change (null when none exists yet).
  Stream<AgentWorkingMemoryDto?> watchByAgent(String agentId) => _client
      .subscribe('agent_working_memory.watchByAgent', {'agent_id': agentId})
      .map((data) {
        final memory = data['memory'];
        return memory is Map
            ? AgentWorkingMemoryDto.fromJson(memory.cast<String, dynamic>())
            : null;
      });

  /// Live working memories across the bound workspace — a fresh snapshot on
  /// every change.
  Stream<List<AgentWorkingMemoryDto>> watchByWorkspace() => _client
      .subscribe('agent_working_memory.watchByWorkspace', const {})
      .map(_memories);

  List<AgentWorkingMemoryDto> _memories(Map<String, dynamic> data) =>
      ((data['memories'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => AgentWorkingMemoryDto.fromJson(m.cast<String, dynamic>()))
          .toList();
}
