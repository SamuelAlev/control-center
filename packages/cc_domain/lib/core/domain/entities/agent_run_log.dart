import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';

/// Current state of an agent execution.
enum RunStatus {
  /// Run is queued / waiting to start; process not yet spawned.
  pending,
  /// Run is currently in progress.
  running,
  /// Run finished successfully.
  completed,
  /// Run ended with an error.
  error;
}

/// Error family classification for failed runs.
enum RunErrorFamily {
  /// Upstream / remote service issue (API rate limits, auth, etc.).
  transientUpstream,
  /// Local sandbox / process infrastructure failure.
  sandboxInfrastructure,
  /// Budget exhausted.
  budgetExceeded,
  /// Process died or was killed externally.
  processLost,
  /// Agent produced no output for extended period.
  silentRun,
  /// Unknown / unclassified.
  unknown;

  /// Parses a string into a [RunErrorFamily], defaulting to [unknown] for
  /// unrecognized values.
  static RunErrorFamily tryParse(String? value) {
    if (value == null) {
      return unknown;
    }
    return RunErrorFamily.values.where(
      (v) => v.name.toLowerCase() == value.toLowerCase(),
    ).firstOrNull ?? unknown;
  }
}

/// Liveness classification of a run.
enum RunLiveness {
  /// Run is producing output, healthy.
  alive,
  /// Run produced terminal output (done/failed/blocked).
  productive,
  /// Run reached its completion status.
  completed,
  /// Run detected a blocker and stopped.
  blocked,
  /// Run produced no useful output.
  empty,
  /// Run appears to be in a loop.
  looping,
  /// Run has failed.
  failed,
  /// Run is stalled (process alive but no recent output).
  stalled,
  /// Run is dead (process not running, no recovery attempted).
  dead;

  /// Parses a string into a [RunLiveness], defaulting to [empty] for
  /// unrecognized values.
  static RunLiveness tryParse(String? value) {
    if (value == null) {
      return RunLiveness.empty;
    }
    return RunLiveness.values.where(
      (v) => v.name == value.toLowerCase(),
    ).firstOrNull ?? RunLiveness.empty;
  }
}

/// Immutable record of a single agent execution.
class AgentRunLog {
  /// Creates a new [AgentRunLog].
  AgentRunLog({
    required this.id,
    required this.agentId,
    this.workspaceId,
    this.conversationId,
    this.ticketId,
    this.channelId,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.summary,
    this.adapter,
    this.pid,
    this.logPath,
    RunCost? cost,
    this.liveness,
    this.errorFamily,
    this.lastOutputAt,
    this.continuationSummary,
    this.contextSnapshotJson,
    this.pipelineRunId,
    this.pipelineStepRunId,
    this.errorCode,
    this.expectedOutputSchema,
    this.outputContractMode = OutputContractMode.strict,
    this.outputJson,
    this.outputRejections = 0,
    RetryMeta? retry,
  })  : cost = cost ?? RunCost.zero,
        retry = retry ?? const RetryMeta(),
        assert(agentId.isNotEmpty, 'AgentRunLog agentId must not be empty');

  /// Unique run log identifier.
  final String id;

  /// Agent that executed the run.
  final String agentId;

  /// Workspace the run was executed in, if any.
  final String? workspaceId;

  /// Conversation tied to this run, if any.
  final String? conversationId;

  /// Ticket this run is executing against, if any.
  final String? ticketId;

  /// Channel this run is associated with, if any.
  final String? channelId;

  /// When the run started (or was scheduled for pending runs).
  final DateTime startedAt;

  /// When the run finished, if it has.
  final DateTime? completedAt;

  /// Current status of the run.
  final RunStatus status;

  /// Human-readable summary of the run outcome.
  final String? summary;

  /// Adapter used for this run, if any.
  final String? adapter;

  /// OS process id, if any.
  final int? pid;

  /// Absolute path to the NDJSON run-log file on disk, if any.
  final String? logPath;

  /// Token usage and cost for this run.
  final RunCost cost;

  /// Liveness classification.
  final RunLiveness? liveness;

  /// Error family for failed runs.
  final RunErrorFamily? errorFamily;

  /// When the agent last produced output.
  final DateTime? lastOutputAt;

  /// Continuation summary written after run completion.
  final String? continuationSummary;

  /// Serialized full prompt context for debugging.
  final String? contextSnapshotJson;

  /// Pipeline run this agent run belongs to, when dispatched from a pipeline.
  final String? pipelineRunId;

  /// Identifies which pipeline step this run served, by the template step id
  /// (the ticket's `pipelineStepId`, equal to `PipelineStepRuns.stepId`). Used
  /// to roll up per-step cost on the run waterfall by grouping run logs that
  /// share the same `pipelineRunId` + `pipelineStepRunId`.
  final String? pipelineStepRunId;

  /// Structured adapter error code (e.g. `rate_limit_error`, `relay_crash`).
  final String? errorCode;
  /// JSON schema the run's `submit_output` payload should conform to (the
  /// pipeline output contract, ported from tickets). Null when the run has no
  /// structured-output contract.
  final Map<String, dynamic>? expectedOutputSchema;

  /// How strictly `submit_output` validates against [expectedOutputSchema].
  /// Only meaningful when a schema is declared.
  final OutputContractMode outputContractMode;

