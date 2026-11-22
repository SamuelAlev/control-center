import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';

/// The most one segment of a goal may spend, in micro-dollars (5 USD, the
/// default cap of a run).
const int goalSegmentCapMaxMicros = 5000000;

/// The most the review of a goal's completion claim may spend, in
/// micro-dollars (2 USD; plan section 8, "Verification").
const int goalReviewCapMaxMicros = 2000000;

/// What [goal]'s next segment may spend: what is left of its budget, at most
/// [goalSegmentCapMaxMicros]. Zero when nothing is left.
int goalSegmentCapMicros(AgentGoalRun goal) =>
    _share(goal, goalSegmentCapMaxMicros);

/// What the review of [goal]'s claim may spend: what is left of its budget,
/// at most [goalReviewCapMaxMicros]. Zero when nothing is left.
int goalReviewCapMicros(AgentGoalRun goal) =>
    _share(goal, goalReviewCapMaxMicros);

int _share(AgentGoalRun goal, int max) {
  final remaining = goal.costCapMicros - goal.costMicros;
  return remaining <= 0 ? 0 : (remaining > max ? max : remaining);
}
