@TestOn('browser')
library;

import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/work_kind_text.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:flutter_test/flutter_test.dart';

import 'work_test_host.dart';

RemoteRpcException _refusal(String kind) =>
    RemoteRpcException(-32000, 'English message', {'kind': kind});

void main() {
  late AppLocalizations l;

  setUpAll(() async => l = await english());

  test('every wake kind the server sends has a sentence', () {
    for (final kind in [
      'stopped',
      'attempts',
      'agent_deleted',
      'agent_not_dispatchable',
      'agent_paused',
      'person_removed',
      'budget_blocked',
      'take_over',
      'rate_cap_conversation',
      'rate_cap_workspace',
      'live_run_no_input',
      'live_run_other_options',
      'live_run_other_person',
      'dispatch_refused',
      'sandbox_unavailable',
      'read_only_unavailable',
      'server_stopped',
      'server_restarted',
      'guard_failed',
      'limit',
      'limit_run_live',
      'wake_missed',
      'pipeline_run_ended',
      'goal_ended',
      'goal_budget_exhausted',
      'goal_review_stale',
      'goal_paused',
      'goal_held',
      'goal_stopped',
      'ask_settled',
      'wake_rule_ended',
      // The schedule's own reasons (`WakeRuleService.ownReasonPrefix`).
      'rule_ended',
      'rule_inactive',
      'rule_paused',
      'rule_busy',
      'rule_folded',
      'rule_superseded',
      'rule_notified',
      'rule_limit_parked',
    ]) {
      expect(wakeKindSentence(l, kind), isNotNull, reason: kind);
    }
    expect(wakeKindSentence(l, 'not_a_kind'), isNull);
    // A schedule reason this version does not name is not read as "ended".
    expect(wakeKindSentence(l, 'rule_new_reason'), isNull);
    expect(wakeKindSentence(l, 'rule_folded'), isNot(l.wakeKindRuleEnded));
  });

  test('every schedule refusal kind has a sentence', () {
    for (final kind in [
      WakeRuleRefusals.nextOutsideLoop,
      WakeRuleRefusals.invalidWhen,
      WakeRuleRefusals.noteTooLong,
      WakeRuleRefusals.expiryTooLong,
      WakeRuleRefusals.limitOutOfRange,
      WakeRuleRefusals.watchRefused,
      WakeRuleRefusals.ruleEnded,
      'wake_interval_too_short',
      'wake_too_soon',
      'wake_lineage_ended',
      'watch_target_unreadable',
      'wake_expiry_required',
      'wake_limit_reached',
    ]) {
      expect(wakeRuleRefusalSentence(l, kind), isNotNull, reason: kind);
    }
  });

  test('every goal refusal kind has a sentence', () {
    for (final kind in [
      'goal_already_active',
      'goal_not_in_review',
      'goal_evidence_incomplete',
      'goal_claim_pending',
      'goal_not_active_segment',
      'goal_not_yours',
      'goal_not_paused',
      'goal_contract_invalid',
      'goal_checker_unknown',
      'goal_checker_ambiguous',
      'goal_checker_is_goal_agent',
      'goal_command_invalid',
    ]) {
      expect(goalRefusalSentence(l, kind), isNotNull, reason: kind);
    }
  });

  test('every end reason has a sentence', () {
    for (final reason in [
      'fired',
      'expired',
      'run_cap',
      'cost_cap',
      'goal_ended',
      'cancelled',
      'member_removed',
      'invalid_row',
    ]) {
      expect(wakeRuleEndSentence(l, reason), isNotNull, reason: reason);
    }
  });

  test('every wake reason has an origin label', () {
    for (final reason in WakeReason.values) {
      expect(wakeOriginLabel(l, reason), isNotEmpty);
    }
    expect(
      wakeOriginLabel(l, WakeReason.peerReply, agentName: 'Reviewer'),
      l.wakeOriginReplyFrom('Reviewer'),
    );
  });

  test('/refine and held steering refusals have sentences', () {
    for (final kind in [
      'improvement_review_cooldown',
      'improvement_review_queued',
      'improvement_agent_not_found',
      'steering_held_by_limit',
      'steering_not_yours',
    ]) {
      expect(workRefusalSentence(l, kind), isNotNull, reason: kind);
      expect(workFailure(l, _refusal(kind)).code, isNull, reason: kind);
    }
    expect(
      workFailure(l, _refusal('steering_held_by_limit')).text,
      l.steeringRefusalHeldByLimit,
    );
    expect(workRefusalSentence(l, 'x_new'), isNull);
    // Steering's own failure text: no write grant, then the steering kinds,
    // then the error itself.
    expect(
      steeringFailureText(l, _refusal('repo_grant_required')),
      l.steeringRefusalNeedsWrite,
    );
    expect(
      steeringFailureText(l, _refusal('steering_not_yours')),
      l.steeringRefusalNotYours,
    );
    expect(steeringFailureText(l, StateError('boom')), 'Bad state: boom');
    // Gone from the server: no longer named.
    expect(workRefusalSentence(l, 'orchestration_cap_use_raise'), isNull);
  });

  test('a failure reads its kind, never the English message', () {
    expect(
      workFailure(l, _refusal('goal_not_yours')).text,
      l.goalRefusalNotYours,
    );
    expect(
      workFailure(l, _refusal('wake_not_yours')).text,
      l.wakeRefusalNotYours,
    );
    expect(
      workFailure(l, _refusal('wake_not_yours'), schedule: true).text,
      l.wakeRuleRefusalNotYours,
    );
    final unknown = workFailure(l, _refusal('x_new'));
    expect(unknown.text, l.workRefusalUnknown);
    expect(unknown.code, 'x_new');
    expect(workFailure(l, StateError('boom')).code, isNull);
    expect(refusalKindOf(RemoteRpcException(1, 'm')), isNull);
  });

  test('hold details: commands and skip kinds are split out as data', () {
    final broken = goalHoldDetailText(l, 'check_broken: npm test');
    expect(broken.sentence, l.goalHoldDetailCheckBroken);
    expect(broken.code, 'npm test');
    final skipped = goalHoldDetailText(l, 'wake_skipped: agent_paused');
    expect(skipped.sentence, l.goalHoldDetailWakeSkipped);
    expect(skipped.followUp, l.wakeKindAgentPaused);
    expect(goalHoldDetailText(l, 'input:w1').sentence, l.goalHoldDetailInput);
    final unknown = goalHoldDetailText(l, 'new_detail');
    expect(unknown.sentence, isNull);
    expect(unknown.code, 'new_detail');
  });
}