  /// JSON output produced by the agent via `submit_output`. Null until the
  /// agent submits. The pipeline engine harvests this into step state.
  final Map<String, dynamic>? outputJson;

  /// How many times `submit_output` rejected a non-conforming payload on this
  /// run (the strict-mode 3-strike cap).
  final int outputRejections;

  /// Retry metadata (parent run and attempt count).
  final RetryMeta retry;

  /// True while the run is still active.
  bool get isRunning => status == RunStatus.running;

  /// True when the run is pending or running.
  bool get isActive => status == RunStatus.pending || status == RunStatus.running;

  /// True once the run finished successfully.
  bool get isCompleted => status == RunStatus.completed;

  /// True when the run ended in an error state.
  bool get isError => status == RunStatus.error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentRunLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          agentId == other.agentId &&
          workspaceId == other.workspaceId &&
          conversationId == other.conversationId &&
          ticketId == other.ticketId &&
          channelId == other.channelId &&
          startedAt == other.startedAt &&
          completedAt == other.completedAt &&
          status == other.status &&
          summary == other.summary &&
          adapter == other.adapter &&
          pid == other.pid &&
          logPath == other.logPath &&
          cost == other.cost &&
          liveness == other.liveness &&
          errorFamily == other.errorFamily &&
          lastOutputAt == other.lastOutputAt &&
          continuationSummary == other.continuationSummary &&
          contextSnapshotJson == other.contextSnapshotJson &&
          pipelineRunId == other.pipelineRunId &&
          pipelineStepRunId == other.pipelineStepRunId &&
          errorCode == other.errorCode &&
          expectedOutputSchema == other.expectedOutputSchema &&
          outputContractMode == other.outputContractMode &&
          outputJson == other.outputJson &&
          outputRejections == other.outputRejections &&
          retry == other.retry;

  @override
  int get hashCode => Object.hashAll([
    id,
    agentId,
    workspaceId,
    conversationId,
    ticketId,
    channelId,
    startedAt,
    completedAt,
    status,
    summary,
    adapter,
    pid,
    logPath,
    cost,
    liveness,
    errorFamily,
    lastOutputAt,
    continuationSummary,
    contextSnapshotJson,
    pipelineRunId,
    pipelineStepRunId,
    errorCode,
    expectedOutputSchema,
    outputContractMode,
    outputJson,
    outputRejections,
    retry,
  ]);

  /// Copy with.
  AgentRunLog copyWith({
    String? id,
    String? agentId,
    String? workspaceId,
    String? conversationId,
    String? ticketId,
    String? channelId,
    DateTime? startedAt,
    DateTime? completedAt,
    bool removeCompletedAt = false,
    RunStatus? status,
    String? summary,
    bool removeSummary = false,
    String? adapter,
    bool removeAdapter = false,
    int? pid,
    bool removePid = false,
    String? logPath,
    bool removeLogPath = false,
    RunCost? cost,
    RunLiveness? liveness,
    bool removeLiveness = false,
    RunErrorFamily? errorFamily,
    bool removeErrorFamily = false,
    DateTime? lastOutputAt,
    bool removeLastOutputAt = false,
    String? continuationSummary,
    bool removeContinuationSummary = false,
    String? contextSnapshotJson,
    bool removeContextSnapshotJson = false,
    String? pipelineRunId,
    String? pipelineStepRunId,
    String? errorCode,
    bool removeErrorCode = false,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode? outputContractMode,
    Map<String, dynamic>? outputJson,
    bool removeOutputJson = false,
    int? outputRejections,
    RetryMeta? retry,
  }) {
    return AgentRunLog(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      ticketId: ticketId ?? this.ticketId,
      channelId: channelId ?? this.channelId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: removeCompletedAt ? null : (completedAt ?? this.completedAt),
      status: status ?? this.status,
      summary: removeSummary ? null : (summary ?? this.summary),
      adapter: removeAdapter ? null : (adapter ?? this.adapter),
      pid: removePid ? null : (pid ?? this.pid),
      logPath: removeLogPath ? null : (logPath ?? this.logPath),
      cost: cost ?? this.cost,
      liveness: removeLiveness ? null : (liveness ?? this.liveness),
      errorFamily: removeErrorFamily ? null : (errorFamily ?? this.errorFamily),
      lastOutputAt: removeLastOutputAt ? null : (lastOutputAt ?? this.lastOutputAt),
      continuationSummary: removeContinuationSummary ? null : (continuationSummary ?? this.continuationSummary),
      contextSnapshotJson: removeContextSnapshotJson ? null : (contextSnapshotJson ?? this.contextSnapshotJson),
      pipelineRunId: pipelineRunId ?? this.pipelineRunId,
      pipelineStepRunId: pipelineStepRunId ?? this.pipelineStepRunId,
      errorCode: removeErrorCode ? null : (errorCode ?? this.errorCode),
      expectedOutputSchema: expectedOutputSchema ?? this.expectedOutputSchema,
      outputJson: removeOutputJson ? null : (outputJson ?? this.outputJson),
      outputRejections: outputRejections ?? this.outputRejections,
      retry: retry ?? this.retry,
    );
  }
}
