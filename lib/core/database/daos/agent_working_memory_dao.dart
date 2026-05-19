import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/agent_working_memory.dart';
import 'package:drift/drift.dart';

part 'agent_working_memory_dao.g.dart';

@DriftAccessor(tables: [AgentWorkingMemoryTable])
class AgentWorkingMemoryDao extends DatabaseAccessor<AppDatabase>
    with _$AgentWorkingMemoryDaoMixin {
  AgentWorkingMemoryDao(super.attachedDatabase);

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

  Stream<List<AgentWorkingMemoryTableData>> watchByWorkspace(
    String workspaceId,
  ) =>
      (select(agentWorkingMemoryTable)
            ..where((t) => t.workspaceId.equals(workspaceId)))
          .watch();

  Future<void> upsert(AgentWorkingMemoryTableCompanion entry) =>
      into(agentWorkingMemoryTable).insertOnConflictUpdate(entry);
}
