part of 'dtos.dart';

/// Agent run log wire DTO — a single agent execution record. Mirrors
/// `agentRunLogToWire` in the host catalog (runs travel one way: no client op
/// writes a run log). Enum fields
/// (`status`, `liveness`, `error_family`, `output_contract_mode`) are encoded
/// as `.name`; timestamps are ISO-8601 strings; the structured-output payloads
/// (`expected_output_schema`, `output_json`) travel as raw JSON maps.
class AgentRunLogDto {
  AgentRunLogDto({
    required this.id,
    required this.agentId,
    this.workspaceId,
    this.conversationId,
    this.ticketId,
    this.spaceId,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.summary,
    this.adapter,
    this.modelId,
    this.pid,
    this.logPath,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.thoughtTokens = 0,
    this.cachedReadTokens = 0,
    this.cachedWriteTokens = 0,
    this.costMicros = 0,
    this.costBasis,
    this.childCostMicros = 0,
    this.effort,
    this.taskFamily,
    this.latency,
    this.verification,
    this.nativeSessionId,
    this.resumedNativeSession = false,
    this.agentRole,
    this.durationMs,
    this.timeToFirstTokenMs,
    this.liveness,
    this.errorFamily,
    this.lastOutputAt,
    this.contextSnapshotJson,
    this.pipelineRunId,
    this.pipelineStepId,
    this.errorCode,
    this.expectedOutputSchema,
    this.outputContractMode = 'strict',
    this.outputJson,
    this.outputRejections = 0,
    this.retryOfRunId,
    this.retryAttempt = 0,
    this.parentRunId,
    this.spawnToolCallId,
    this.endReason,
    this.wakeIds = const [],
    this.requestedByUserId,
    this.wakeReason,
  });

  factory AgentRunLogDto.fromJson(Map<String, dynamic> json) => AgentRunLogDto(
    id: json['id'] as String,
    agentId: json['agent_id'] as String? ?? '',
    workspaceId: json['workspace_id'] as String?,
    conversationId: json['conversation_id'] as String?,
    ticketId: json['ticket_id'] as String?,
    spaceId: json['space_id'] as String?,
    startedAt: json['started_at'] as String? ?? '',
    completedAt: json['completed_at'] as String?,
    status: json['status'] as String? ?? 'pending',
    summary: json['summary'] as String?,
    adapter: json['adapter'] as String?,
    modelId: json['model_id'] as String?,
    pid: (json['pid'] as num?)?.toInt(),
    logPath: json['log_path'] as String?,
    inputTokens: (json['input_tokens'] as num?)?.toInt() ?? 0,
    outputTokens: (json['output_tokens'] as num?)?.toInt() ?? 0,
    thoughtTokens: (json['thought_tokens'] as num?)?.toInt() ?? 0,
    cachedReadTokens: (json['cached_read_tokens'] as num?)?.toInt() ?? 0,
    cachedWriteTokens: (json['cached_write_tokens'] as num?)?.toInt() ?? 0,
    costMicros: (json['cost_micros'] as num?)?.toInt() ?? 0,
    costBasis: json['cost_basis'] as String?,
    childCostMicros: (json['child_cost_micros'] as num?)?.toInt() ?? 0,
    effort: json['effort'] as String?,
    taskFamily: json['task_family'] as String?,
    latency: json['latency'] is List
        ? (json['latency'] as List)
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList()
        : null,
    verification: json['verification'] is Map
        ? (json['verification'] as Map).cast<String, dynamic>()
        : null,
    nativeSessionId: json['native_session_id'] as String?,
    resumedNativeSession: json['resumed_native_session'] as bool? ?? false,
    agentRole: json['agent_role'] as String?,
    durationMs: (json['duration_ms'] as num?)?.toInt(),
    timeToFirstTokenMs: (json['time_to_first_token_ms'] as num?)?.toInt(),
    liveness: json['liveness'] as String?,
    errorFamily: json['error_family'] as String?,
    lastOutputAt: json['last_output_at'] as String?,
    contextSnapshotJson: json['context_snapshot_json'] as String?,
    pipelineRunId: json['pipeline_run_id'] as String?,
    pipelineStepId: json['pipeline_step_id'] as String?,
    errorCode: json['error_code'] as String?,
    expectedOutputSchema: json['expected_output_schema'] is Map
        ? (json['expected_output_schema'] as Map).cast<String, dynamic>()
        : null,
    outputContractMode: json['output_contract_mode'] as String? ?? 'strict',
    outputJson: json['output_json'] is Map
        ? (json['output_json'] as Map).cast<String, dynamic>()
        : null,
    outputRejections: (json['output_rejections'] as num?)?.toInt() ?? 0,
    retryOfRunId: json['retry_of_run_id'] as String?,
    retryAttempt: (json['retry_attempt'] as num?)?.toInt() ?? 0,
    parentRunId: json['parent_run_id'] as String?,
    spawnToolCallId: json['spawn_tool_call_id'] as String?,
    endReason: json['end_reason'] as String?,
    wakeIds: json['wake_ids'] is List
        ? [
            for (final id in json['wake_ids'] as List)
              if (id is String) id,
          ]
        : const [],
    requestedByUserId: json['requested_by_user_id'] as String?,
    wakeReason: json['wake_reason'] as String?,
  );

