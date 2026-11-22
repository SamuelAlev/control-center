/// The localized sentences for the server's long-running-work kinds: why a
/// wake waits or was skipped, a goal's hold detail, a schedule's end reason,
/// and the refusal kinds of goals, schedules and wakes.
///
/// Each table maps a wire kind to one sentence and returns null for a kind
/// this version does not know; the caller then shows its generic lead-in
/// (`wakeKindUnknown`, `workRefusalUnknown`, `goalHoldDetail…`) followed by the
/// raw kind in code style (`KindSentence`). A sentence is never built from
/// the server's message text.
library;

import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:control_center/l10n/app_localizations.dart';

/// Why a wake waits, is held or was skipped: a `state_reason` or a skip kind.
String? wakeKindSentence(AppLocalizations l10n, String? kind) {
  if (kind == null || kind.isEmpty) {
    return null;
  }
  if (kind == 'rule_folded') {
    return l10n.wakeKindRuleFolded;
  }
  if (kind.startsWith('rule_')) {
    return l10n.wakeKindRuleEnded;
  }
  return switch (kind) {
    'stopped' => l10n.wakeKindStopped,
    'attempts' => l10n.wakeKindAttempts,
    'agent_deleted' => l10n.wakeKindAgentDeleted,
    'agent_not_dispatchable' => l10n.wakeKindAgentNotDispatchable,
    'agent_paused' => l10n.wakeKindAgentPaused,
    'person_removed' => l10n.wakeKindPersonRemoved,
    'budget_blocked' => l10n.wakeKindBudgetBlocked,
    'take_over' => l10n.wakeKindTakeOver,
    'rate_cap_conversation' => l10n.wakeKindRateCapConversation,
    'rate_cap_workspace' => l10n.wakeKindRateCapWorkspace,
    'live_run_no_input' => l10n.wakeKindLiveRunNoInput,
    'live_run_other_options' => l10n.wakeKindLiveRunOtherOptions,
    'live_run_other_person' => l10n.wakeKindLiveRunOtherPerson,
    'dispatch_refused' => l10n.wakeKindDispatchRefused,
    'sandbox_unavailable' => l10n.wakeKindSandboxUnavailable,
    'read_only_unavailable' => l10n.wakeKindReadOnlyUnavailable,
    'server_stopped' => l10n.wakeKindServerStopped,
    'server_restarted' => l10n.wakeKindServerRestarted,
    'guard_failed' => l10n.wakeKindGuardFailed,
    'limit' => l10n.wakeKindLimit,
    'limit_run_live' => l10n.wakeKindLimitRunLive,
    'wake_missed' => l10n.wakeKindWakeMissed,
    'pipeline_run_ended' => l10n.wakeKindPipelineRunEnded,
    'goal_ended' => l10n.wakeKindGoalEnded,
    'goal_budget_exhausted' => l10n.wakeKindGoalBudgetExhausted,
    'goal_review_stale' => l10n.wakeKindGoalReviewStale,
    'goal_paused' => l10n.wakeKindGoalPaused,
    'goal_held' => l10n.wakeKindGoalHeld,
    'goal_stopped' => l10n.wakeKindGoalStopped,
    'ask_settled' => l10n.wakeKindAskSettled,
    'wake_rule_ended' => l10n.wakeKindRuleEnded,
    _ => null,
  };
}

/// The chip label for what raised a wake. [agentName] names the agent a
/// reply, message or finished work came from, when known.
String wakeOriginLabel(
  AppLocalizations l10n,
  WakeReason reason, {
  String? agentName,
}) => switch (reason) {
  WakeReason.goalContinuation => l10n.wakeOriginGoal,
  WakeReason.goalVerification => l10n.wakeOriginGoalCheck,
  WakeReason.goalReview => l10n.wakeOriginGoalReview,
  WakeReason.schedule => l10n.wakeOriginSchedule,
  WakeReason.watch => l10n.wakeOriginWatch,
  WakeReason.peerReply =>
    agentName == null
        ? l10n.wakeOriginReply
        : l10n.wakeOriginReplyFrom(agentName),
  WakeReason.peerMessage =>
    agentName == null
        ? l10n.wakeOriginMessage
        : l10n.wakeOriginMessageFrom(agentName),
  WakeReason.childCompleted =>
    agentName == null
        ? l10n.wakeOriginWorkFinished
        : l10n.wakeOriginWorkFinishedBy(agentName),
  WakeReason.limitReset => l10n.wakeOriginLimitReset,
  WakeReason.recovery => l10n.wakeOriginRecovery,
  WakeReason.userMessage => l10n.wakeOriginMessage,
  WakeReason.assignment => l10n.wakeOriginAssignment,
  WakeReason.pipelineStep => l10n.wakeOriginPipelineStep,
  WakeReason.improvementReview => l10n.wakeOriginImprovementReview,
};

