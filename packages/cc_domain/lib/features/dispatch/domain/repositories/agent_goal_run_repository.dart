import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';

/// Persistence port for durable supervised goals ([AgentGoalRun]).
///
/// Every method is workspace-scoped — `workspaceId` is required and never
/// optional. An id-only lookup is NOT a substitute for scoping: a foreign
/// goal id must simply not be found.
abstract interface class AgentGoalRunRepository {
  /// Returns the goal [id] within [workspaceId], or null.
  Future<AgentGoalRun?> getById(String workspaceId, String id);

  /// Lists every goal in [workspaceId], newest first.
  Future<List<AgentGoalRun>> listByWorkspace(String workspaceId);

  /// Watches every goal in [workspaceId], newest first (mirrors
  /// [listByWorkspace] ordering). Backs the RPC `WatchQuery` surface.
  Stream<List<AgentGoalRun>> watchByWorkspace(String workspaceId);

  /// Lists all non-terminal goals across ALL workspaces.
  ///
  /// CROSS-WORKSPACE BY DESIGN: the supervisor's startup reconciler must
  /// resume every active goal regardless of workspace (each re-dispatch is
  /// itself workspace-scoped). The workspace-scoped read path is
  /// [listByWorkspace].
  Future<List<AgentGoalRun>> listActive();

  /// Returns the agent's currently active goal in [workspaceId], or null.
  ///
  /// At most one goal per agent is active (a partial unique index), which
  /// lets the `complete_goal` tool resolve "my goal" without the agent having
  /// to carry the id through its prompt.
  Future<AgentGoalRun?> getActiveForAgent(String workspaceId, String agentId);

  /// The active and paused goals in [workspaceId] that hold something,
  /// narrowed to [hold] when given, oldest first.
  Future<List<AgentGoalRun>> listHeld(String workspaceId, {GoalHold? hold});

  /// Returns the goal in [workspaceId] whose active segment is [runId], or
  /// null. Any status: a closed goal keeps its live segment until it settles.
  Future<AgentGoalRun?> getByActiveRunId(String workspaceId, String runId);

  /// The goals in [workspaceId] that a step of pipeline run [pipelineRunId]
  /// started (`AgentGoalRun.pipeline`), any status, oldest first.
  Future<List<AgentGoalRun>> listForPipelineRun(
    String workspaceId,
    String pipelineRunId,
  );

  /// Inserts or replaces [goal] (keyed by id; workspace comes from the goal),
  /// every field included. For a new goal: a change to a stored one goes
  /// through [replaceIf], so two writers never overwrite each other.
  ///
  /// Throws `GoalAlreadyActiveException` when [goal] is active and another
  /// goal of its agent already is.
  Future<void> upsert(AgentGoalRun goal);

  /// Replaces the stored goal with [next] only while the stored row still
  /// equals [expected] in every field (the copy the caller read and changed),
  /// in one transaction. Returns whether it wrote; a caller that lost
  /// re-reads the goal and acts on what is there. A write that lands never
  /// undoes a change made after [expected] was read: a contract edited
  /// meanwhile, a segment's spend recorded, a hold set.
  ///
  /// [next] and [expected] must be the same goal (id and workspace),
  /// otherwise `ArgumentError`. Throws `GoalAlreadyActiveException` like
  /// [upsert].
  Future<bool> replaceIf(AgentGoalRun next, {required AgentGoalRun expected});

  /// Ends segment [runId] of goal [goalId]: adds [costMicros] to the goal's
  /// spend and one to its run count and clears its active segment, in one
  /// statement and only while [runId] is still that segment. Returns whether
  /// it did: exactly one caller records a segment's end.
  Future<bool> recordSegmentEnd(
    String workspaceId,
    String goalId, {
    required String runId,
    required int costMicros,
    required DateTime at,
  });
}
