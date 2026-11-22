import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';

/// Narrow port the `complete_goal` MCP tool (and any future goal-control
/// surface) consumes. Implemented by the server's goal supervisor; kept in
/// the shared kernel so tool packages never depend on server infrastructure.
abstract interface class GoalSupervisionPort {
  /// The calling agent's currently active goal, or null.
  ///
  /// At most one goal per agent is active at a time (a partial unique index),
  /// so an agent never has to carry a goal id to claim its objective.
  Future<AgentGoalRun?> activeGoalForAgent(String workspaceId, String agentId);

  /// Records the calling agent's claim that its active goal is complete, and
  /// returns the goal as stored: `hold: verifying`, the claim in
  /// `verification`. The claim does not complete the goal: when the segment
  /// ends the server runs the contract's checks and an independent review.
  ///
  /// Only the goal's active segment may claim: [agentId] and
  /// [conversationId] come from the call's scope (never a model argument),
  /// the goal must be that agent's active goal in that conversation, and its
  /// `activeRunId` must be [callingRunId]. Anything else throws
  /// `GoalNotActiveSegmentException` (`goal_not_active_segment`).
  ///
  /// When the contract has criteria, [evidence] must cover each one: an
  /// entry covers a criterion when its `criterion` is the criterion's number
  /// (`"2"`, counting from 1) or its exact text; otherwise it throws
  /// `GoalRefusedException` (`goal_evidence_incomplete`). A second claim
  /// while one is being verified throws it with `goal_claim_pending`.
  Future<AgentGoalRun> claimCompletion(
    String workspaceId,
    String agentId, {
    required String conversationId,
    required String? callingRunId,
    required String summary,
    required List<GoalClaimEvidence> evidence,
  });
}
