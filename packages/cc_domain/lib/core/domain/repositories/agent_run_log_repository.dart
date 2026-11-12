import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';

/// Agent run log repository.
///
/// A run's large values ([AgentRunLog.contextSnapshotJson],
/// [AgentRunLog.expectedOutputSchema], [AgentRunLog.outputJson] and the
/// detail of [AgentRunLog.verification]) are its payload. Only the single-run reads
/// ([getById], [activeRunForAgent], [latestForTicket]) and the pipeline
/// harvest read ([forPipelineStep]) carry it; every list and watch returns runs
/// without it (those fields null, the verification verdict without detail).
abstract class AgentRunLogRepository {
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

  /// Runs that have not finished (pending or running) in every workspace,
  /// newest first, bounded per workspace.
  ///
  /// CROSS-WORKSPACE BY DESIGN — for the liveness jobs (the orphan-run
  /// reaper, process detection), which are defined over every workspace and
  /// only ever inspect runs still in flight. The status filter runs in the
  /// store; nothing reads finished history to find these.
  Future<List<AgentRunLog>> nonTerminal();

  /// Watches [workspaceId]'s unfinished runs (pending or running), newest
  /// first and bounded — "which spaces have an agent working right now".
  Stream<List<AgentRunLog>> watchNonTerminalForWorkspace(String workspaceId);

  /// The most recently started run for [ticketId] in [workspaceId], or null
  /// when the ticket has never been dispatched.
  Future<AgentRunLog?> latestForTicket(String workspaceId, String ticketId);

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

  /// Point-in-time companion to [watchActiveByConversation]: the active run
  /// logs right now. Used by server-side one-shot decisions (the steering
  /// queue's "is anyone still working here" check) that would otherwise
  /// subscribe-and-cancel on every call.
  Future<List<AgentRunLog>> activeByConversation(
    String workspaceId,
    String conversationId,
  ) async => await watchActiveByConversation(workspaceId, conversationId).first;

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

  /// Upserts [log]. The workspace comes from [AgentRunLog.workspaceId]; a run
  /// log with no workspace cannot be stored and is rejected.
  ///
  /// A payload field that is null on [log] keeps its stored value, so a run
  /// read from a list can be written back without erasing its payload.
  Future<void> upsert(AgentRunLog log);

  /// Updates only this run's own usage and timing; never writes descendant cost
  /// or terminal/metadata fields. A missing run in this workspace is a no-op.
  Future<void> updateCost(String workspaceId, String runId, RunCost cost);

  /// Adds exact descendant spend in micro-dollars atomically.
  /// A missing run in this workspace is a no-op.
  Future<void> addChildCostMicros(
    String workspaceId,
    String runId,
    int amountMicros,
  );

  /// Writes only explicitly supplied runtime/observability columns. Returns
  /// false for a missing row, an empty update, or a rejected [markRunning]
  /// transition. Only pending, nonterminal rows can become running.
  Future<bool> updateRuntime(
    String workspaceId,
    String runId, {
    int? pid,
    bool markRunning = false,
    String? logPath,
    String? contextSnapshotJson,
    DateTime? lastOutputAt,
    RunLiveness? liveness,
    RunErrorFamily? errorFamily,
    String? summary,
    String? modelId,
    String? effort,
    String? taskFamily,
  });

  /// Conditionally stamps a terminal run using only terminal/observability
  /// columns. Returns false if this run was missing or already terminal.
  /// [writeCost] is false when the caller has no final usage report: a separate
  /// in-flight [updateCost] must not be replaced by a stale run snapshot.
  Future<bool> completeIfActive(AgentRunLog completed, {bool writeCost = true});
}
