import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';

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
  /// The supervisor enforces at most one active goal per agent, which lets
  /// the `complete_goal` tool resolve "my goal" without the agent having to
  /// carry the id through its prompt.
  Future<AgentGoalRun?> getActiveForAgent(String workspaceId, String agentId);

  /// Inserts or replaces [goal] (keyed by id; workspace comes from the goal).
  Future<void> upsert(AgentGoalRun goal);
}
