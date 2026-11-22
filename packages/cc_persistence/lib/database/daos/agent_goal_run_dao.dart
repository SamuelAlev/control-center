import 'package:cc_persistence/database/tables/agent_goal_runs_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'agent_goal_run_dao.g.dart';

/// Data access for durable supervised goals (`/goal`).
///
/// Every read filters by `workspaceId` — an id-only query would leak across
/// workspaces. The one exception is [listActive], documented inline.
@DriftAccessor(tables: [AgentGoalRunsTable])
class AgentGoalRunDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$AgentGoalRunDaoMixin {
  /// Creates an [AgentGoalRunDao].
  AgentGoalRunDao(super.db);

  /// Returns the goal [id] within [workspaceId], or null.
  Future<AgentGoalRunsTableData?> getById(String workspaceId, String id) =>
      (select(agentGoalRunsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Lists every goal in [workspaceId], newest first.
  Future<List<AgentGoalRunsTableData>> listByWorkspace(String workspaceId) =>
      (select(agentGoalRunsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Watches every goal in [workspaceId], newest first.
  Stream<List<AgentGoalRunsTableData>> watchByWorkspace(String workspaceId) =>
      (select(agentGoalRunsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Lists every goal still `active` across ALL workspaces, oldest first.
  ///
  /// This workspace's active goals.
  ///
  /// The supervisor's startup reconciler resumes every active goal on the
  /// install by asking each workspace's database in turn.
  Future<List<AgentGoalRunsTableData>> listActive() =>
      (select(agentGoalRunsTable)
            ..where((t) => t.status.equals('active'))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// Returns the agent's currently active goal in [workspaceId], or null.
  ///
  /// At most one goal per agent is active (`uq_agent_goal_runs_active_agent`),
  /// which lets the `complete_goal` tool resolve "my goal" without an id.
  Future<AgentGoalRunsTableData?> getActiveForAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(agentGoalRunsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.agentId.equals(agentId) &
                t.status.equals('active'),
          ))
          .getSingleOrNull();

  /// The active and paused goals in [workspaceId] holding something,
  /// narrowed to [hold] (a `GoalHold` wire name), oldest first.
  Future<List<AgentGoalRunsTableData>> listHeld(
    String workspaceId, {
    String? hold,
  }) =>
      (select(agentGoalRunsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.status.isIn(const ['active', 'paused']) &
                  (hold == null ? t.hold.isNotNull() : t.hold.equals(hold)),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  /// The goals in [workspaceId] a step of [pipelineRunId] started, oldest
  /// first (`idx_agent_goal_runs_pipeline_run`).
  Future<List<AgentGoalRunsTableData>> listForPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) =>
      (select(agentGoalRunsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.pipelineRunId.equals(pipelineRunId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// The goal in [workspaceId] whose active segment is [runId], or null
  /// (`idx_agent_goal_runs_active_run`).
  Future<AgentGoalRunsTableData?> getByActiveRunId(
    String workspaceId,
    String runId,
  ) =>
      (select(agentGoalRunsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.activeRunId.equals(runId),
            )
            ..limit(1))
          .getSingleOrNull();

  /// Inserts or replaces the goal (keyed by id; workspace comes from the row).
  Future<void> upsert(AgentGoalRunsTableCompanion entry) =>
      into(agentGoalRunsTable).insertOnConflictUpdate(entry);

  /// Writes [entry] to goal [id] of [workspaceId]. Returns whether a row was
  /// written. Unconditional: the repository's `replaceIf` calls it inside the
  /// transaction that compared the stored row first.
  Future<bool> replace(
    String workspaceId,
    String id,
    AgentGoalRunsTableCompanion entry,
  ) async {
    final written = await (update(
      agentGoalRunsTable,
    )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).write(
      entry,
    );
    return written > 0;
  }

  /// Adds [costMicros] and one run to goal [id] and clears its active
  /// segment, only while that segment is [runId]. Returns whether it did.
  Future<bool> recordSegmentEnd(
    String workspaceId,
    String id, {
    required String runId,
    required int costMicros,
    required DateTime at,
  }) async {
    final t = agentGoalRunsTable;
    final written =
        await (update(t)..where(
              (r) =>
                  r.workspaceId.equals(workspaceId) &
                  r.id.equals(id) &
                  r.activeRunId.equals(runId),
            ))
            .write(
              AgentGoalRunsTableCompanion.custom(
                costMicros: t.costMicros + Variable<int>(costMicros),
                runCount: t.runCount + const Variable<int>(1),
                activeRunId: const Variable<String>(null),
                updatedAt: Variable<DateTime>(at),
              ),
            );
    return written > 0;
  }
}
