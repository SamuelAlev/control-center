import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates agent run logs over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. A workspace id selects
/// the database file server-side, so every workspace-scoped call names its
/// `workspace_id` in the args — an agent, conversation or run id resolves only
/// inside its own workspace. [watchRecent] is the documented cross-workspace
/// exception (the dashboard's global view). Mirrors the `agent_run_log.*` ops
/// + the `agent_run_log.watch*` subscriptions in the host catalog.
class RemoteAgentRunLogRepository {
  /// Creates a [RemoteAgentRunLogRepository] over [_client].
  RemoteAgentRunLogRepository(this._client);

  final RemoteRpcClient _client;

  /// A single run log by id within [workspaceId], or null when it does not
  /// exist there.
  Future<AgentRunLogDto?> get(String workspaceId, String id) async {
    final data = await _client.call('agent_run_log.get', {
      'workspace_id': workspaceId,
      'id': id,
    });
    final log = data['log'];
    return log is Map
        ? AgentRunLogDto.fromJson(log.cast<String, dynamic>())
        : null;
  }

  /// The agent's most-recently-started run in [workspaceId] that has not
  /// reached a terminal state, or null when the agent has no active run.
  Future<AgentRunLogDto?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async {
    final data = await _client.call('agent_run_log.activeRunForAgent', {
      'workspace_id': workspaceId,
      'agent_id': agentId,
    });
    final log = data['log'];
    return log is Map
        ? AgentRunLogDto.fromJson(log.cast<String, dynamic>())
        : null;
  }

  /// The raw NDJSON events of run [runId]'s log file, read on the HOST.
  ///
  /// `truncated` is true when the log exceeded the server's read cap and only
  /// its tail is returned. The log lives in the server's data directory, so
  /// this is the only way a thin client can show it — reading the path locally
  /// rendered an empty dialog against every remote server.
  Future<({List<Map<String, dynamic>> events, bool truncated})> readEvents(
    String workspaceId,
    String runId,
  ) async {
    final data = await _client.call('agent_run_log.readEvents', {
      'workspace_id': workspaceId,
      'run_id': runId,
    });
    final events = ((data['events'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    return (events: events, truncated: data['truncated'] == true);
  }

  /// The run logs belonging to [pipelineRunId] in [workspaceId], newest first.
  Future<List<AgentRunLogDto>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async {
    final data = await _client.call('agent_run_log.forPipelineRun', {
      'workspace_id': workspaceId,
      'pipeline_run_id': pipelineRunId,
    });
    return _logs(data);
  }

  /// The run logs belonging to a specific pipeline step in [workspaceId],
  /// newest first.
  Future<List<AgentRunLogDto>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async {
    final data = await _client.call('agent_run_log.forPipelineStep', {
      'workspace_id': workspaceId,
      'pipeline_run_id': pipelineRunId,
      'pipeline_step_id': pipelineStepId,
    });
    return _logs(data);
  }

  /// Asks the host to stop the live run [runId] of [workspaceId]: it signals
  /// the run's process and settles the run as stopped by a person. The host
  /// decides the end reason, time and cost; a client never writes a run log.
  /// Refused (`not_found`) when the run is not live or has no process.
  Future<void> stop(String workspaceId, String runId) => _client.call(
    'agent_run_log.stop',
    {'workspace_id': workspaceId, 'run_id': runId},
  );

  /// Live run logs for [agentId] in [workspaceId] — a fresh snapshot on every
  /// change, newest first.
  Stream<List<AgentRunLogDto>> watchByAgent(
    String workspaceId,
    String agentId,
  ) => _client
      .subscribe('agent_run_log.watchByAgent', {
        'workspace_id': workspaceId,
        'agent_id': agentId,
      })
      .map(_logs);

  /// Live active (not-yet-completed) run logs for [conversationId] in
  /// [workspaceId].
  Stream<List<AgentRunLogDto>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) => _client
      .subscribe('agent_run_log.watchActiveByConversation', {
        'workspace_id': workspaceId,
        'conversation_id': conversationId,
      })
      .map(_logs);

  /// Live active run logs for the whole SPACE [spaceId] in [workspaceId] —
  /// every conversation in it, threads included.
  Stream<List<AgentRunLogDto>> watchActiveBySpace(
    String workspaceId,
    String spaceId,
  ) => _client
      .subscribe('agent_run_log.watchActiveBySpace', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      })
      .map(_logs);

  /// Live ALL run logs (active + completed) for [conversationId] in
  /// [workspaceId] — the run-tree view (parent dispatch + subagent runs).
  Stream<List<AgentRunLogDto>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) => _client
      .subscribe('agent_run_log.watchByConversation', {
        'workspace_id': workspaceId,
        'conversation_id': conversationId,
      })
      .map(_logs);

  /// [workspaceId] — the run-tree view (parent dispatch + subagent runs).
  Stream<List<AgentRunLogDto>> watchBySpace(
    String workspaceId,
    String spaceId,
  ) => _client
      .subscribe('agent_run_log.watchBySpace', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      })
      .map(_logs);

  /// Live unfinished (pending or running) run logs of [workspaceId], newest
  /// first and bounded by the host.
  Stream<List<AgentRunLogDto>> watchActiveByWorkspace(String workspaceId) =>
      _client
          .subscribe('agent_run_log.watchActiveByWorkspace', {
            'workspace_id': workspaceId,
          })
          .map(_logs);

  /// Live [limit] most recent run logs across ALL workspaces, newest first —
  /// the dashboard's global view.
  Stream<List<AgentRunLogDto>> watchRecent(int limit) => _client
      .subscribe('agent_run_log.watchRecent', {'limit': limit})
      .map(_logs);

  /// One run's recorded activity timeline (the replay read behind a subagent's
  /// activity tab). Scoped by the `workspace_id` the request carries.
  Future<Map<String, dynamic>> getTranscript(String runId) =>
      _client.call('agent_run_log.getTranscript', {'run_id': runId});

  /// Raw run-activity relay frames for [runId] (`seed` / `updates` — see
  /// `runTranscriptEventFromWire` for the typed decode). Completes when the run
  /// reaches a terminal state.
  Stream<Map<String, dynamic>> watchRunTranscript(String runId) => _client
      .subscribeEvents('agent_run_log.watchRunTranscript', {'run_id': runId});

  List<AgentRunLogDto> _logs(Map<String, dynamic> data) =>
      ((data['logs'] as List?) ?? const [])
          .whereType<Map>()
          .map((l) => AgentRunLogDto.fromJson(l.cast<String, dynamic>()))
          .toList();
}
