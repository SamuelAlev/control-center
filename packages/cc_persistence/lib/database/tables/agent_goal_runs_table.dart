import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// Drift table for durable supervised goals (`/goal`).
///
/// Each row is one objective the goal supervisor keeps dispatching bounded
/// runs (segments) for until verification passes, a person stops it, or a
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
@TableIndex(
  name: 'idx_agent_goal_runs_pipeline_run',
  columns: {#pipelineRunId},
)
// One active goal per agent: each workspace has its own file, so this is one
// per agent per workspace. The repository turns a violation into
// `GoalAlreadyActiveException`.
@TableIndex.sql(
  'CREATE UNIQUE INDEX uq_agent_goal_runs_active_agent '
  "ON agent_goal_runs (agent_id) WHERE status = 'active'",
)
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

  /// The objective, verbatim (the `/goal` body).
  TextColumn get userText => text()();

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

  /// `GoalContract` as a JSON object (criteria, checks, boundaries,
  /// stopWhen); null for a goal started without one.
  TextColumn get contract =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJsonObject(contract))();

  /// What an active or paused goal is waiting on: a `GoalHold` wire name;
  /// null when nothing is held.
  TextColumn get hold =>
      text().nullable()
      // ignore: recursive_getters
      .check(hold.isIn(AgentsStoredValues.goalHold))();

  /// When the hold lifts by itself, when it does.
  DateTimeColumn get holdUntil => dateTime().nullable()();

  /// A short explanation of the hold.
  TextColumn get holdDetail => text().nullable()();

  /// Consecutive segments without observed progress.
  IntColumn get noProgressStreak => integer().withDefault(const Constant(0))();

  /// Verification rounds that failed.
  IntColumn get verificationRounds =>
      integer().withDefault(const Constant(0))();

  /// The worktree fingerprint after the previous segment.
  TextColumn get lastFingerprint => text().nullable()();

  /// A digest of what the previous segment did (at most 128 characters,
  /// enforced by the entity).
  TextColumn get lastActivityDigest => text().nullable()();

  /// `GoalStartRefs` as a JSON object: the commit each checkout of the
  /// conversation was at when the goal started. Null on a goal started
  /// before it was recorded.
  TextColumn get startRef =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJsonObject(startRef))();

  /// How many times the goal parked on a provider limit.
  IntColumn get parkCount => integer().withDefault(const Constant(0))();

  /// Whether every segment starts without the conversation's history.
  BoolColumn get fresh => boolean().withDefault(const Constant(false))();

  /// What a segment's unanswered question does: a `GoalUnattendedPolicy`
  /// wire name.
  TextColumn get unattended => text()
      .check(
        // ignore: recursive_getters
        unattended.isIn(AgentsStoredValues.goalUnattendedPolicy),
      )
      .withDefault(const Constant('wait'))();

  /// The agent that reviews completion claims; null for the space's checker
  /// or the goal's own agent. A value, not a key: a removed checker falls
  /// back to those.
  TextColumn get checkerAgentId => text().nullable()();

  /// The last verification (`GoalVerification`) as a JSON object.
  TextColumn get verification =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJsonObject(verification))();

  /// The pipeline run whose `goal.pursue` step started the goal; null for a
  /// goal a person or an agent started. A value, not a key: the goal reads
  /// a run it no longer finds as ended (`GoalPipelineLink`).
  TextColumn get pipelineRunId => text().nullable()();

  /// The `goal.pursue` step of [pipelineRunId]; set with it.
  TextColumn get pipelineStepId => text().nullable()();

  /// The progress marks the goal has already seen (JSON); a mark seen
  /// before is not progress. Null on a goal that has none yet.
  TextColumn get progressMarks =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJson(progressMarks))();

  /// When the goal was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the goal was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'agent_goal_runs';

  @override
  Set<Column> get primaryKey => {id};
}
