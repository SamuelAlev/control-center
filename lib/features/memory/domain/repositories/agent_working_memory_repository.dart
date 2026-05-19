import 'package:control_center/core/domain/entities/agent_working_memory.dart';

abstract class AgentWorkingMemoryRepository {
  Stream<AgentWorkingMemory?> watchByAgent(String workspaceId, String agentId);
  Future<AgentWorkingMemory?> getByAgent(String workspaceId, String agentId);
  Stream<List<AgentWorkingMemory>> watchByWorkspace(String workspaceId);
  Future<void> upsert(AgentWorkingMemory memory);
}
