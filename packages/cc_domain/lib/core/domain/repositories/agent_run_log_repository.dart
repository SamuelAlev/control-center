import 'package:cc_domain/core/domain/entities/agent_run_log.dart';

/// Agent run log repository.
abstract class AgentRunLogRepository {
  /// Watches all run logs for the given agent within a workspace, newest first.
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId);

  /// Returns the run logs belonging to a pipeline run within a workspace,
  /// newest first. Used to roll up per-step cost on the run waterfall.
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  );
  /// Returns the run logs belonging to a specific pipeline step within a
  /// workspace, newest first. Used by the pipeline engine to harvest
  /// `submit_output` payloads and by the resume listener to detect step
  /// completion. Workspace-scoped.
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  );

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

  /// Returns the agent's most-recently-started run that has not yet reached a
  /// terminal state (used to resolve which conversation an agent is currently
  /// working in, server-side, without trusting client-supplied arguments).
  /// Returns null when the agent has no active run.
  Future<AgentRunLog?> activeRunForAgent(String agentId);

  /// Upsert.
  Future<void> upsert(AgentRunLog log);
}
