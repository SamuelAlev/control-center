import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/ports/goal_turn_text_port.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/improvement_review_prompt.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_harness/context.dart' show newWakeDataNonce;
import 'package:cc_infra/src/dispatch/improvement_review_service.dart'
    show ImprovementReviewService, kImprovementGoalField;

/// [GoalTurnTextPort] for an improvement review's run: the review's
/// instructions (`renderImprovementReviewPrompt`) rendered from the stored
/// goal, never from the wake's payload. Every other run's text comes from
/// the goal port.
class ImprovementReviewTurnTexts implements GoalTurnTextPort {
  /// Creates the port over the goal port (the goal block and the goal
  /// review) and the goal rows.
  ImprovementReviewTurnTexts({required this._goals, required this._goalRows});

  final GoalTurnTextPort _goals;
  final AgentGoalRunRepository _goalRows;

  @override
  Future<GoalTurnText?> forRun({
    required String workspaceId,
    required String agentId,
    required String? conversationId,
    required WakeContext wakeContext,
    required bool hasRepl,
  }) async {
    final review = wakeContext.wakes
        .where((w) => w.reason == WakeReason.improvementReview)
        .firstOrNull;
    if (review == null) {
      return _goals.forRun(
        workspaceId: workspaceId,
        agentId: agentId,
        conversationId: conversationId,
        wakeContext: wakeContext,
        hasRepl: hasRepl,
      );
    }
    if (conversationId == null ||
        review.workspaceId != workspaceId ||
        review.conversationId != conversationId ||
        review.agentId != agentId) {
      return null;
    }
    final goalId = review.detail.fields[kImprovementGoalField];
    final goal = goalId is String
        ? await _goalRows.getById(workspaceId, goalId)
        : null;
    final verified =
        goal != null &&
        goal.conversationId == conversationId &&
        ImprovementReviewService.isVerifiedGoal(goal);
    return GoalTurnText(
      section: renderImprovementReviewPrompt(
        workspaceId: workspaceId,
        spaceId: review.spaceId,
        conversationId: conversationId,
        goal: verified ? goal : null,
        nonce: wakeContext.nonce ?? newWakeDataNonce(),
        hasRepl: hasRepl,
      ),
    );
  }
}
