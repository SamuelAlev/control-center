import 'package:control_center/core/database/tables/agents.dart';
import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

/// Drift table that records every agent execution (a single "run").
@TableIndex(name: 'idx_agent_run_logs_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_agent_run_logs_agentId', columns: {#agentId})
@TableIndex(name: 'idx_agent_run_logs_ticket', columns: {#ticketId})
@TableIndex(name: 'idx_agent_run_logs_status', columns: {#status})
@TableIndex(name: 'idx_agent_run_logs_pipelineRun', columns: {#pipelineRunId})
class AgentRunLogsTable extends Table {
  /// Id.
  TextColumn get id => text()();

  /// References the agent that performed the run.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// References the workspace the run was executed in.
  TextColumn get workspaceId => text().nullable().references(
    WorkspacesTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

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

  /// OS process id of the running agent, if any.
  IntColumn get pid => integer().nullable()();

  /// Absolute path to the NDJSON run-log file on disk, if any.
  TextColumn get logPath => text().nullable()();

  /// Input tokens consumed during this run.
  IntColumn get inputTokens => integer().withDefault(const Constant(0))();

  /// Output tokens generated during this run.
  IntColumn get outputTokens => integer().withDefault(const Constant(0))();

  /// Estimated cost in US cents for this run.
  IntColumn get estimatedCostCents =>
      integer().withDefault(const Constant(0))();

  /// Liveness classification of the run outcome.
  TextColumn get livenessClass => text().nullable()();

  /// Error family for failed runs (transient_upstream, sandbox_infrastructure, etc.).
  TextColumn get errorFamily => text().nullable()();

  /// Structured error code from the adapter (e.g. `rate_limit_error`,
  /// `relay_crash`), when the backend reported one. Drives deterministic
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

  /// Run ID this run is retrying, if applicable.
  TextColumn get retryOfRunId => text().nullable()();

  /// Retry attempt number (0 = initial run).
  IntColumn get retryAttempt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
