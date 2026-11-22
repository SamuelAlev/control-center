import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';

/// The refusal kind of a goal move that only the goal's requester (or, for a
/// goal nobody requested, a workspace admin) may make: resuming it, raising
/// its budget, changing its contract or checker, and closing a goal a
/// pipeline pursues as done.
const String goalNotYoursKind = 'goal_not_yours';

/// Whether [userId], whose role in the goal's workspace is [role], may resume
/// [goal], let it spend more (its cost cap, run cap or deadline raised) or
/// change what done means for it (its contract, its checker).
///
/// A goal's segments run with its requester's sign-in, so the rule for wakes
/// and schedules applies: that is the requester's alone, not even an admin's.
/// A goal without a requester (a bot's, a pipeline's) is a workspace admin's.
/// Pausing and cancelling a goal stay open to every member who may read its
/// space; closing it as done too, unless a pipeline pursues it
/// ([mayApproveGoal]).
bool mayResumeGoal(
  AgentGoalRun goal, {
  required String userId,
  required WorkspaceRole? role,
}) {
  final requester = goal.requestedByUserId;
  if (requester != null) {
    return requester == userId;
  }
  return role?.isAdmin ?? false;
}

/// Whether [userId], whose role in the goal's workspace is [role], may close
/// [goal] as done on their word (`agentGoalRuns.approveCompletion`).
///
/// An unlinked goal's closing starts nothing, so every member who may read
/// its space may. Closing a goal a pipeline step pursues completes that
/// step, and the pipeline's next steps run as the pipeline run's requester:
/// that is [mayResumeGoal]'s.
bool mayApproveGoal(
  AgentGoalRun goal, {
  required String userId,
  required WorkspaceRole? role,
}) => goal.pipeline == null || mayResumeGoal(goal, userId: userId, role: role);
