/// The phone's sentences for the server's long-running-work kinds: why a
/// wake waits or was skipped, a goal's hold detail, why a schedule ended,
/// and the refusal kinds of goals, schedules, wakes, `/refine` and held
/// steering.
///
/// Each table maps a wire kind to one localized sentence and returns null
/// for a kind this version does not know; the caller then shows the generic
/// lead-in (`workKindUnknown` / `workRefusalUnknown`) with the raw kind in
/// code style. A sentence is never built from the server's message text.
library;

import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;

/// The `data.kind` a refused RPC carries, or null for any other failure.
String? refusalKindOf(Object? error) {
  if (error is! RemoteRpcException) return null;
  final data = error.data;
  final kind = data is Map ? data['kind'] : null;
  return kind is String && kind.isNotEmpty ? kind : null;
}

/// Why a wake waits, is held or was skipped (a `state_reason` or skip kind).
String? wakeKindSentence(AppLocalizations l, String? kind) {
  if (kind == null || kind.isEmpty) return null;
  return switch (kind) {
    'rule_ended' || 'rule_inactive' => l.wakeKindRuleEnded,
    'rule_paused' => l.wakeKindRulePaused,
    'rule_busy' => l.wakeKindRuleBusy,
    'rule_folded' => l.wakeKindRuleFolded,
    'rule_superseded' => l.wakeKindRuleSuperseded,
    'rule_notified' => l.wakeKindRuleNotified,
    'rule_limit_parked' => l.wakeKindRuleLimitParked,
    'stopped' => l.wakeKindStopped,
    'attempts' => l.wakeKindAttempts,
    'agent_deleted' => l.wakeKindAgentDeleted,
    'agent_not_dispatchable' => l.wakeKindAgentNotDispatchable,
    'agent_paused' => l.wakeKindAgentPaused,
    'person_removed' => l.wakeKindPersonRemoved,
    'budget_blocked' => l.wakeKindBudgetBlocked,
    'take_over' => l.wakeKindTakeOver,
    'rate_cap_conversation' => l.wakeKindRateCapConversation,
    'rate_cap_workspace' => l.wakeKindRateCapWorkspace,
    'live_run_no_input' => l.wakeKindLiveRunNoInput,
    'live_run_other_options' => l.wakeKindLiveRunOtherOptions,
    'live_run_other_person' => l.wakeKindLiveRunOtherPerson,
    'dispatch_refused' => l.wakeKindDispatchRefused,
    'sandbox_unavailable' => l.wakeKindSandboxUnavailable,
    'read_only_unavailable' => l.wakeKindReadOnlyUnavailable,
    'server_stopped' => l.wakeKindServerStopped,
    'server_restarted' => l.wakeKindServerRestarted,
    'guard_failed' => l.wakeKindGuardFailed,
    'limit' => l.wakeKindLimit,
    'limit_run_live' => l.wakeKindLimitRunLive,
    'wake_missed' => l.wakeKindWakeMissed,
    'pipeline_run_ended' => l.wakeKindPipelineRunEnded,
    'goal_ended' => l.wakeKindGoalEnded,
    'goal_budget_exhausted' => l.wakeKindGoalBudgetExhausted,
    'goal_review_stale' => l.wakeKindGoalReviewStale,
    'goal_paused' => l.wakeKindGoalPaused,
    'goal_held' => l.wakeKindGoalHeld,
    'goal_stopped' => l.wakeKindGoalStopped,
    'ask_settled' => l.wakeKindAskSettled,
    'wake_rule_ended' => l.wakeKindRuleEnded,
    _ => null,
  };
}

/// The label naming what raised a wake. [agentName] names the agent whose
/// reply, message or finished work raised it, when known.
String wakeOriginLabel(
  AppLocalizations l,
  WakeReason reason, {
  String? agentName,
}) => switch (reason) {
  WakeReason.goalContinuation => l.wakeOriginGoal,
  WakeReason.goalVerification => l.wakeOriginGoalCheck,
  WakeReason.goalReview => l.wakeOriginGoalReview,
  WakeReason.schedule => l.wakeOriginSchedule,
  WakeReason.watch => l.wakeOriginWatch,
  WakeReason.peerReply =>
    agentName == null ? l.wakeOriginReply : l.wakeOriginReplyFrom(agentName),
  WakeReason.peerMessage =>
    agentName == null
        ? l.wakeOriginMessage
        : l.wakeOriginMessageFrom(agentName),
  WakeReason.childCompleted =>
    agentName == null
        ? l.wakeOriginWorkFinished
        : l.wakeOriginWorkFinishedBy(agentName),
  WakeReason.limitReset => l.wakeOriginLimitReset,
  WakeReason.recovery => l.wakeOriginRecovery,
  WakeReason.userMessage => l.wakeOriginMessage,
  WakeReason.assignment => l.wakeOriginAssignment,
  WakeReason.pipelineStep => l.wakeOriginPipelineStep,
  WakeReason.improvementReview => l.wakeOriginImprovementReview,
};

