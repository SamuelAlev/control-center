import 'package:cc_persistence/database/tables/agent_goal_runs_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'agent_goal_run_dao.g.dart';

/// Data access for durable supervised goals (`/goal` and `/loop`).
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
  /// The supervisor enforces at most one active goal per agent, which lets
  /// the `complete_goal` tool resolve "my goal" without an id.
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

  /// Inserts or replaces the goal (keyed by id; workspace comes from the row).
  Future<void> upsert(AgentGoalRunsTableCompanion entry) =>
      into(agentGoalRunsTable).insertOnConflictUpdate(entry);
}
