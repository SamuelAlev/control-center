import 'package:control_center/core/database/tables/agents.dart';
import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

/// Drift table that records every agent execution (a single "run").
@TableIndex(name: 'idx_agent_run_logs_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_agent_run_logs_agentId', columns: {#agentId})
@TableIndex(name: 'idx_agent_run_logs_ticket', columns: {#ticketId})
@TableIndex(name: 'idx_agent_run_logs_status', columns: {#status})
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
