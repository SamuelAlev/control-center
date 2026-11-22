import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_authority.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_host/cc_host.dart';

/// One durable-goal lifecycle control (`pause` / `resume` / `cancel`), wired
/// by the caller to the server's `GoalSupervisor` (tear-offs keep this file
/// agnostic of the dispatch machinery).
typedef GoalControl = Future<void> Function(String workspaceId, String goalId);

/// The `resume` control: resumes a paused goal, or a `budgetExhausted` one
/// when [raiseCostCapMicros] lifts the cost cap above the spend that tripped
/// it (budget exhaustion is not completion — the goal resumes only by
/// raising the budget).
typedef GoalResumeControl =
    Future<void> Function(
      String workspaceId,
      String goalId, {
      int? raiseCostCapMicros,
    });

/// The gate every `agentGoalRuns.*` operation passes: the goal [goalId]
/// looked up in the caller's workspace (a foreign id is not found), and the
/// caller allowed to read the goal's space (`PrDataGate.requireSpace`: a
/// review space only for who may see its pull request, any space only for
/// who may read every repository it exposes). Returns the goal.
typedef GoalSpaceGate =
    Future<AgentGoalRun> Function(
      String workspaceId,
      String userId,
      String goalId,
    );

/// The [GoalSpaceGate] over [goals] and the space gate [requireSpace].
GoalSpaceGate goalSpaceGate({
  required AgentGoalRunRepository goals,
  required Future<void> Function(
    String workspaceId,
    String userId,
    String spaceId,
  )
  requireSpace,
}) => (workspaceId, userId, goalId) async {
  if (goalId.isEmpty) {
    throw const ValidationException('goal_id must be a goal id');
  }
  final goal = await goals.getById(workspaceId, goalId);
  if (goal == null) {
    throw NotFoundException('No goal $goalId in this workspace.');
  }
  await requireSpace(workspaceId, userId, goal.spaceId);
  return goal;
};

/// The caller's role in a workspace (null: not a member).
typedef GoalViewerRole =
    Future<WorkspaceRole?> Function(String workspaceId, String userId);

