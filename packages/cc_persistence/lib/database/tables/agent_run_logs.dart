import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/tables/pipeline_runs_table.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:cc_persistence/database/tables/tickets_table.dart';
import 'package:drift/drift.dart';

/// Drift table that records every agent execution (a single "run").
///
/// A run log is history: it outlives the conversation, space, ticket and
/// pipeline run it served, and the runs it retried or was spawned by (each of
/// those keys is `SET NULL`). Its per-run children (transcript, call usages,
/// payload) go with it.
///
/// The row holds what lists, filters, sorts and counters read. The large
/// values only a run's detail view or the runtime reads (prompt-context
/// snapshot, output contract and output, verification detail) are in
/// `agent_run_payloads`, so a status or counter write never rewrites them and
/// a list never loads them.
///
/// Every list reads newest first by `(started_at, id)`, so each index a list
/// filters on ends with those two columns and the order comes from the index.
@TableIndex(name: 'idx_agent_run_logs_started', columns: {#startedAt, #id})
@TableIndex(
  name: 'idx_agent_run_logs_agent_started',
  columns: {#agentId, #startedAt, #id},
)
@TableIndex(
  name: 'idx_agent_run_logs_conversation_started',
  columns: {#conversationId, #startedAt, #id},
)
@TableIndex(
  name: 'idx_agent_run_logs_space_started',
  columns: {#spaceId, #startedAt, #id},
)
@TableIndex(
  name: 'idx_agent_run_logs_ticket',
  columns: {#ticketId, #startedAt, #id},
)
@TableIndex(
  name: 'idx_agent_run_logs_status',
  columns: {#status, #startedAt, #id},
)
@TableIndex(
  name: 'idx_agent_run_logs_pipelineRun',
  columns: {#pipelineRunId, #pipelineStepId},
)
// The retention sweep deletes finished runs by status and completion time.
@TableIndex(
  name: 'idx_agent_run_logs_status_completed',
  columns: {#status, #completedAt},
)
@TableIndex(name: 'idx_agent_run_logs_parentRun', columns: {#parentRunId})
@TableIndex(name: 'idx_agent_run_logs_retryOf', columns: {#retryOfRunId})
class AgentRunLogsTable extends Table {
  /// Id.
  TextColumn get id => text()();

  /// The agent that performed the run.
  ///
  /// `CASCADE` because the column is required (`AgentRunLog.agentId` is
  /// non-null), so the run cannot outlive its agent as a `SET NULL` row:
  /// deleting an agent is the confirmed "delete it with its history" act.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// The workspace the run was executed in (this file's workspace).
  TextColumn get workspaceId => text()();

  /// The conversation the run posted into, if any. `SET NULL`: the run
  /// outlives the conversation.
  TextColumn get conversationId => text().nullable().references(
    ConversationsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The ticket this run is executing, if any. `SET NULL`: the run outlives
  /// the ticket.
  TextColumn get ticketId => text().nullable().references(
    TicketsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The space this run is associated with, if any. `SET NULL`: the run
  /// outlives the space.
  TextColumn get spaceId => text().nullable().references(
    SpacesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// When the run started.
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();

  /// When the run finished, or null if still running.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Run status: a `RunStatus` name.
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(AgentsStoredValues.runStatus),
      )
      .withDefault(const Constant('pending'))();

  /// Human-readable summary of the run outcome.
  TextColumn get summary => text().nullable()();

  /// Name of the inference adapter used. Open set: registered adapter ids.
  TextColumn get adapter => text().nullable()();

  /// ID of the language model used for this run, if known. Open set:
  /// provider model ids.
  TextColumn get modelId => text().nullable()();

  /// OS process id of the running agent, if any.
  IntColumn get pid => integer().nullable()();

  /// Absolute path to the NDJSON run-log file on disk, if any.
  TextColumn get logPath => text().nullable()();

  /// Input tokens consumed during this run.
  IntColumn get inputTokens => integer().withDefault(const Constant(0))();

  /// Output tokens generated during this run.
  IntColumn get outputTokens => integer().withDefault(const Constant(0))();

  /// Reasoning / "thinking" output tokens generated during this run.
  IntColumn get thoughtTokens => integer().withDefault(const Constant(0))();

  /// Cache-hit read tokens (discounted by the provider) for this run.
  IntColumn get cachedReadTokens => integer().withDefault(const Constant(0))();

  /// Cache-hit write tokens (discounted by the provider) for this run.
  IntColumn get cachedWriteTokens => integer().withDefault(const Constant(0))();

  /// Exact cost in micro-dollars (1 USD = 1,000,000) for this run, or 0 when
  /// no precise figure was recorded.
  ///
  /// The only money column of a run: a sub-cent priced request still adds to
  /// it, so hundreds of small auxiliary calls sum to what they cost.
  IntColumn get costMicros => integer().withDefault(const Constant(0))();

  /// How the cost was obtained: a `CostBasis` name. Nullable; null reads as
  /// estimated.
  TextColumn get costBasis =>
      text().nullable()
      // ignore: recursive_getters
      .check(costBasis.isIn(AgentsStoredValues.costBasis))();

  /// Cost in micro-dollars rolled up from this run's subagent (child) runs, summed
  /// as each child completes. Zero for leaf runs.
  IntColumn get childCostMicros => integer().withDefault(const Constant(0))();

  /// Reasoning-effort level the run actually executed at, when recorded. Null
  /// means unknown (not "the default"): latency percentiles group by this and
  /// an unknown must form its own bucket. Open set: each adapter names its
  /// own levels.
  TextColumn get effort => text().nullable()();

  /// Caller-assigned task-family label, when recorded. Null means
  /// unclassified. Open set: caller labels.
  TextColumn get taskFamily => text().nullable()();

  /// The adapter's OWN session/thread id for this run, when it has one (e.g. a
  /// Claude CLI session id). Stored as data so the evaluation's resume-vs-fresh
  /// stratum is queryable rather than parseable out of a log line.
  TextColumn get nativeSessionId => text().nullable()();

  /// Whether this run RESUMED [nativeSessionId] rather than starting fresh.
  BoolColumn get resumedNativeSession =>
      boolean().withDefault(const Constant(false))();

  /// JSON array of observed run-stage timings (`RunLatencyProfile.toJson`).
  /// Nullable: a run from before stage instrumentation has no timings at all,
  /// which is unknown rather than zero.
  TextColumn get latencyJson =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJsonArray(latencyJson))();

  /// Independent verification verdict: a `VerificationStatus` wire name.
  /// Nullable; null reads as unverified. Distinct from [status]: a run can
  /// complete and fail verification.
  TextColumn get verificationStatus =>
      text().nullable()
      // ignore: recursive_getters
      .check(verificationStatus.isIn(AgentsStoredValues.verificationStatus))();

  /// The role this run played in the agent tree for per-role cost
  /// attribution: an `AgentRunRole` name. Nullable; null attributes to main.
  TextColumn get agentRole =>
      text().nullable()
      // ignore: recursive_getters
      .check(agentRole.isIn(AgentsStoredValues.agentRunRole))();

  /// Total wall-clock duration of the run in milliseconds, when measured.
  /// Drives the observability dashboard's avg-latency + tokens/sec metrics.
  IntColumn get durationMs => integer().nullable()();

  /// Time from run start to first output token in milliseconds, when measured.
  /// Drives the observability dashboard's time-to-first-token metric.
  IntColumn get timeToFirstTokenMs => integer().nullable()();

  /// Liveness classification of the run outcome: a `RunLiveness` name.
  TextColumn get livenessClass =>
      text().nullable()
      // ignore: recursive_getters
      .check(livenessClass.isIn(AgentsStoredValues.runLiveness))();

  /// Error family for failed runs: a `RunErrorFamily` name.
  TextColumn get errorFamily =>
      text().nullable()
      // ignore: recursive_getters
      .check(errorFamily.isIn(AgentsStoredValues.runErrorFamily))();

  /// Structured error code from the adapter (e.g. `rate_limit_error`,
  /// `overloaded_error`), when the backend reported one. Drives deterministic
  /// failure classification ahead of the regex fallback. Open set: backend
  /// error codes.
  TextColumn get errorCode => text().nullable()();

  /// Pipeline run this agent run belongs to, when dispatched from a pipeline
  /// step. Indexed so cost/observability can roll up exactly per run. `SET
  /// NULL`: the run log (and its spend) outlives a pruned pipeline run.
  TextColumn get pipelineRunId => text().nullable().references(
    PipelineRunsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The TEMPLATE step this agent run served — `PipelineStepRuns.stepId`, not a
  /// step-RUN row id. Runs are grouped by `(pipelineRunId, pipelineStepId)` for
  /// per-step cost rollup and for the pipeline engine's output harvest.
  ///
  /// The name matters: a reader that takes this for a step-RUN id compares it
  /// against a row uuid, which can never match, and renders nothing forever.
  /// No foreign key: a template step id is not a row.
  TextColumn get pipelineStepId => text().nullable()();

  /// Number of memory-read MCP calls made during this run (telemetry).
  IntColumn get memoryReads => integer().withDefault(const Constant(0))();

  /// Number of memory-write MCP calls made during this run (telemetry).
  IntColumn get memoryWrites => integer().withDefault(const Constant(0))();

  /// Number of code-graph MCP calls made during this run (telemetry).
  IntColumn get codeGraphCalls => integer().withDefault(const Constant(0))();

  /// When the agent last produced output.
  DateTimeColumn get lastOutputAt => dateTime().nullable()();

  /// How strictly `submit_output` validates against the run's expected
  /// output schema (`agent_run_payloads.expected_output_schema`): an
  /// `OutputContractMode` name.
  TextColumn get outputContractMode => text()
      .nullable()
      // ignore: recursive_getters
      .check(outputContractMode.isIn(AgentsStoredValues.outputContractMode))
      .withDefault(const Constant('strict'))();

  /// How many times `submit_output` has rejected a non-conforming payload on
  /// this run (the strict-mode 3-strike cap). Persisted so it survives a
  /// crash mid-retry.
  IntColumn get outputRejections => integer().withDefault(const Constant(0))();

  /// Run ID this run is retrying, if applicable. `SET NULL`: a retry
  /// outlives the run it retried.
  TextColumn get retryOfRunId => text().nullable().references(
    AgentRunLogsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Retry attempt number (0 = initial run).
  IntColumn get retryAttempt => integer().withDefault(const Constant(0))();

  /// Run ID of the parent run that spawned this one as an ephemeral subagent
  /// (the `task` tool). Null for top-level runs. Distinct from [retryOfRunId],
  /// which is the retry relationship — this is the subagent-parentage tree that
  /// the conversation run-tree UI renders. Indexed for fast child lookup.
  /// `SET NULL`: a subagent's run outlives its parent's row.
  TextColumn get parentRunId => text().nullable().references(
    AgentRunLogsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Id of the parent run's `task` tool call that spawned this subagent run.
  /// Null for top-level runs (and for subagents spawned outside a tool call).
  ///
  /// [parentRunId] gives the tree; this pins the child to the exact tool row in
  /// the parent's transcript, so the `task` cell rendered in the parent's
  /// timeline can open the child's own activity. Correlating by parent + label +
  /// time instead would mis-link concurrent `task` calls. No foreign key: a
  /// tool call id is not a row.
  TextColumn get spawnToolCallId => text().nullable()();

  @override
  String get tableName => 'agent_run_logs';

  @override
  Set<Column> get primaryKey => {id};
}
