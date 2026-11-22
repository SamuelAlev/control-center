import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/observability/domain/run_stage.dart';
import 'package:cc_domain/features/observability/domain/run_verification.dart';

/// Current state of an agent execution.
enum RunStatus {
  /// Run is queued / waiting to start; process not yet spawned.
  pending,

  /// Run is currently in progress.
  running,

  /// Run finished successfully.
  completed,

  /// Run ended with an error.
  error,
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
    return RunErrorFamily.values
            .where((v) => v.name.toLowerCase() == value.toLowerCase())
            .firstOrNull ??
        unknown;
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
    return RunLiveness.values
            .where((v) => v.name == value.toLowerCase())
            .firstOrNull ??
        RunLiveness.empty;
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
    this.spaceId,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.summary,
    this.adapter,
    this.modelId,
    this.pid,
    this.logPath,
    RunCost? cost,
    this.liveness,
    this.errorFamily,
    this.lastOutputAt,
    this.contextSnapshotJson,
    this.pipelineRunId,
    this.pipelineStepId,
    this.errorCode,
    this.expectedOutputSchema,
    this.outputContractMode = OutputContractMode.strict,
    this.outputJson,
    this.outputRejections = 0,
    RetryMeta? retry,
    this.role = AgentRunRole.main,
    this.childCostMicros = 0,
    this.parentRunId,
    this.spawnToolCallId,
    this.effort,
    this.taskFamily,
    this.nativeSessionId,
    this.resumedNativeSession = false,
    RunVerification? verification,
    RunLatencyProfile? latency,
    this.endReason,
    List<String> wakeIds = const [],
    this.requestedByUserId,
    this.wakeReason,
    this.startedByRunId,
  }) : cost = cost ?? RunCost.zero,
       wakeIds = List.unmodifiable(wakeIds),
       retry = retry ?? const RetryMeta(),
       verification = verification ?? RunVerification.none,
       latency = latency ?? RunLatencyProfile.empty {
    if (agentId.isEmpty) {
      throw ArgumentError('AgentRunLog agentId must not be empty');
    }
    if (requestedByUserId != null && requestedByUserId!.isEmpty) {
      throw ArgumentError('AgentRunLog requestedByUserId must not be empty');
    }
    if (startedByRunId != null && startedByRunId!.isEmpty) {
      throw ArgumentError('AgentRunLog startedByRunId must not be empty');
    }
  }

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

  /// Space this run is associated with, if any.
  final String? spaceId;

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

  /// ID of the language model used for this run, if known. Drives the
  /// observability "By model" grouping; falls back to [adapter] when absent.
  final String? modelId;

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

  /// Serialized full prompt context for debugging.
  final String? contextSnapshotJson;

  /// Pipeline run this agent run belongs to, when dispatched from a pipeline.
  final String? pipelineRunId;

  /// Which pipeline step this run served, by the TEMPLATE step id — equal to
  /// `PipelineStepRun.stepId`, and never a step-run row id.
  ///
  /// The engine's output harvest and the per-step cost rollup both group runs
  /// by `pipelineRunId` + this. The name matters: a reader that takes it for a
  /// step-RUN id compares it against a row uuid, which can never match, and
  /// renders nothing forever.
  final String? pipelineStepId;

  /// Structured adapter error code (e.g. `rate_limit_error`, `overloaded_error`).
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

  /// The role this run played in the agent tree (main / sub / advisor), for
  /// per-role cost attribution. Defaults to [AgentRunRole.main]; the dispatch
  /// service maps the registry's `AgentKind` into this when it writes the run.
  final AgentRunRole role;

  /// Exact cost in micro-dollars rolled up from this run's subagent (child) runs,
  /// summed concurrency-safely as each child completes (see
  /// `SubagentCostPropagator`). Zero for leaf runs.
  final int childCostMicros;

  /// Run id of the parent run that spawned this one as an ephemeral subagent
  /// (via the `task` tool). Null for top-level runs. Distinct from
  /// [RetryMeta.parentRunId] (the retry relationship) — this is the subagent
  /// tree the conversation run-tree UI renders.
  final String? parentRunId;

  /// Id of the parent run's `task` tool call that spawned this subagent run.
  /// Null for top-level runs.
  ///
  /// [parentRunId] gives the tree; this pins the child to the exact tool row in
  /// the parent's transcript, so the `task` cell rendered in the parent's
  /// timeline can open this run's own activity. Correlating by parent + label +
  /// time instead would mis-link concurrent `task` calls.
  final String? spawnToolCallId;

  /// Reasoning-effort setting the run actually executed at (`low`/`medium`/
  /// `high`, or an adapter-specific level), when recorded.
  ///
  /// Null means UNKNOWN — a run from before effort was plumbed through, or one
  /// with no effort configured. Latency percentiles group by this, and an
  /// unknown run must form its own bucket rather than being folded into a real
  /// level.
  final String? effort;

  /// Task-family label the run belongs to (the caller's classification), when
  /// recorded. Null means unclassified.
  final String? taskFamily;

  /// The adapter's OWN session/thread id for this run, when it has one (e.g. a
  /// Claude CLI session id).
  ///
  /// Recorded as DATA, not as a debug line: the evaluation's resume-vs-fresh
  /// stratum is derived from stored runs, and lineage that exists only as prose
  /// in a log file cannot be grouped or filtered.
  final String? nativeSessionId;

  /// Whether this run RESUMED [nativeSessionId] rather than starting a fresh
  /// native session.
  final bool resumedNativeSession;

  /// Whether the run's output was independently verified.
  ///
  /// Distinct from [status]: a run can complete and still fail verification, or
  /// complete with no verifier at all. Metrics that count "success" MUST say
  /// which of the two they mean.
  final RunVerification verification;

  /// Observed stage offsets for this run (submitted → verifiedCompletion).
  /// Absent stages are unknown, never zero.
  final RunLatencyProfile latency;

  /// Why the run ended, written with its terminal row. Null while the run is
  /// live, and for a run that ended before end reasons were recorded.
  final RunEndReason? endReason;

  /// Ids of the wakes (`agent_wakes`) this run was started to deliver, in
  /// delivery order. Empty for a run a person or a pipeline started. A wake
  /// whose id is on a run log counts as delivered, so a restart never sends it
  /// again.
  final List<String> wakeIds;

  /// The person the run acts for, recorded with the run row. Null for a run
  /// the server started on its own (a bot run). Server-owned: it decides
  /// whether a recovery after a crash needs that person, so a client never
  /// sets it.
  final String? requestedByUserId;

  /// Why the run was started: the dispatch-time `WakeContext.wakeReason`
  /// (`userMessage` for a person's own message), written with the run row and
  /// never changed. Null for a run started without a wake context (a
  /// subagent). Server-owned: after a restart it tells a person's run from a
  /// wake-started one, which [wakeIds] cannot (a person's run also drains
  /// wakes pushed into its lane).
  final WakeReason? wakeReason;

  /// The run whose tool call started this run by a direct dispatch
  /// (`WakeContext.startedByRunId`: a reviewer `dispatch_reviewers` started,
  /// a team leader an agent's `assign_ticket` routed to), written with the
  /// run row and never changed. Null for any other run. Not a parent link:
  /// it nests nothing, changes no cost rollup, and the run settles like any
  /// other. Server-owned: the wake rules read it to keep such a run in the
  /// starting run's chain of wakes.
  final String? startedByRunId;

  /// True when the run finished successfully AND an independent verifier
  /// accepted the output.
  bool get isVerifiedSuccess =>
      status == RunStatus.completed && verification.isVerifiedSuccess;

  /// Total cost in micro-dollars for this run including propagated subagent cost.
  int get totalCostMicrosWithChildren => cost.costMicros + childCostMicros;

  /// True while the run is still active.
  bool get isRunning => status == RunStatus.running;

  /// True when the run is pending or running.
  bool get isActive =>
      status == RunStatus.pending || status == RunStatus.running;

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
          spaceId == other.spaceId &&
          startedAt == other.startedAt &&
          completedAt == other.completedAt &&
          status == other.status &&
          summary == other.summary &&
          adapter == other.adapter &&
          modelId == other.modelId &&
          pid == other.pid &&
          logPath == other.logPath &&
          cost == other.cost &&
          liveness == other.liveness &&
          errorFamily == other.errorFamily &&
          lastOutputAt == other.lastOutputAt &&
          contextSnapshotJson == other.contextSnapshotJson &&
          pipelineRunId == other.pipelineRunId &&
          pipelineStepId == other.pipelineStepId &&
          errorCode == other.errorCode &&
          expectedOutputSchema == other.expectedOutputSchema &&
          outputContractMode == other.outputContractMode &&
          outputJson == other.outputJson &&
          outputRejections == other.outputRejections &&
          retry == other.retry &&
          role == other.role &&
          childCostMicros == other.childCostMicros &&
          parentRunId == other.parentRunId &&
          spawnToolCallId == other.spawnToolCallId &&
          effort == other.effort &&
          taskFamily == other.taskFamily &&
          nativeSessionId == other.nativeSessionId &&
          resumedNativeSession == other.resumedNativeSession &&
          verification == other.verification &&
          latency == other.latency &&
          endReason == other.endReason &&
          _sameIds(wakeIds, other.wakeIds) &&
          requestedByUserId == other.requestedByUserId &&
          wakeReason == other.wakeReason &&
          startedByRunId == other.startedByRunId;

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    agentId,
    workspaceId,
    conversationId,
    ticketId,
    spaceId,
    startedAt,
    completedAt,
    status,
    summary,
    adapter,
    modelId,
    pid,
    logPath,
    cost,
    liveness,
    errorFamily,
    lastOutputAt,
    contextSnapshotJson,
    pipelineRunId,
    pipelineStepId,
    errorCode,
    expectedOutputSchema,
    outputContractMode,
    outputJson,
    outputRejections,
    retry,
    role,
    childCostMicros,
    parentRunId,
    spawnToolCallId,
    effort,
    taskFamily,
    nativeSessionId,
    resumedNativeSession,
    verification,
    latency,
    endReason,
    Object.hashAll(wakeIds),
    requestedByUserId,
    wakeReason,
    startedByRunId,
  ]);

  /// Copy with.
  AgentRunLog copyWith({
    String? id,
    String? agentId,
    String? workspaceId,
    String? conversationId,
    String? ticketId,
    String? spaceId,
    DateTime? startedAt,
    DateTime? completedAt,
    bool removeCompletedAt = false,
    RunStatus? status,
    String? summary,
    bool removeSummary = false,
    String? adapter,
    bool removeAdapter = false,
    String? modelId,
    bool removeModelId = false,
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
    String? contextSnapshotJson,
    bool removeContextSnapshotJson = false,
    String? pipelineRunId,
    String? pipelineStepId,
    String? errorCode,
    bool removeErrorCode = false,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode? outputContractMode,
    Map<String, dynamic>? outputJson,
    bool removeOutputJson = false,
    int? outputRejections,
    RetryMeta? retry,
    AgentRunRole? role,
    int? childCostMicros,
    String? parentRunId,
    String? spawnToolCallId,
    String? effort,
    bool removeEffort = false,
    String? taskFamily,
    bool removeTaskFamily = false,
    String? nativeSessionId,
    bool removeNativeSessionId = false,
    bool? resumedNativeSession,
    RunVerification? verification,
    RunLatencyProfile? latency,
    RunEndReason? endReason,
    bool removeEndReason = false,
    List<String>? wakeIds,
    String? requestedByUserId,
    bool removeRequestedByUserId = false,
    WakeReason? wakeReason,
  }) {
    return AgentRunLog(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      ticketId: ticketId ?? this.ticketId,
      spaceId: spaceId ?? this.spaceId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: removeCompletedAt ? null : (completedAt ?? this.completedAt),
      status: status ?? this.status,
      summary: removeSummary ? null : (summary ?? this.summary),
      adapter: removeAdapter ? null : (adapter ?? this.adapter),
      modelId: removeModelId ? null : (modelId ?? this.modelId),
      pid: removePid ? null : (pid ?? this.pid),
      logPath: removeLogPath ? null : (logPath ?? this.logPath),
      cost: cost ?? this.cost,
      liveness: removeLiveness ? null : (liveness ?? this.liveness),
      errorFamily: removeErrorFamily ? null : (errorFamily ?? this.errorFamily),
      lastOutputAt: removeLastOutputAt
          ? null
          : (lastOutputAt ?? this.lastOutputAt),
      contextSnapshotJson: removeContextSnapshotJson
          ? null
          : (contextSnapshotJson ?? this.contextSnapshotJson),
      pipelineRunId: pipelineRunId ?? this.pipelineRunId,
      pipelineStepId: pipelineStepId ?? this.pipelineStepId,
      errorCode: removeErrorCode ? null : (errorCode ?? this.errorCode),
      expectedOutputSchema: expectedOutputSchema ?? this.expectedOutputSchema,
      outputContractMode: outputContractMode ?? this.outputContractMode,
      outputJson: removeOutputJson ? null : (outputJson ?? this.outputJson),
      outputRejections: outputRejections ?? this.outputRejections,
      retry: retry ?? this.retry,
      role: role ?? this.role,
      childCostMicros: childCostMicros ?? this.childCostMicros,
      parentRunId: parentRunId ?? this.parentRunId,
      spawnToolCallId: spawnToolCallId ?? this.spawnToolCallId,
      effort: removeEffort ? null : (effort ?? this.effort),
      taskFamily: removeTaskFamily ? null : (taskFamily ?? this.taskFamily),
      nativeSessionId: removeNativeSessionId
          ? null
          : (nativeSessionId ?? this.nativeSessionId),
      resumedNativeSession: resumedNativeSession ?? this.resumedNativeSession,
      verification: verification ?? this.verification,
      latency: latency ?? this.latency,
      endReason: removeEndReason ? null : (endReason ?? this.endReason),
      wakeIds: wakeIds ?? this.wakeIds,
      requestedByUserId: removeRequestedByUserId
          ? null
          : (requestedByUserId ?? this.requestedByUserId),
      wakeReason: wakeReason ?? this.wakeReason,
      startedByRunId: startedByRunId,
    );
  }
}
