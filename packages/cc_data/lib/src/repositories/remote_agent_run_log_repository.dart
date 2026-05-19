import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates agent run logs over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one.
/// Mirrors the `agent_run_log.*` ops + the
/// `agent_run_log.watchByAgent` / `agent_run_log.watchActiveByConversation` /
/// `agent_run_log.watchAll` subscriptions in the host catalog.
class RemoteAgentRunLogRepository {
  /// Creates a [RemoteAgentRunLogRepository] over [_client].
  RemoteAgentRunLogRepository(this._client);

  final RemoteRpcClient _client;

  /// A single run log by id (scoped to the bound workspace server-side), or
  /// null when it does not exist.
  Future<AgentRunLogDto?> get(String id) async {
    final data = await _client.call('agent_run_log.get', {'id': id});
    final log = data['log'];
    return log is Map
        ? AgentRunLogDto.fromJson(log.cast<String, dynamic>())
        : null;
  }

  /// The agent's most-recently-started run that has not reached a terminal
  /// state, or null when the agent has no active run.
  Future<AgentRunLogDto?> activeRunForAgent(String agentId) async {
    final data = await _client.call('agent_run_log.activeRunForAgent', {
      'agent_id': agentId,
    });
    final log = data['log'];
    return log is Map
        ? AgentRunLogDto.fromJson(log.cast<String, dynamic>())
        : null;
  }

  /// The run logs belonging to [pipelineRunId] in the bound workspace, newest
  /// first.
  Future<List<AgentRunLogDto>> forPipelineRun(String pipelineRunId) async {
    final data = await _client.call('agent_run_log.forPipelineRun', {
      'pipeline_run_id': pipelineRunId,
    });
    return _logs(data);
  }

  /// The run logs belonging to a specific pipeline step in the bound
  /// workspace, newest first.
  Future<List<AgentRunLogDto>> forPipelineStep(
    String pipelineRunId,
    String pipelineStepId,
  ) async {
    final data = await _client.call('agent_run_log.forPipelineStep', {
      'pipeline_run_id': pipelineRunId,
      'pipeline_step_id': pipelineStepId,
    });
    return _logs(data);
  }

  /// Inserts or updates [log] (the host owns persistence).
  Future<void> upsert(AgentRunLogDto log) =>
      _client.call('agent_run_log.upsert', {'log': log.toJson()});

  /// Live run logs for [agentId] in the bound workspace — a fresh snapshot on
  /// every change, newest first.
  Stream<List<AgentRunLogDto>> watchByAgent(String agentId) => _client
      .subscribe('agent_run_log.watchByAgent', {'agent_id': agentId})
      .map(_logs);

  /// Live active (not-yet-completed) run logs for [conversationId] in the
  /// bound workspace.
  Stream<List<AgentRunLogDto>> watchActiveByConversation(
    String conversationId,
  ) => _client
      .subscribe('agent_run_log.watchActiveByConversation', {
        'conversation_id': conversationId,
      })
      .map(_logs);

  /// Live run logs across ALL workspaces (the dashboard's global view).
  Stream<List<AgentRunLogDto>> watchAll() =>
      _client.subscribe('agent_run_log.watchAll', const {}).map(_logs);

  List<AgentRunLogDto> _logs(Map<String, dynamic> data) =>
      ((data['logs'] as List?) ?? const [])
          .whereType<Map>()
          .map((l) => AgentRunLogDto.fromJson(l.cast<String, dynamic>()))
          .toList();
}
