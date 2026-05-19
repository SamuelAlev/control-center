import 'package:cc_persistence/database/tables/agents.dart';
import 'package:drift/drift.dart';

/// Drift table that records every agent execution (a single "run").
@TableIndex(name: 'idx_agent_run_logs_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_agent_run_logs_agentId', columns: {#agentId})
@TableIndex(name: 'idx_agent_run_logs_ticket', columns: {#ticketId})
@TableIndex(name: 'idx_agent_run_logs_status', columns: {#status})
@TableIndex(name: 'idx_agent_run_logs_pipelineRun', columns: {#pipelineRunId})
@TableIndex(name: 'idx_agent_run_logs_parentRun', columns: {#parentRunId})
class AgentRunLogsTable extends Table {
  /// Id.
  TextColumn get id => text()();

  /// References the agent that performed the run.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// References the workspace the run was executed in.
  TextColumn get workspaceId => text().nullable()();

  /// References the channel tied to this run.
  TextColumn get conversationId => text().nullable()();

  /// References the ticket this run is executing, if any.
  TextColumn get ticketId => text().nullable()();

  /// References the channel this run is associated with, if any.
  TextColumn get channelId => text().nullable()();

  /// When the run started.
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();

  /// When the run finished, or null if still running.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Run status: pending, running, completed, or error.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Human-readable summary of the run outcome.
  TextColumn get summary => text().nullable()();

  /// Name of the inference adapter used.
  TextColumn get adapter => text().nullable()();

  /// ID of the language model used for this run, if known.
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

  /// Estimated cost in US cents for this run.
  IntColumn get estimatedCostCents =>
      integer().withDefault(const Constant(0))();

  /// Cost in US cents rolled up from this run's subagent (child) runs, summed
  /// as each child completes. `estimatedCostCents + childCostCents` is the
  /// run's total spend including everything it delegated. Zero for leaf runs.
  IntColumn get childCostCents => integer().withDefault(const Constant(0))();

  /// The role this run played in the agent tree for per-role cost attribution:
  /// `main` | `sub` | `advisor`. Nullable; null/legacy rows attribute to main.
  TextColumn get agentRole => text().nullable()();

  /// Total wall-clock duration of the run in milliseconds, when measured.
  /// Drives the observability dashboard's avg-latency + tokens/sec metrics.
  IntColumn get durationMs => integer().nullable()();

  /// Time from run start to first output token in milliseconds, when measured.
  /// Drives the observability dashboard's time-to-first-token metric.
  IntColumn get timeToFirstTokenMs => integer().nullable()();

  /// Liveness classification of the run outcome.
  TextColumn get livenessClass => text().nullable()();

  /// Error family for failed runs (transient_upstream, sandbox_infrastructure, etc.).
  TextColumn get errorFamily => text().nullable()();

  /// Structured error code from the adapter (e.g. `rate_limit_error`,
  /// `overloaded_error`), when the backend reported one. Drives deterministic
  /// failure classification ahead of the regex fallback.
  TextColumn get errorCode => text().nullable()();

  /// Pipeline run this agent run belongs to, when dispatched from a pipeline
  /// step. Indexed so cost/observability can roll up exactly per run.
  TextColumn get pipelineRunId => text().nullable()();

  /// Pipeline step-run this agent run belongs to (for per-step cost rollup).
  TextColumn get pipelineStepRunId => text().nullable()();

  /// Number of memory-read MCP calls made during this run (telemetry).
  IntColumn get memoryReads => integer().withDefault(const Constant(0))();

  /// Number of memory-write MCP calls made during this run (telemetry).
  IntColumn get memoryWrites => integer().withDefault(const Constant(0))();

  /// Number of code-graph MCP calls made during this run (telemetry).
  IntColumn get codeGraphCalls => integer().withDefault(const Constant(0))();

  /// When the agent last produced output.
  DateTimeColumn get lastOutputAt => dateTime().nullable()();

  /// Continuation summary written after run completion.
  TextColumn get continuationSummary => text().nullable()();

  /// Serialized full prompt context for debugging.
  TextColumn get contextSnapshotJson => text().nullable()();

  /// JSON schema the run's `submit_output` payload should conform to (the
  /// pipeline output contract, ported from tickets).
  TextColumn get expectedOutputSchema => text().nullable()();

  /// How strictly `submit_output` validates against [expectedOutputSchema]
  /// (`strict` | `permissive`).
  TextColumn get outputContractMode =>
      text().nullable().withDefault(const Constant('strict'))();

  /// JSON output produced by the agent via `submit_output`. Null until done.
  TextColumn get outputJson => text().nullable()();

  /// How many times `submit_output` has rejected a non-conforming payload on
  /// this run (the strict-mode 3-strike cap). Persisted so it survives a
  /// crash mid-retry.
  IntColumn get outputRejections => integer().withDefault(const Constant(0))();

  /// Run ID this run is retrying, if applicable.
  TextColumn get retryOfRunId => text().nullable()();

  /// Retry attempt number (0 = initial run).
  IntColumn get retryAttempt => integer().withDefault(const Constant(0))();

  /// Run ID of the parent run that spawned this one as an ephemeral subagent
  /// (the `task` tool). Null for top-level runs. Distinct from [retryOfRunId],
  /// which is the retry relationship — this is the subagent-parentage tree that
  /// the conversation run-tree UI renders. Indexed for fast child lookup.
  TextColumn get parentRunId => text().nullable()();

  /// Id of the parent run's `task` tool call that spawned this subagent run.
  /// Null for top-level runs (and for subagents spawned outside a tool call).
  ///
  /// [parentRunId] gives the tree; this pins the child to the exact tool row in
  /// the parent's transcript, so the `task` cell rendered in the parent's
  /// timeline can open the child's own activity. Correlating by parent + label +
  /// time instead would mis-link concurrent `task` calls.
  TextColumn get spawnToolCallId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
