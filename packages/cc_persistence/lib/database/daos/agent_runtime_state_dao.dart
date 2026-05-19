import 'package:cc_persistence/database/tables/agent_runtime_state_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'agent_runtime_state_dao.g.dart';

/// Data access for per-agent runtime liveness (heartbeats). Every read filters
/// by `workspaceId`.
@DriftAccessor(tables: [AgentRuntimeStateTable])
class AgentRuntimeStateDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$AgentRuntimeStateDaoMixin {
  /// Creates an [AgentRuntimeStateDao].
  AgentRuntimeStateDao(super.db);

  /// Watches all runtime-state rows for [workspaceId].
  Stream<List<AgentRuntimeStateTableData>> watchByWorkspace(
    String workspaceId,
  ) => (select(
    agentRuntimeStateTable,
  )..where((t) => t.workspaceId.equals(workspaceId))).watch();

  /// Returns all runtime-state rows for [workspaceId].
  Future<List<AgentRuntimeStateTableData>> getByWorkspace(String workspaceId) =>
      (select(
        agentRuntimeStateTable,
      )..where((t) => t.workspaceId.equals(workspaceId))).get();

  /// Returns the runtime state for [agentId] within [workspaceId], or null.
  Future<AgentRuntimeStateTableData?> getForAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(agentRuntimeStateTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) & t.agentId.equals(agentId),
          ))
          .getSingleOrNull();

  /// Returns **all** runtime-state rows across every workspace.
  ///
  /// This workspace's runtime-state rows, for the runtime-health GC sweeper.
  ///
  /// The sweeper reaps stale rows across the install by visiting each
  /// workspace's database in turn.
  Future<List<AgentRuntimeStateTableData>> getAll() =>
      select(agentRuntimeStateTable).get();

  /// Inserts or updates a runtime-state row.
  Future<void> upsert(AgentRuntimeStateTableCompanion entry) =>
      into(agentRuntimeStateTable).insertOnConflictUpdate(entry);

  /// Deletes the runtime state for [agentId] within [workspaceId]. Returns rows
  /// deleted.
  Future<int> deleteForAgent(String workspaceId, String agentId) =>
      (delete(agentRuntimeStateTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) & t.agentId.equals(agentId),
          ))
          .go();
}
