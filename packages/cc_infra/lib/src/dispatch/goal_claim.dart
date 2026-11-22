import 'package:cc_domain/cc_domain.dart'
    show
        GoalNotActiveSegmentException,
        GoalRefusedException,
        ValidationException;
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';

// The rules of a completion claim (plan section 8, "Verification"): who may
// claim, when, and with what evidence. `GoalSupervisor.claimCompletion`
// checks a claim with [checkGoalClaim] before it records it.

/// [goal]'s claim checked: [goal] is the agent's active goal in
/// [conversationId] with [callingRunId] its active segment and no claim
/// pending, [summary] is within its limit, and [evidence] covers every "Done
/// means" item. Returns the evidence with each item's own text; throws the
/// refusal otherwise ([GoalNotActiveSegmentException], [GoalRefusedException]
/// `goal_claim_pending` or `goal_evidence_incomplete`, [ValidationException]).
List<GoalClaimEvidence> checkGoalClaim(
  AgentGoalRun? goal, {
  required String conversationId,
  required String? callingRunId,
  required String summary,
  required List<GoalClaimEvidence> evidence,
}) {
  final active = requireGoalSegment(goal, conversationId, callingRunId);
  if (active.hold == GoalHold.verifying) {
    throw goalClaimPending;
  }
  final covered = coverGoalEvidence(active, evidence);
  if (summary.length > GoalVerification.maxSummaryLength) {
    throw ValidationException(
      'The summary is ${summary.length} characters; keep it within '
      '${GoalVerification.maxSummaryLength}.',
    );
  }
  return covered;
}

/// The refusal of a second claim while one is verified.
const GoalRefusedException goalClaimPending = GoalRefusedException(
  'Your completion claim is already being verified. End your turn; you '
  'will be woken with the result.',
  kind: GoalRefusedException.claimPendingKind,
);

/// [goal], when it is the agent's active goal in [conversationId] and
/// [callingRunId] its active segment; throws otherwise.
AgentGoalRun requireGoalSegment(
  AgentGoalRun? goal,
  String conversationId,
  String? callingRunId,
) {
  if (goal == null || goal.status != AgentGoalStatus.active) {
    throw const GoalNotActiveSegmentException(
      'You have no active goal in this workspace.',
    );
  }
  if (goal.conversationId != conversationId) {
    throw const GoalNotActiveSegmentException(
      'Your active goal runs in another conversation; only its own '
      'segment can claim it.',
    );
  }
  final activeRunId = goal.activeRunId;
  if (activeRunId == null) {
    throw const GoalNotActiveSegmentException(
      'Your goal has no segment running; only its active segment can '
      'claim it.',
    );
  }
  // Both transports prove the calling run: the gateway from the run's
  // grant, the built-in harness from its own run.
  if (callingRunId == null || callingRunId != activeRunId) {
    throw const GoalNotActiveSegmentException(
      "This run is not your goal's active segment; only that segment "
      'can claim it.',
    );
  }
  return goal;
}

/// [evidence] with each entry that names a contract criterion (by its
/// number from 1 or its text) carrying the criterion's own text. Throws
/// [GoalRefusedException] (`goal_evidence_incomplete`) naming every
/// criterion no entry covers.
List<GoalClaimEvidence> coverGoalEvidence(
  AgentGoalRun goal,
  List<GoalClaimEvidence> evidence,
) {
  final criteria = goal.contract?.criteria ?? const <String>[];
  if (criteria.isEmpty) {
    return evidence;
  }
  String key(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');
  final byText = {
    for (var i = 0; i < criteria.length; i++) key(criteria[i]): i,
  };
  final matched = <int, GoalClaimEvidence>{};
  final extra = <GoalClaimEvidence>[];
  for (final entry in evidence) {
    final name = key(entry.criterion);
    final number = int.tryParse(name);
    final index = number != null && number >= 1 && number <= criteria.length
        ? number - 1
        : byText[name];
    if (index == null || entry.evidence.trim().isEmpty) {
      extra.add(entry);
      continue;
    }
    matched.putIfAbsent(
      index,
      () => GoalClaimEvidence(
        criterion: criteria[index],
        evidence: entry.evidence,
      ),
    );
  }
  final missing = [
    for (var i = 0; i < criteria.length; i++)
      if (!matched.containsKey(i)) '${i + 1}. ${key(criteria[i])}',
  ];
  if (missing.isNotEmpty) {
    throw GoalRefusedException(
      'Your evidence does not cover every "Done means" item. Missing: '
      '${missing.join('; ')}. Call complete_goal again with one '
      '{criterion, evidence} entry per item, the criterion given as its '
      'number or its exact text.',
      kind: GoalRefusedException.evidenceIncompleteKind,
    );
  }
  return [for (var i = 0; i < criteria.length; i++) matched[i]!, ...extra];
}
