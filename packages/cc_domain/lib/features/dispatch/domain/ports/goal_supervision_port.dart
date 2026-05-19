import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';

/// Narrow port the `complete_goal` MCP tool (and any future goal-control
/// surface) consumes. Implemented by the server's goal supervisor; kept in
/// the shared kernel so tool packages never depend on server infrastructure.
abstract interface class GoalSupervisionPort {
  /// The calling agent's currently active goal, or null.
  ///
  /// At most one goal per agent is active at a time (the supervisor enforces
  /// this at start), so an agent never has to carry a goal id to declare its
  /// objective achieved.
  Future<AgentGoalRun?> activeGoalForAgent(String workspaceId, String agentId);

  /// Declares the calling agent's active goal achieved.
  ///
  /// Throws a [StateError] with an agent-readable message when the agent has
  /// no active goal — the tool surfaces it verbatim.
  Future<void> completeGoal(
    String workspaceId,
    String agentId, {
    required String summary,
  });
}
