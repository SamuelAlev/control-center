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
  ///
  /// CROSS-WORKSPACE BY DESIGN — for the completeness-critical system jobs (the
  /// orphan-run reaper, cost rollups, process detection). A workspace-scoped
  /// surface must use [watchByAgent] or [watchByConversation].
  Stream<List<AgentRunLog>> watchAll();

  /// Watches the [limit] most recent run logs across all agents/workspaces,
  /// newest first.
  ///
  /// The bounded companion to [watchAll] for live UI surfaces: a live
  /// dashboard never needs the full unbounded history materialized on every
  /// change (that scales RAM and wire traffic with the whole table). System
  /// jobs that genuinely need completeness (e.g. the orphan-run reaper) keep
  /// using [watchAll].
  ///
  /// The default implementation trims [watchAll] in memory; persistence-backed
  /// implementations should override it with a real `LIMIT` query.
  Stream<List<AgentRunLog>> watchRecent(int limit) => watchAll().map(
    (logs) => logs.length <= limit ? logs : logs.sublist(0, limit),
  );

  /// Watches the active (not-yet-completed) run logs for a conversation within
  /// a workspace. Used to detect whether an agent is currently working in a
  /// channel/ticket.
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  );

  /// Watches ALL run logs (active + completed) for a conversation within a
  /// workspace, newest first. Used by the conversation run-tree UI to render
  /// the parent dispatch plus the ephemeral subagent runs it spawned (linked
  /// via [AgentRunLog.parentRunId]).
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  );

  /// Returns the run log [id] within [workspaceId], or null.
  ///
  /// The id resolves only inside [workspaceId]: a run belonging to another
  /// workspace is simply not found, so an id alone can never reach across the
  /// isolation boundary.
  Future<AgentRunLog?> getById(String workspaceId, String id);

  /// Returns the agent's most-recently-started run within [workspaceId] that has
  /// not yet reached a terminal state (used to resolve which conversation an
  /// agent is currently working in, server-side, without trusting
  /// client-supplied arguments). Returns null when the agent has no active run.
  Future<AgentRunLog?> activeRunForAgent(String workspaceId, String agentId);

  /// Upserts [log]. The workspace comes from [AgentRunLog.workspaceId]; a run
  /// log with no workspace cannot be stored and is rejected.
  Future<void> upsert(AgentRunLog log);
}
