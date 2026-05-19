import 'package:cc_persistence/database/tables/agents.dart';
import 'package:drift/drift.dart';

/// Drift table for per-agent runtime liveness — one row per agent, carrying the
/// last heartbeat and the agent's self-reported status.
///
/// Heartbeat monitoring tracks whether an agent is alive / idle / stuck via
/// [reportedStatus] + [lastHeartbeatAt]; the derived 4-state runtime health
/// (online / recently-lost / offline / about-to-gc) is computed from
/// [lastHeartbeatAt]'s age, not stored. Rows cascade-delete with their agent.
@TableIndex(
  name: 'idx_agent_runtime_state_workspaceId',
  columns: {#workspaceId},
)
class AgentRuntimeStateTable extends Table {
  /// Agent this runtime state belongs to (also the primary key).
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Last heartbeat-reported liveness: `alive`, `idle`, `stuck`, or `offline`.
  TextColumn get reportedStatus =>
      text().withDefault(const Constant('offline'))();

  /// When the agent last phoned home, or null if it never has.
  DateTimeColumn get lastHeartbeatAt => dateTime().nullable()();

  /// Run id the agent is currently working under, if any.
  TextColumn get currentRunId => text().nullable()();

  /// Optional free-form note from the last heartbeat (e.g. what it is doing).
  TextColumn get note => text().nullable()();

  /// When this row was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'agent_runtime_state';

  @override
  Set<Column> get primaryKey => {agentId};
}
