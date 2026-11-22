import 'package:cc_domain/core/domain/entities/agent_run_log.dart';

/// The reads of the run log a client makes: the watches the screens render
/// and the single-run gets. The server's full `AgentRunLogRepository`
/// implements this and adds the host-only reads and every write; a client
/// binds only this, so it holds no method it cannot honour.
///
/// A run's large values ([AgentRunLog.contextSnapshotJson],
/// [AgentRunLog.expectedOutputSchema], [AgentRunLog.outputJson] and the
/// detail of [AgentRunLog.verification]) are its payload. Only the single-run
/// reads ([getById], [activeRunForAgent]) and the pipeline harvest read
/// ([forPipelineStep]) carry it; every list and watch returns runs without it
/// (those fields null, the verification verdict without detail).
abstract interface class AgentRunLogReader {
  /// Watches the newest run logs (bounded) for the given agent within a
  /// workspace, newest first.
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

  /// Watches [workspaceId]'s unfinished runs (pending or running), newest
  /// first and bounded — "which spaces have an agent working right now".
  Stream<List<AgentRunLog>> watchNonTerminalForWorkspace(String workspaceId);

  /// Watches the [limit] most recent run logs across all agents/workspaces,
  /// newest first.
  ///
  /// CROSS-WORKSPACE BY DESIGN — the bounded global view for live UI
  /// surfaces: only [limit] rows per workspace are read and re-emitted per
  /// change, so memory and wire traffic stay flat as history grows.
  Stream<List<AgentRunLog>> watchRecent(int limit);

  /// Watches the active (not-yet-completed) run logs for a conversation within
  /// a workspace. Used to detect whether an agent is currently working in a
  /// space/ticket.
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  );

  /// Watches the active run logs of a whole SPACE — every conversation in it,
  /// threads included. This is the "an agent is working here" signal for any
  /// space-level surface (sidebar status dot, review-hub busy gate, take-over
  /// guard); [watchActiveByConversation] answers the narrower per-stream
  /// question.
  Stream<List<AgentRunLog>> watchActiveBySpace(
    String workspaceId,
    String spaceId,
  );

  /// Watches the newest run logs (active + completed, bounded) for a
  /// conversation within a workspace, oldest first. Used by the conversation
  /// run-tree UI to render the parent dispatch plus the ephemeral subagent
  /// runs it spawned (linked via [AgentRunLog.parentRunId]).
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  );

  /// Watches the newest run logs (active + completed, bounded) of a whole
  /// SPACE — every conversation in it, threads included — oldest first.
  /// Backs the space-level AGENTS panel, which lists who has worked here
  /// rather than who is in one stream.
  Stream<List<AgentRunLog>> watchBySpace(String workspaceId, String spaceId);

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
}
