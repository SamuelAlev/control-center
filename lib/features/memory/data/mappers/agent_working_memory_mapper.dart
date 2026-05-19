import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/domain/entities/agent_working_memory.dart';

/// Maps [db.AgentWorkingMemoryTableData] rows to [AgentWorkingMemory] domain entities.
class AgentWorkingMemoryMapper {
  /// Creates a const [AgentWorkingMemoryMapper].
  const AgentWorkingMemoryMapper();

  /// Converts a [db.AgentWorkingMemoryTableData] row to an [AgentWorkingMemory].
  AgentWorkingMemory toDomain(db.AgentWorkingMemoryTableData row) {
    return AgentWorkingMemory(
      id: row.id,
      workspaceId: row.workspaceId,
      agentId: row.agentId,
      content: row.content,
      updatedAt: row.updatedAt,
    );
  }
}
