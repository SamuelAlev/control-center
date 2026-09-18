import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_host/cc_host.dart';

import 'catalog_wire.dart' show agentGoalRunToWire;

/// One durable-goal lifecycle control (`pause` / `resume` / `cancel`), wired
/// by the caller to the server's `GoalSupervisor` (tear-offs keep this file
/// agnostic of the dispatch machinery).
typedef GoalControl = Future<void> Function(String workspaceId, String goalId);

/// The `resume` control: resumes a paused goal, or a `budgetExhausted` one
/// when [raiseCostCapCents] lifts the cost cap above the spend that tripped
/// it (budget exhaustion is not completion — the goal resumes only by
/// raising the budget).
typedef GoalResumeControl =
    Future<void> Function(
      String workspaceId,
      String goalId, {
      int? raiseCostCapCents,
    });

/// Durable supervised goals (`/goal` + `/loop`): the pause / resume / cancel
/// controls a thin client drives over repo-RPC. Each op is a thin delegation
/// to the server's goal supervisor.
List<RepoOp> agentGoalRunOps({
  required GoalControl pauseGoal,
  required GoalResumeControl resumeGoal,
  required GoalControl cancelGoal,
}) => [
  RepoOp(
    name: 'agentGoalRuns.pause',
    kind: RepoOpKind.mutate,
    requiredArgs: ['goal_id'],
    handler: (ctx) async {
      await pauseGoal(ctx.workspaceId!, ctx.args['goal_id'] as String);
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'agentGoalRuns.resume',
    kind: RepoOpKind.mutate,
    requiredArgs: ['goal_id'],
    handler: (ctx) async {
      await resumeGoal(
        ctx.workspaceId!,
        ctx.args['goal_id'] as String,
        raiseCostCapCents: (ctx.args['raise_cost_cap_cents'] as num?)?.toInt(),
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'agentGoalRuns.cancel',
    kind: RepoOpKind.mutate,
    requiredArgs: ['goal_id'],
    handler: (ctx) async {
      await cancelGoal(ctx.workspaceId!, ctx.args['goal_id'] as String);
      return {'ok': true};
    },
  ),
];

/// The watch counterpart to [agentGoalRunOps]: the workspace's durable goals
/// (newest first) filtered to the client's `conversation_id` arg.
WatchQuery agentGoalRunsWatchQuery({
  required AgentGoalRunRepository agentGoalRunRepository,
}) => WatchQuery(
  name: 'agentGoalRuns.watchForConversation',
  handler: (ctx) => agentGoalRunRepository
      .watchByWorkspace(ctx.workspaceId!)
      .map(
        (list) => {
          'goals': [
            for (final g in list.where(
              (g) => g.conversationId == ctx.args['conversation_id'],
            ))
              agentGoalRunToWire(g),
          ],
        },
      ),
);