/// A goal's `holdDetail`, read. Some details carry a value after a colon:
/// `check_broken: <command>` gives `code` the command, `wake_skipped: <kind>`
/// gives the skip kind's sentence as `followUp`. A null `sentence` means a
/// detail this version does not name (its raw text is then `code`).
typedef GoalHoldDetailText = ({
  String? sentence,
  String? code,
  String? followUp,
});

/// The sentence for a goal's hold detail (see [GoalHoldDetailText]).
GoalHoldDetailText goalHoldDetailSentence(
  AppLocalizations l10n,
  String detail,
) {
  final colon = detail.indexOf(':');
  final head = (colon < 0 ? detail : detail.substring(0, colon)).trim();
  final tail = colon < 0 ? '' : detail.substring(colon + 1).trim();
  switch (head) {
    case 'check_broken':
      return (
        sentence: l10n.goalHoldDetailCheckBroken,
        code: tail.isEmpty ? null : tail,
        followUp: null,
      );
    case 'wake_skipped':
      final reason = wakeKindSentence(l10n, tail);
      return (
        sentence: l10n.goalHoldDetailWakeSkipped,
        code: reason == null && tail.isNotEmpty ? tail : null,
        followUp: reason,
      );
    case 'input':
      return (sentence: l10n.goalHoldDetailInput, code: null, followUp: null);
  }
  final sentence = switch (head) {
    'stalled' => l10n.goalHoldDetailStalled,
    'stalled_waiting' => l10n.goalHoldDetailStalledWaiting,
    'verification_failed' => l10n.goalHoldDetailVerificationFailed,
    'cannot_verify' => l10n.goalHoldDetailCannotVerify,
    'sandbox_unavailable' => l10n.goalHoldDetailSandboxUnavailable,
    'checker_unavailable' => l10n.goalHoldDetailCheckerUnavailable,
    'claim_pending' => l10n.goalHoldDetailClaimPending,
    'unanswered' => l10n.goalHoldDetailUnanswered,
    'limit_parks' => l10n.goalHoldDetailLimitParks,
    _ => null,
  };
  return (
    sentence: sentence,
    code: sentence == null ? detail : null,
    followUp: null,
  );
}

/// Why a schedule ended (`endReason` / `reason` on the wire).
String? wakeRuleEndReasonSentence(AppLocalizations l10n, String? reason) =>
    switch (reason) {
      'fired' => l10n.wakeRuleEndFired,
      'expired' => l10n.wakeRuleEndExpired,
      'run_cap' => l10n.wakeRuleEndRunCap,
      'cost_cap' => l10n.wakeRuleEndCostCap,
      'goal_ended' => l10n.wakeRuleEndGoalEnded,
      'cancelled' => l10n.wakeRuleEndCancelled,
      'member_removed' => l10n.wakeRuleEndMemberRemoved,
      'invalid_row' => l10n.wakeRuleEndInvalidRow,
      _ => null,
    };

/// A schedule refusal (`data.kind` from `wakeRules.*`, `/loop`, `/schedule`).
String? wakeRuleRefusalSentence(AppLocalizations l10n, String? kind) =>
    switch (kind) {
      'wake_interval_too_short' => l10n.wakeRuleRefusalIntervalTooShort,
      'wake_too_soon' => l10n.wakeRuleRefusalTooSoon,
      'wake_lineage_ended' => l10n.wakeRuleRefusalLineageEnded,
      'watch_target_unreadable' => l10n.wakeRuleRefusalWatchTargetUnreadable,
      'wake_expiry_required' => l10n.wakeRuleRefusalExpiryRequired,
      'wake_limit_reached' => l10n.wakeRuleRefusalLimitReached,
      'wake_invalid_when' => l10n.wakeRuleRefusalInvalidWhen,
      'wake_note_too_long' => l10n.wakeRuleRefusalNoteTooLong,
      'wake_expiry_too_long' => l10n.wakeRuleRefusalExpiryTooLong,
      'wake_limit_out_of_range' => l10n.wakeRuleRefusalLimitOutOfRange,
      'wake_next_outside_loop' => l10n.wakeRuleRefusalNextOutsideLoop,
      'wake_watch_refused' => l10n.wakeRuleRefusalWatchRefused,
      'wake_rule_ended' => l10n.wakeRuleRefusalRuleEnded,
      _ => null,
    };

/// A goal refusal (`data.kind` from `agentGoalRuns.*` and `/goal`).
String? goalRefusalSentence(AppLocalizations l10n, String? kind) =>
    switch (kind) {
      'goal_already_active' => l10n.goalRefusalAlreadyActive,
      'goal_not_in_review' => l10n.goalRefusalNotInReview,
      'goal_evidence_incomplete' => l10n.goalRefusalEvidenceIncomplete,
      'goal_claim_pending' => l10n.goalRefusalClaimPending,
      'goal_not_active_segment' => l10n.goalRefusalNotActiveSegment,
      'goal_not_yours' => l10n.goalRefusalNotYours,
      'goal_not_paused' => l10n.goalRefusalNotPaused,
      'goal_contract_invalid' => l10n.goalRefusalContractInvalid,
      'goal_checker_unknown' => l10n.goalRefusalCheckerUnknown,
      'goal_checker_ambiguous' => l10n.goalRefusalCheckerAmbiguous,
      'goal_checker_is_goal_agent' => l10n.goalRefusalCheckerIsGoalAgent,
      'goal_command_invalid' => l10n.goalRefusalCommandInvalid,
      _ => null,
    };

