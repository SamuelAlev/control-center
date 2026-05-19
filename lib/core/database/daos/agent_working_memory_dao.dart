import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/agent_working_memory.dart';
import 'package:drift/drift.dart';

part 'agent_working_memory_dao.g.dart';

@DriftAccessor(tables: [AgentWorkingMemoryTable])
/// Data access for agent working memory.
class AgentWorkingMemoryDao extends DatabaseAccessor<AppDatabase>
    with _$AgentWorkingMemoryDaoMixin {
  /// Creates an [AgentWorkingMemoryDao].
  AgentWorkingMemoryDao(super.attachedDatabase);

  /// Watches working memory for a specific agent.
  Stream<AgentWorkingMemoryTableData?> watchByAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(agentWorkingMemoryTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.agentId.equals(agentId),
            ))
          .watchSingleOrNull();

  /// Reads working memory for a specific agent.
  Future<AgentWorkingMemoryTableData?> getByAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(agentWorkingMemoryTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.agentId.equals(agentId),
            ))
          .getSingleOrNull();

  /// Watches all working memory entries in a workspace.
  Stream<List<AgentWorkingMemoryTableData>> watchByWorkspace(
    String workspaceId,
  ) =>
      (select(agentWorkingMemoryTable)
            ..where((t) => t.workspaceId.equals(workspaceId)))
          .watch();

  /// Inserts or updates a working memory entry.
  Future<void> upsert(AgentWorkingMemoryTableCompanion entry) =>
      into(agentWorkingMemoryTable).insertOnConflictUpdate(entry);
}
