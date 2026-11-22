import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/ports/goal_turn_text_port.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_block.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_review_prompt.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_verification_notice.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_budget_shares.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_harness/context.dart' show newWakeDataNonce;
import 'package:cc_infra/src/dispatch/goal_changes.dart';
import 'package:cc_infra/src/dispatch/goal_store.dart' show isGoalReviewWake;
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// The heading of the review run's per-turn section.
const String goalReviewHeading = '## Goal review';

/// [GoalTurnTextPort] over the goal rows: what a wake-started run's per-turn
/// prompt says about a goal, rendered from the stored goal (never from a
/// wake's payload, which is far too small for a review prompt or a
/// failed-verification notice).
///
/// - A `goalReview` wake's run gets [goalReviewHeading] and
///   `renderGoalReviewPrompt` (the claim, the check results and what changed
///   since the goal started, in data blocks).
/// - A run that is a goal's segment (one of the goal's own wakes, or any
///   wake of the agent in the goal's conversation while the goal waits,
///   `hold: waiting`) gets the goal block with its completion audit; a
///   `goalVerification` wake's item becomes the failed-verification notice.
/// - Any other run gets nothing.
class GoalTurnTexts implements GoalTurnTextPort {
  /// Creates the port.
  GoalTurnTexts({
    required this.goals,
    required this.changes,
    required this._now,
  });

  /// The goal rows.
  final AgentGoalRunRepository goals;

  /// What changed since a goal started.
  final GoalChanges changes;

  final DateTime Function() _now;

  @override
  Future<GoalTurnText?> forRun({
    required String workspaceId,
    required String agentId,
    required String? conversationId,
    required WakeContext wakeContext,
    required bool hasRepl,
  }) async {
    if (conversationId == null || !wakeContext.hasWakes) {
      return null;
    }
    final nonce = wakeContext.nonce ?? newWakeDataNonce();
    final review = wakeContext.wakes.where(isGoalReviewWake);
    if (review.isNotEmpty) {
      return _review(
        workspaceId,
        review.first.detail.goalId!,
        conversationId: conversationId,
        nonce: nonce,
        hasRepl: hasRepl,
      );
    }
    final goal = await _segmentGoal(
      workspaceId,
      agentId: agentId,
      conversationId: conversationId,
      goalId: wakeContext.goalId,
    );
    if (goal == null) {
      return null;
    }
    final items = <String, String>{};
    final verification = goal.verification;
    for (final wake in wakeContext.wakes) {
      if (wake.reason != WakeReason.goalVerification ||
          wake.detail.goalId != goal.id ||
          verification == null) {
        continue;
      }
      try {
        items[wake.id] = goalVerificationNotice(
          verification,
        ).render(nonce: nonce);
      } on ArgumentError catch (e) {
        CcInfraLog.warning('goal ${goal.id}: no verification notice: $e');
      }
    }
    final deadline = goal.deadlineAt;
    final segmentCap = goalSegmentCapMicros(goal);
    return GoalTurnText(
      section: renderGoalBlockWithAudit(
        goal,
        GoalBlockState(
          segment: goal.runCount + 1,
          spentMicros: goal.costMicros < 0 ? 0 : goal.costMicros,
          capMicros: goal.costCapMicros,
          timeLeft: deadline?.difference(_now()),
          noProgressCount: goal.noProgressStreak,
          verificationRound: goal.verificationRounds + 1,
          segmentCapMicros: segmentCap <= 0 ? 1 : segmentCap,
        ),
        hasRepl: hasRepl,
        nonce: nonce,
      ),
      wakeItems: items,
    );
  }

  Future<GoalTurnText?> _review(
    String workspaceId,
    String goalId, {
    required String conversationId,
    required String nonce,
    required bool hasRepl,
  }) async {
    final goal = await goals.getById(workspaceId, goalId);
    final verification = goal?.verification;
    if (goal == null ||
        verification == null ||
        goal.conversationId != conversationId) {
      return null;
    }
    final changed = await changes.of(goal);
    return GoalTurnText(
      section:
          '$goalReviewHeading\n\n'
          '${renderGoalReviewPrompt(goal: goal, verification: verification, changes: changed, nonce: nonce, hasRepl: hasRepl)}',
    );
  }

  /// The goal whose segment this run is: [goalId]'s (the run delivers one of
  /// its wakes), or the agent's goal in [conversationId] while it waits for
  /// the first wake to arrive.
  Future<AgentGoalRun?> _segmentGoal(
    String workspaceId, {
    required String agentId,
    required String conversationId,
    required String? goalId,
  }) async {
    if (goalId != null) {
      final goal = await goals.getById(workspaceId, goalId);
      if (goal == null ||
          goal.status.isTerminal ||
          goal.agentId != agentId ||
          goal.conversationId != conversationId) {
        return null;
      }
      return goal;
    }
    final active = await goals.getActiveForAgent(workspaceId, agentId);
    if (active == null ||
        active.status != AgentGoalStatus.active ||
        active.conversationId != conversationId ||
        active.hold != GoalHold.waiting) {
      return null;
    }
    return active;
  }
}