/// A goal's `holdDetail`, read: the sentence (null for a detail this
/// version does not name), a value to show in code style (the command of
/// `check_broken: <command>`, or the raw detail when unnamed) and a second
/// sentence (the skip kind of `wake_skipped: <kind>`).
typedef GoalHoldDetailText = ({
  String? sentence,
  String? code,
  String? followUp,
});

/// Reads a goal's hold detail (see [GoalHoldDetailText]). The part after a
/// colon is data.
GoalHoldDetailText goalHoldDetailText(AppLocalizations l, String detail) {
  final colon = detail.indexOf(':');
  final head = (colon < 0 ? detail : detail.substring(0, colon)).trim();
  final tail = colon < 0 ? '' : detail.substring(colon + 1).trim();
  switch (head) {
    case 'check_broken':
      return (
        sentence: l.goalHoldDetailCheckBroken,
        code: tail.isEmpty ? null : tail,
        followUp: null,
      );
    case 'wake_skipped':
      final reason = wakeKindSentence(l, tail);
      return (
        sentence: l.goalHoldDetailWakeSkipped,
        code: reason == null && tail.isNotEmpty ? tail : null,
        followUp: reason,
      );
    case 'input':
      return (sentence: l.goalHoldDetailInput, code: null, followUp: null);
  }
  final sentence = switch (head) {
    'stalled' => l.goalHoldDetailStalled,
    'stalled_waiting' => l.goalHoldDetailStalledWaiting,
    'verification_failed' => l.goalHoldDetailVerificationFailed,
    'cannot_verify' => l.goalHoldDetailCannotVerify,
    'sandbox_unavailable' => l.goalHoldDetailSandboxUnavailable,
    'checker_unavailable' => l.goalHoldDetailCheckerUnavailable,
    'claim_pending' => l.goalHoldDetailClaimPending,
    'unanswered' => l.goalHoldDetailUnanswered,
    'limit_parks' => l.goalHoldDetailLimitParks,
    _ => null,
  };
  return (
    sentence: sentence,
    code: sentence == null ? detail : null,
    followUp: null,
  );
}

/// Why a schedule ended (`end_reason`, or `reason` on a frame).
String? wakeRuleEndSentence(AppLocalizations l, String? reason) =>
    switch (reason) {
      'fired' => l.wakeRuleEndFired,
      'expired' => l.wakeRuleEndExpired,
      'run_cap' => l.wakeRuleEndRunCap,
      'cost_cap' => l.wakeRuleEndCostCap,
      'goal_ended' => l.wakeRuleEndGoalEnded,
      'cancelled' => l.wakeRuleEndCancelled,
      'member_removed' => l.wakeRuleEndMemberRemoved,
      'invalid_row' => l.wakeRuleEndInvalidRow,
      _ => null,
    };

/// A schedule refusal (`data.kind` from `wakeRules.*`).
String? wakeRuleRefusalSentence(AppLocalizations l, String? kind) =>
    switch (kind) {
      'wake_interval_too_short' => l.wakeRuleRefusalIntervalTooShort,
      'wake_too_soon' => l.wakeRuleRefusalTooSoon,
      'wake_lineage_ended' => l.wakeRuleRefusalLineageEnded,
      'watch_target_unreadable' => l.wakeRuleRefusalWatchTargetUnreadable,
      'wake_expiry_required' => l.wakeRuleRefusalExpiryRequired,
      'wake_limit_reached' => l.wakeRuleRefusalLimitReached,
      'wake_invalid_when' => l.wakeRuleRefusalInvalidWhen,
      'wake_note_too_long' => l.wakeRuleRefusalNoteTooLong,
      'wake_expiry_too_long' => l.wakeRuleRefusalExpiryTooLong,
      'wake_limit_out_of_range' => l.wakeRuleRefusalLimitOutOfRange,
      'wake_next_outside_loop' => l.wakeRuleRefusalNextOutsideLoop,
      'wake_watch_refused' => l.wakeRuleRefusalWatchRefused,
      'wake_rule_ended' => l.wakeRuleRefusalRuleEnded,
      _ => null,
    };

