import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';

/// Repository for per-agent working memory entries.
abstract class AgentWorkingMemoryRepository {
  /// Watches a single agent's working memory.
  Stream<AgentWorkingMemory?> watchByAgent(String workspaceId, String agentId);
  /// Fetches a single agent's working memory.
  Future<AgentWorkingMemory?> getByAgent(String workspaceId, String agentId);
  /// Watches all working memories in a workspace.
  Stream<List<AgentWorkingMemory>> watchByWorkspace(String workspaceId);
  /// Inserts or updates a working memory entry.
  Future<void> upsert(AgentWorkingMemory memory);
}
