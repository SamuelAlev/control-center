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
/// exception, for the reconciler). Deleting the workspace cascades its goals.
@TableIndex(name: 'idx_agent_goal_runs_workspaceId', columns: {#workspaceId})
@TableIndex(
  name: 'idx_agent_goal_runs_agent_status',
  columns: {#workspaceId, #agentId, #status},
)
class AgentGoalRunsTable extends Table {
  /// Unique goal identifier.
  TextColumn get id => text()();

  /// Owning workspace (the isolation boundary).
  TextColumn get workspaceId => text()();

  /// Channel the goal runs in (progress + control messages land here).
  TextColumn get channelId => text()();

  /// Conversation (stream) the runs see and post into.
  TextColumn get conversationId => text()();

  /// Agent pursuing the goal. No FK: agents are not hard-deleted
  /// workspace-cascade style here and a dangling id just means the goal can
  /// never dispatch again (the reconciler's per-run dispatch is
  /// workspace-scoped and fails safe).
  TextColumn get agentId => text()();

  /// The objective, verbatim (the `/goal` or `/loop` body).
  TextColumn get userText => text()();

  /// Which command spawned the goal: `goal` or `loop`.
  TextColumn get kind => text()();

  /// Lifecycle status: `active`, `paused`, `completed`, `failed`,
  /// `cancelled`, or `budget_exhausted`.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Wall-clock budget: no new run is dispatched past this instant. NULL
  /// (the default) means no deadline — the goal runs until completed,
  /// stopped, or its cost cap bites.
  DateTimeColumn get deadlineAt => dateTime().nullable()();

  /// Hard cost cap for the whole goal, in cents (priced models only).
  IntColumn get costCapCents => integer()();

  /// Cost accumulated across all runs so far, in cents.
  IntColumn get costCents => integer().withDefault(const Constant(0))();

  /// Run budget: no more than this many runs are dispatched for the goal.
  /// NULL (the default) means no iteration cap — the cost cap is the budget
  /// that bounds the loop.
  IntColumn get maxRuns => integer().nullable()();

  /// Runs dispatched so far.
  IntColumn get runCount => integer().withDefault(const Constant(0))();

  /// Run-log id of the currently in-flight run, when known. Correlates
  /// `AgentRunCompleted` events to this goal; null between runs.
  TextColumn get activeRunId => text().nullable()();

  /// Consecutive failed runs; reset on any successful run. Drives the
  /// give-up threshold and the re-dispatch backoff.
  IntColumn get consecutiveFailures =>
      integer().withDefault(const Constant(0))();

  /// Human who started the goal, when known.
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