/// A goal refusal (`data.kind` from `agentGoalRuns.*` and `/goal`).
String? goalRefusalSentence(AppLocalizations l, String? kind) => switch (kind) {
  'goal_already_active' => l.goalRefusalAlreadyActive,
  'goal_not_in_review' => l.goalRefusalNotInReview,
  'goal_evidence_incomplete' => l.goalRefusalEvidenceIncomplete,
  'goal_claim_pending' => l.goalRefusalClaimPending,
  'goal_not_active_segment' => l.goalRefusalNotActiveSegment,
  'goal_not_yours' => l.goalRefusalNotYours,
  'goal_not_paused' => l.goalRefusalNotPaused,
  'goal_contract_invalid' => l.goalRefusalContractInvalid,
  'goal_checker_unknown' => l.goalRefusalCheckerUnknown,
  'goal_checker_ambiguous' => l.goalRefusalCheckerAmbiguous,
  'goal_checker_is_goal_agent' => l.goalRefusalCheckerIsGoalAgent,
  'goal_command_invalid' => l.goalRefusalCommandInvalid,
  _ => null,
};

/// A wake refusal (`data.kind` from `wakes.*`). `wake_not_yours` is also the
/// kind a schedule change by someone else is refused with; on a wake it says
/// the wake is another person's.
String? wakeRefusalSentence(AppLocalizations l, String? kind) => switch (kind) {
  'wake_not_yours' => l.wakeRefusalNotYours,
  'wake_settled' => l.wakeRefusalSettled,
  _ => null,
};

/// A `/refine` refusal (`data.kind` of an improvement review request).
String? improvementRefusalSentence(AppLocalizations l, String? kind) =>
    switch (kind) {
      'improvement_review_cooldown' => l.improvementRefusalCooldown,
      'improvement_review_queued' => l.improvementRefusalQueued,
      'improvement_agent_not_found' => l.improvementRefusalAgentNotFound,
      _ => null,
    };

/// A steering refusal (`data.kind` from `steering.*`): a usage-limit
/// pause's cards are not sent by hand, and a held card is sent only by the
/// person who wrote it.
String? steeringRefusalSentence(AppLocalizations l, String? kind) =>
    switch (kind) {
      'steering_held_by_limit' => l.steeringRefusalHeldByLimit,
      'steering_not_yours' => l.steeringRefusalNotYours,
      _ => null,
    };

/// What a failed steering action (`steering.enqueue`, `steering.deliver`)
/// shows: `repo_grant_required` (no write grant while the live run acts for
/// someone else) in words, any other steering refusal by its kind, else the
/// error itself. The draft or the card stays where it was.
String steeringFailureText(AppLocalizations l, Object error) {
  final kind = refusalKindOf(error);
  if (kind == 'repo_grant_required') return l.steeringRefusalNeedsWrite;
  return steeringRefusalSentence(l, kind) ?? '$error';
}

/// The sentence for any refusal kind this version names, or null: what a
/// refused action and a refused command row both show.
String? workRefusalSentence(
  AppLocalizations l,
  String kind, {
  bool schedule = false,
}) =>
    goalRefusalSentence(l, kind) ??
    (schedule && kind == 'wake_not_yours' ? l.wakeRuleRefusalNotYours : null) ??
    wakeRuleRefusalSentence(l, kind) ??
    wakeRefusalSentence(l, kind) ??
    improvementRefusalSentence(l, kind) ??
    steeringRefusalSentence(l, kind) ??
    wakeKindSentence(l, kind);

/// What a failed action on a goal, wake or schedule shows: the refusal's
/// sentence, the generic lead-in with the raw kind, or the error itself.
/// [schedule] reads `wake_not_yours` as a schedule refusal.
({String text, String? code}) workFailure(
  AppLocalizations l,
  Object error, {
  bool schedule = false,
}) {
  final kind = refusalKindOf(error);
  if (kind == null) return (text: l.workActionFailed('$error'), code: null);
  final sentence = workRefusalSentence(l, kind, schedule: schedule);
  return sentence == null
      ? (text: l.workRefusalUnknown, code: kind)
      : (text: sentence, code: null);
}
