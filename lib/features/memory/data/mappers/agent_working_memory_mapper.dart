import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/domain/entities/agent_working_memory.dart';

class AgentWorkingMemoryMapper {
  const AgentWorkingMemoryMapper();

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
