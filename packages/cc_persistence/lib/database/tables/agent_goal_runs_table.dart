import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// Drift table for durable supervised goals (`/goal` and `/loop`).
///
/// Each row is one objective the goal supervisor keeps dispatching bounded
/// runs for until the agent declares it complete, a human stops it, or a
/// budget wall (deadline / cost cap / run budget) is hit. Persisted so the
/// objective survives server restarts — the startup reconciler re-dispatches
/// every row still `active`.
///
/// Distinct from the governance `goals` table (the OrgGoal hierarchy) and
/// from `conversation_goals` (the per-conversation working goal). Workspace
/// isolation: [workspaceId] is the boundary and every read filters by it
/// (`AgentGoalRunDao.listActive` is the single documented cross-workspace
/// exception, for the reconciler). A goal goes with its space, its
/// conversation and its agent: without any of them it can never dispatch.
@TableIndex(
  name: 'idx_agent_goal_runs_agent_status',
  columns: {#agentId, #status},
)
@TableIndex(name: 'idx_agent_goal_runs_status', columns: {#status, #createdAt})
@TableIndex(name: 'idx_agent_goal_runs_created', columns: {#createdAt})
@TableIndex(name: 'idx_agent_goal_runs_space', columns: {#spaceId})
@TableIndex(
  name: 'idx_agent_goal_runs_conversation',
  columns: {#conversationId},
)
@TableIndex(name: 'idx_agent_goal_runs_active_run', columns: {#activeRunId})
class AgentGoalRunsTable extends Table {
  /// Unique goal identifier.
  TextColumn get id => text()();

  /// Owning workspace (the isolation boundary).
  TextColumn get workspaceId => text()();

  /// Space the goal runs in (progress + control messages land here).
  TextColumn get spaceId =>
      text().references(SpacesTable, #id, onDelete: KeyAction.cascade)();

  /// Conversation (stream) the runs see and post into.
  TextColumn get conversationId =>
      text().references(ConversationsTable, #id, onDelete: KeyAction.cascade)();

  /// Agent pursuing the goal.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// The objective, verbatim (the `/goal` or `/loop` body).
  TextColumn get userText => text()();

  /// Which command spawned the goal: an `AgentGoalKind` wire name.
  TextColumn get kind => text().check(
    // ignore: recursive_getters
    kind.isIn(AgentsStoredValues.agentGoalKind),
  )();

  /// Lifecycle status: an `AgentGoalStatus` wire name.
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(AgentsStoredValues.agentGoalStatus),
      )
      .withDefault(const Constant('active'))();

  /// Wall-clock budget: no new run is dispatched past this instant. NULL
  /// (the default) means no deadline — the goal runs until completed,
  /// stopped, or its cost cap bites.
  DateTimeColumn get deadlineAt => dateTime().nullable()();

  /// Hard cost cap for the whole goal, in micro-dollars (priced models only).
  ///
  /// Every goal is written with its cap; the default is the goal
  /// supervisor's default cap of 50 USD, which is what a goal written before
  /// the unit was micro-dollars gets (its cents cap is not carried over).
  IntColumn get costCapMicros =>
      integer().withDefault(const Constant(50000000))();

  /// Cost accumulated across all runs so far, in micro-dollars.
  IntColumn get costMicros => integer().withDefault(const Constant(0))();

  /// Run budget: no more than this many runs are dispatched for the goal.
  /// NULL (the default) means no iteration cap — the cost cap is the budget
  /// that bounds the loop.
  IntColumn get maxRuns => integer().nullable()();

  /// Runs dispatched so far.
  IntColumn get runCount => integer().withDefault(const Constant(0))();

  /// Run-log id of the currently in-flight run, when known. Correlates
  /// `AgentRunCompleted` events to this goal; null between runs, and `SET
  /// NULL` when that run log is deleted.
  TextColumn get activeRunId => text().nullable().references(
    AgentRunLogsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Consecutive failed runs; reset on any successful run. Drives the
  /// give-up threshold and the re-dispatch backoff.
  IntColumn get consecutiveFailures =>
      integer().withDefault(const Constant(0))();

  /// Human who started the goal, when known (no foreign key: users live in
  /// `global.db`).
  TextColumn get requestedByUserId => text().nullable()();

  /// The agent's completion summary (set when status becomes completed).
  TextColumn get summary => text().nullable()();

  /// When the goal was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the goal was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'agent_goal_runs';

  @override
  Set<Column> get primaryKey => {id};
}