/// A wake refusal (`data.kind` from `wakes.*`).
String? wakeRefusalSentence(AppLocalizations l10n, String? kind) =>
    switch (kind) {
      'wake_not_yours' => l10n.wakeRefusalNotYours,
      'wake_settled' => l10n.wakeRefusalSettled,
      _ => null,
    };

/// A `/refine` or improvement refusal (`data.kind` from `improvements.*`,
/// and `refusalKind` on a refused `/refine` row).
String? improvementRefusalSentence(AppLocalizations l10n, String? kind) =>
    switch (kind) {
      'improvement_review_cooldown' => l10n.improvementRefusalReviewCooldown,
      'improvement_review_queued' => l10n.improvementRefusalQueued,
      'improvement_agent_not_found' ||
      'agent_not_found' => l10n.improvementRefusalAgentNotFound,
      'improvement_changed_since' => l10n.improvementRefusalChangedSince,
      'wake_queue_full' => l10n.workRefusalWakeQueueFull,
      _ => null,
    };

/// A held steering refusal (`data.kind` from `steering.release`).
String? steeringRefusalSentence(AppLocalizations l10n, String? kind) =>
    switch (kind) {
      'steering_held_by_limit' => l10n.steeringRefusalHeldByLimit,
      'steering_not_yours' => l10n.steeringRefusalNotYours,
      _ => null,
    };

/// An orchestration refusal (`data.kind`): `orchestration.raiseCap`, and
/// `orchestration_not_yours` also from `approveNodes` and `continueNode`.
String? orchestrationRefusalSentence(AppLocalizations l10n, String? kind) =>
    switch (kind) {
      'orchestration_not_yours' => l10n.orchestrationRefusalNotYours,
      'orchestration_cap_invalid' => l10n.orchestrationRefusalCapInvalid,
      'orchestration_cap_changed' => l10n.orchestrationRefusalCapChanged,
      _ => null,
    };

/// Any refusal kind the conversation surfaces know, or null for one this
/// version does not name.
String? workRefusalSentence(AppLocalizations l10n, String? kind) =>
    goalRefusalSentence(l10n, kind) ??
    wakeRuleRefusalSentence(l10n, kind) ??
    wakeRefusalSentence(l10n, kind) ??
    improvementRefusalSentence(l10n, kind) ??
    steeringRefusalSentence(l10n, kind) ??
    orchestrationRefusalSentence(l10n, kind);

/// Any refusal kind the conversation surfaces may meet, for a toast: the
/// localized sentence, or the generic lead-in with the raw kind.
String workRefusalMessage(AppLocalizations l10n, String kind) =>
    workRefusalSentence(l10n, kind) ?? '${l10n.workRefusalUnknown} $kind';

/// Why a question to another agent failed (`PeerAsk.error`: a kind, or
/// `kind: detail`). Null for a kind this version does not name.
String? peerAskFailureSentence(AppLocalizations l10n, String? error) {
  final head = error?.split(':').first.trim();
  return switch (head) {
    'no_output' => l10n.peerAskFailNoOutput,
    'run_failed' => l10n.peerAskFailRunFailed,
    'stopped_by_person' => l10n.peerAskFailStoppedByPerson,
    'budget' => l10n.peerAskFailBudget,
    'silence' => l10n.peerAskFailSilence,
    'usage_limit' => l10n.peerAskFailUsageLimit,
    'not_delivered' => l10n.peerAskFailNotDelivered,
    _ => null,
  };
}

/// An ask's status, as a chip label.
String peerAskStatusLabel(AppLocalizations l10n, PeerAskStatus status) =>
    switch (status) {
      PeerAskStatus.pending => l10n.peerAskStatusPending,
      PeerAskStatus.answered => l10n.peerAskStatusAnswered,
      PeerAskStatus.failed => l10n.peerAskStatusFailed,
      PeerAskStatus.expired => l10n.peerAskStatusExpired,
      PeerAskStatus.cancelled => l10n.peerAskStatusCancelled,
    };

/// An ask's kind, as a label.
String peerAskKindLabel(AppLocalizations l10n, PeerAskKind kind) =>
    switch (kind) {
      PeerAskKind.ask => l10n.peerAskKindAsk,
      PeerAskKind.consult => l10n.peerAskKindConsult,
      PeerAskKind.review => l10n.peerAskKindReview,
    };
