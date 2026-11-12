import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:drift/drift.dart';

/// Drift table for per-agent runtime liveness — one row per agent, carrying the
/// last heartbeat and the agent's self-reported status.
///
/// Heartbeat monitoring tracks whether an agent is alive / idle / stuck via
/// [reportedStatus] + [lastHeartbeatAt]; the derived 4-state runtime health
/// (online / recently-lost / offline / about-to-gc) is computed from
/// [lastHeartbeatAt]'s age, not stored. Rows cascade-delete with their agent.
@TableIndex(
  name: 'idx_agent_runtime_state_current_run',
  columns: {#currentRunId},
)
class AgentRuntimeStateTable extends Table {
  /// Agent this runtime state belongs to (also the primary key).
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Last heartbeat-reported liveness: a `HeartbeatStatus` name.
  TextColumn get reportedStatus => text()
      .check(
        // ignore: recursive_getters
        reportedStatus.isIn(AgentsStoredValues.heartbeatStatus),
      )
      .withDefault(const Constant('offline'))();

  /// When the agent last phoned home, or null if it never has.
  DateTimeColumn get lastHeartbeatAt => dateTime().nullable()();

  /// Run id the agent is currently working under, if any. `SET NULL` when
  /// that run log is deleted.
  TextColumn get currentRunId => text().nullable().references(
    AgentRunLogsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Optional free-form note from the last heartbeat (e.g. what it is doing).
  TextColumn get note => text().nullable()();

  /// When this row was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'agent_runtime_state';

  @override
  Set<Column> get primaryKey => {agentId};
}