/// Durable supervised goals (`/goal`): the pause / resume / cancel controls a
/// thin client drives over repo-RPC. Each op passes the [goalSpaceGate] over
/// [goals] and [requireSpace], then delegates to the goal supervisor.
///
/// Resume, and its raise of the cost cap, lets the goal spend more with its
/// requester's sign-in: only the requester may (for a goal nobody requested,
/// a workspace admin; [mayResumeGoal]), refused with `data.kind:
/// goal_not_yours` otherwise. Pause and cancel stay open to every member who
/// may read the space. A resume while another goal of the same agent is
/// active is refused with `data.kind: goal_already_active`
/// (`GoalAlreadyActiveException`, mapped by the RPC exception mapper).
List<RepoOp> agentGoalRunOps({
  required AgentGoalRunRepository goals,
  required Future<void> Function(
    String workspaceId,
    String userId,
    String spaceId,
  )
  requireSpace,
  required GoalControl pauseGoal,
  required GoalResumeControl resumeGoal,
  required GoalControl cancelGoal,
}) {
  final goalSpace = goalSpaceGate(goals: goals, requireSpace: requireSpace);
  Future<String> gated(RepoOpContext ctx) async => (await goalSpace(
    ctx.workspaceId!,
    ctx.userId,
    ctx.args['goal_id'] as String,
  )).id;
  return [
    RepoOp(
      name: 'agentGoalRuns.pause',
      kind: RepoOpKind.mutate,
      requiredArgs: ['goal_id'],
      handler: (ctx) async {
        await pauseGoal(ctx.workspaceId!, await gated(ctx));
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'agentGoalRuns.resume',
      kind: RepoOpKind.mutate,
      requiredArgs: ['goal_id'],
      handler: (ctx) async {
        final goal = await goalSpace(
          ctx.workspaceId!,
          ctx.userId,
          ctx.args['goal_id'] as String,
        );
        if (!mayResumeGoal(goal, userId: ctx.userId, role: ctx.role)) {
          throw const AuthException(
            'Only the person this goal works for can resume it or raise its '
            'budget (for a goal nobody asked for, a workspace admin).',
            code: goalNotYoursKind,
          );
        }
        await resumeGoal(
          ctx.workspaceId!,
          goal.id,
          raiseCostCapMicros: (ctx.args['raise_cost_cap_micros'] as num?)
              ?.toInt(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'agentGoalRuns.cancel',
      kind: RepoOpKind.mutate,
      requiredArgs: ['goal_id'],
      handler: (ctx) async {
        await cancelGoal(ctx.workspaceId!, await gated(ctx));
        return {'ok': true};
      },
    ),
  ];
}

/// The person's verdict on a goal paused for review: closes it as done on
/// their word ([userId]); throws `GoalRefusedException`
/// (`goal_not_in_review`) when the goal is not waiting for a review.
typedef GoalApproveControl =
    Future<AgentGoalRun> Function(
      String workspaceId,
      String goalId, {
      required String userId,
    });

/// `agentGoalRuns.approveCompletion {goal_id}` → `{goal}` (the
/// [agentGoalRunToWire] shape): a person closes a goal that waits for their
/// review (`paused`, `hold: needsReview`) as done; the goal becomes
/// `completed` and its `verification.approvedByUserId` is the caller. Any
/// workspace member who may read the goal's space ([goalSpace]) may close an
/// unlinked goal; a goal a pipeline step pursues only its requester (or, for
/// one nobody requested, a workspace admin; [mayApproveGoal]), since closing
/// it lets the pipeline go on as that person: refused with `data.kind:
/// goal_not_yours`. Refused with `data.kind: goal_not_in_review` when the
/// goal is not waiting for a review.
List<RepoOp> buildAgentGoalReviewOps({
  required GoalSpaceGate goalSpace,
  required GoalApproveControl approveCompletion,
}) => [
  RepoOp(
    name: 'agentGoalRuns.approveCompletion',
    kind: RepoOpKind.mutate,
    requiredArgs: ['goal_id'],
    handler: (ctx) async {
      final gated = await goalSpace(
        ctx.workspaceId!,
        ctx.userId,
        ctx.args['goal_id'] as String,
      );
      if (!mayApproveGoal(gated, userId: ctx.userId, role: ctx.role)) {
        throw const AuthException(
          'Only the person this goal works for can close it as done while a '
          'pipeline pursues it (for a goal nobody asked for, a workspace '
          'admin).',
          code: goalNotYoursKind,
        );
      }
      final goal = await approveCompletion(
        ctx.workspaceId!,
        gated.id,
        userId: ctx.userId,
      );
      return {'goal': agentGoalRunToWireFor(ctx, goal)};
    },
  ),
];

/// The goal watch queries, each goal sent with the subscriber's
/// `can_resume` and `can_approve` ([roleOf] for a goal nobody requested),
/// and each only when the subscriber passes the space gate for its space
/// ([requireSpace], as `agentGoalRuns.get`), checked before any objective
/// or completion text is serialized:
///
/// - `agentGoalRuns.watchForConversation`: the workspace's durable goals
///   (newest first) filtered to the client's `conversation_id` arg;
/// - `agentGoalRuns.watchForWorkspace`: every goal of the workspace.
List<WatchQuery> agentGoalRunWatchQueries({
  required AgentGoalRunRepository agentGoalRunRepository,
  required Future<void> Function(
    String workspaceId,
    String userId,
    String spaceId,
  )
  requireSpace,
  required GoalViewerRole roleOf,
}) {
  Future<bool> readable(WatchQueryContext ctx, AgentGoalRun goal) async {
    try {
      await requireSpace(ctx.workspaceId!, ctx.userId, goal.spaceId);
      return true;
    } on AppException {
      return false;
    }
  }

  Stream<Map<String, dynamic>> goalsOf(
    WatchQueryContext ctx,
    bool Function(AgentGoalRun goal) wanted,
  ) => agentGoalRunRepository.watchByWorkspace(ctx.workspaceId!).asyncMap((
    list,
  ) async {
    final role = await roleOf(ctx.workspaceId!, ctx.userId);
    return {
      'goals': [
        for (final g in list)
          if (g.workspaceId == ctx.workspaceId &&
              wanted(g) &&
              await readable(ctx, g))
            agentGoalRunToWireAs(g, userId: ctx.userId, role: role),
      ],
    };
  });

  return [
    WatchQuery(
      name: 'agentGoalRuns.watchForConversation',
      handler: (ctx) =>
          goalsOf(ctx, (g) => g.conversationId == ctx.args['conversation_id']),
    ),
    WatchQuery(
      name: 'agentGoalRuns.watchForWorkspace',
      minRole: WorkspaceRole.member,
      handler: (ctx) => goalsOf(ctx, (_) => true),
    ),
  ];
}

/// [agentGoalRunToWire] for the caller of [ctx]: `can_resume` and
/// `can_approve` from their id and role.
Map<String, dynamic> agentGoalRunToWireFor(
  RepoOpContext ctx,
  AgentGoalRun goal,
) => agentGoalRunToWireAs(goal, userId: ctx.userId, role: ctx.role);

/// [agentGoalRunToWire] for [userId], whose role in the goal's workspace is
/// [role].
Map<String, dynamic> agentGoalRunToWireAs(
  AgentGoalRun goal, {
  required String userId,
  required WorkspaceRole? role,
}) => agentGoalRunToWire(
  goal,
  canResume: mayResumeGoal(goal, userId: userId, role: role),
  canApprove: mayApproveGoal(goal, userId: userId, role: role),
);

/// Maps an [AgentGoalRun] (a durable supervised `/goal`) to its
/// wire shape (enum fields as their persisted wire names, timestamps
/// ISO-8601 UTC like the other catalog wire mappers). [canResume] and
/// [canApprove] are the server's answers for the viewer; a client never
/// compares ids itself:
/// - `can_resume` ([mayResumeGoal]): whether to offer Resume, the budget
///   controls, and editing the contract and the checker;
/// - `can_approve` ([mayApproveGoal]): whether to offer closing the goal as
///   done (shown, as before, only while it waits for a review).
Map<String, dynamic> agentGoalRunToWire(
  AgentGoalRun g, {
  required bool canResume,
  required bool canApprove,
}) => {
  'id': g.id,
  'workspace_id': g.workspaceId,
  'space_id': g.spaceId,
  'conversation_id': g.conversationId,
  'agent_id': g.agentId,
  'user_text': g.userText,
  'status': g.status.wire,
  'deadline_at': ?g.deadlineAt?.toIso8601String(),
  'cost_cap_micros': g.costCapMicros,
  'cost_micros': g.costMicros,
  'max_runs': ?g.maxRuns,
  'run_count': g.runCount,
  'consecutive_failures': g.consecutiveFailures,
  'active_run_id': ?g.activeRunId,
  'requested_by_user_id': ?g.requestedByUserId,
  'summary': ?g.summary,
  'contract': ?g.contract?.toJson(),
  'hold': ?g.hold?.wire,
  'hold_until': ?g.holdUntil?.toIso8601String(),
  'hold_detail': ?g.holdDetail,
  'no_progress_streak': g.noProgressStreak,
  'verification_rounds': g.verificationRounds,
  'last_fingerprint': ?g.lastFingerprint,
  'last_activity_digest': ?g.lastActivityDigest,
  'start_ref': ?g.startRefs?.toJson(),
  'park_count': g.parkCount,
  'fresh': g.fresh,
  'unattended': g.unattended.wire,
  'checker_agent_id': ?g.checkerAgentId,
  'verification': ?g.verification?.toJson(),
  'pipeline_run_id': ?g.pipeline?.pipelineRunId,
  'pipeline_step_id': ?g.pipeline?.stepId,
  'created_at': g.createdAt.toIso8601String(),
  'updated_at': g.updatedAt.toIso8601String(),
  'can_resume': canResume,
  'can_approve': canApprove,
};
