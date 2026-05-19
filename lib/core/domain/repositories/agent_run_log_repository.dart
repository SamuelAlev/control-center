import 'package:control_center/core/domain/entities/agent_run_log.dart';

/// Agent run log repository.
abstract class AgentRunLogRepository {
  /// Watches all run logs for the given agent.
  Stream<List<AgentRunLog>> watchByAgent(String agentId);

  /// Watches all run logs across all agents.
  Stream<List<AgentRunLog>> watchAll();

  /// Watches the active (not-yet-completed) run logs for a conversation within
  /// a workspace. Used to detect whether an agent is currently working in a
  /// channel/ticket.
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  );

  /// Get by id.
  Future<AgentRunLog?> getById(String id);

  /// Upsert.
  Future<void> upsert(AgentRunLog log);
}
