import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';

/// A goal as one viewer sees it: the goal and what the server decided that
/// viewer may do with it. [canResume] covers Resume and every control that
/// lets the goal spend more (budget, run cap, deadline): the server computes
/// it per caller (the goal's requester, or an admin for a goal nobody
/// requested), and the same person alone may change its contract or
/// checker. [canApprove] is whether this viewer may close the goal as done
/// while it waits for review: anyone the space admits for a goal a person
/// started in a conversation, the requester alone (an admin for none) for a
/// goal a pipeline started. A client never compares user ids to decide
/// either.
class GoalRunView {
  /// Creates a view of [goal] for one viewer.
  const GoalRunView({
    required this.goal,
    required this.canResume,
    required this.canApprove,
  });

  /// The goal.
  final AgentGoalRun goal;

  /// Whether this viewer may resume the goal or raise what it may spend.
  final bool canResume;

  /// Whether this viewer may approve the goal's completion.
  final bool canApprove;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalRunView &&
          goal == other.goal &&
          canResume == other.canResume &&
          canApprove == other.canApprove;

  @override
  int get hashCode => Object.hash(goal, canResume, canApprove);
}