  final String id;
  final String agentId;
  final String? workspaceId;
  final String? conversationId;
  final String? ticketId;
  final String? spaceId;
  final String startedAt;
  final String? completedAt;
  final String status;
  final String? summary;
  final String? adapter;
  final String? modelId;
  final int? pid;
  final String? logPath;
  final int inputTokens;
  final int outputTokens;
  final int thoughtTokens;
  final int cachedReadTokens;
  final int cachedWriteTokens;

  /// Exact cost in micro-USD when a provider reported one; 0 when unknown.
  final int costMicros;

  /// Wire spelling of `CostBasis`
  /// (`estimated` | `providerReported` | `subscription` | `mixed`).
  final String? costBasis;

  /// Exact cost of the child (subagent) runs in micro-USD.
  final int childCostMicros;

  /// Reasoning-effort tier the run requested, e.g. `low` | `medium` | `high`.
  final String? effort;

  /// Task family the run was classified into (for per-family analytics).
  final String? taskFamily;

  /// `RunLatencyProfile.toJson()` — null/empty when no stage was observed.
  final List<Map<String, dynamic>>? latency;

  /// `RunVerification.toJson()` — null when no verifier ran.
  final Map<String, dynamic>? verification;

  /// The provider/CLI's own session (thread) id this run was bound to; null
  /// when the adapter exposes no native session.
  final String? nativeSessionId;

  /// Whether this run RESUMED [nativeSessionId] rather than starting fresh.
  final bool resumedNativeSession;

  /// Run role for per-role cost attribution: `main` | `sub` | `advisor`.
  final String? agentRole;
  final int? durationMs;
  final int? timeToFirstTokenMs;
  final String? liveness;
  final String? errorFamily;
  final String? lastOutputAt;
  final String? contextSnapshotJson;
  final String? pipelineRunId;
  final String? pipelineStepId;
  final String? errorCode;
  final Map<String, dynamic>? expectedOutputSchema;
  final String outputContractMode;
  final Map<String, dynamic>? outputJson;
  final int outputRejections;
  final String? retryOfRunId;
  final int retryAttempt;

  /// Run id of the parent run that spawned this one as an ephemeral subagent.
  final String? parentRunId;

  /// Id of the parent's `task` tool call that spawned this subagent run.
  final String? spawnToolCallId;

  /// Wire name of `RunEndReason` (`completed` | `error` | `stopped_by_user` |
  /// `budget` | `silence` | `usage_limit` | `server_stopped`); null while the
  /// run is live or when no reason was recorded.
  final String? endReason;

  /// Ids of the wakes this run was started to deliver; empty when nothing
  /// woke it.
  final List<String> wakeIds;

  /// The person the run acts for; null for a run the server started.
  final String? requestedByUserId;

  /// Wire name of the `WakeReason` the run was started with
  /// (`user_message` for a person's own message); null when none.
  final String? wakeReason;

  Map<String, dynamic> toJson() => {
    'id': id,
    'agent_id': agentId,
    'workspace_id': ?workspaceId,
    'conversation_id': ?conversationId,
    'ticket_id': ?ticketId,
    'space_id': ?spaceId,
    'started_at': startedAt,
    'completed_at': ?completedAt,
    'status': status,
    'summary': ?summary,
    'adapter': ?adapter,
    'model_id': ?modelId,
    'pid': ?pid,
    'log_path': ?logPath,
    'input_tokens': inputTokens,
    'output_tokens': outputTokens,
    'thought_tokens': thoughtTokens,
    'cached_read_tokens': cachedReadTokens,
    'cached_write_tokens': cachedWriteTokens,
    'cost_micros': costMicros,
    'cost_basis': ?costBasis,
    'child_cost_micros': childCostMicros,
    'effort': ?effort,
    'task_family': ?taskFamily,
    'latency': ?latency,
    'verification': ?verification,
    'native_session_id': ?nativeSessionId,
    if (resumedNativeSession) 'resumed_native_session': true,
    'agent_role': ?agentRole,
    'duration_ms': ?durationMs,
    'time_to_first_token_ms': ?timeToFirstTokenMs,
    'liveness': ?liveness,
    'error_family': ?errorFamily,
    'last_output_at': ?lastOutputAt,
    'context_snapshot_json': ?contextSnapshotJson,
    'pipeline_run_id': ?pipelineRunId,
    'pipeline_step_id': ?pipelineStepId,
    'error_code': ?errorCode,
    'expected_output_schema': ?expectedOutputSchema,
    'output_contract_mode': outputContractMode,
    'output_json': ?outputJson,
    'output_rejections': outputRejections,
    'retry_of_run_id': ?retryOfRunId,
    'retry_attempt': retryAttempt,
    'parent_run_id': ?parentRunId,
    'spawn_tool_call_id': ?spawnToolCallId,
    'end_reason': ?endReason,
    if (wakeIds.isNotEmpty) 'wake_ids': wakeIds,
    'requested_by_user_id': ?requestedByUserId,
    'wake_reason': ?wakeReason,
  };
}
