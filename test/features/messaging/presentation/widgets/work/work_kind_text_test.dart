import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_kind_text.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  test('every wake hold and skip kind the server names has a sentence', () {
    const kinds = [
      WakeStateReasons.stopped,
      WakeStateReasons.attempts,
      WakeStateReasons.agentDeleted,
      WakeStateReasons.agentNotDispatchable,
      WakeStateReasons.agentPaused,
      WakeStateReasons.personRemoved,
      WakeStateReasons.budgetBlocked,
      WakeStateReasons.takeOver,
      WakeStateReasons.rateCapConversation,
      WakeStateReasons.rateCapWorkspace,
      WakeStateReasons.liveRunNoInput,
      WakeStateReasons.liveRunOtherOptions,
      WakeStateReasons.liveRunOtherPerson,
      WakeStateReasons.dispatchRefused,
      WakeStateReasons.sandboxUnavailable,
      WakeStateReasons.readOnlyUnavailable,
      WakeStateReasons.serverStopped,
      WakeStateReasons.serverRestarted,
      WakeStateReasons.guardFailed,
      WakeStateReasons.limit,
      WakeStateReasons.limitRunLive,
      'wake_missed',
      'pipeline_run_ended',
      'goal_ended',
      'goal_budget_exhausted',
      'goal_review_stale',
      'goal_paused',
      'goal_held',
      'goal_stopped',
      'ask_settled',
      'rule_cost_cap',
    ];
    final sentences = {for (final k in kinds) k: wakeKindSentence(l10n, k)};
    expect([
      for (final e in sentences.entries)
        if (e.value == null) e.key,
    ], isEmpty);
    expect(wakeKindSentence(l10n, 'never_heard_of_it'), isNull);
  });

  test('every wake reason has an origin label; replies name their agent', () {
    for (final r in WakeReason.values) {
      expect(wakeOriginLabel(l10n, r), isNotEmpty, reason: '$r');
    }
    expect(
      wakeOriginLabel(l10n, WakeReason.peerReply, agentName: 'Ada'),
      'Reply from Ada',
    );
    expect(
      wakeOriginLabel(l10n, WakeReason.peerMessage, agentName: 'Ada'),
      'Message from Ada',
    );
  });

  test('the kinds the server fix rounds added have words', () {
    for (final kind in [
      'orchestration_not_yours',
      'orchestration_cap_invalid',
      'steering_not_yours',
      'steering_held_by_limit',
      'orchestration_cap_changed',
      'improvement_review_cooldown',
      'improvement_review_queued',
      'improvement_agent_not_found',
      'agent_not_found',
      'improvement_changed_since',
      'wake_queue_full',
    ]) {
      expect(workRefusalSentence(l10n, kind), isNotNull, reason: kind);
    }
    expect(wakeKindSentence(l10n, 'live_run_no_input'), isNotNull);
    expect(wakeKindSentence(l10n, 'rule_folded'), l10n.wakeKindRuleFolded);
    expect(workRefusalSentence(l10n, 'still_unknown'), isNull);
    // orchestration.update is gone, and with it this kind.
    expect(workRefusalSentence(l10n, 'orchestration_cap_use_raise'), isNull);
    expect(
      workRefusalMessage(l10n, 'still_unknown'),
      '${l10n.workRefusalUnknown} still_unknown',
    );
  });

  test('every way a question to another agent fails has words; a detail '
      'after the colon is ignored', () {
    for (final error in [
      'no_output',
      'run_failed',
      'stopped_by_person',
      'budget',
      'silence',
      'usage_limit',
      'not_delivered',
    ]) {
      expect(peerAskFailureSentence(l10n, error), isNotNull, reason: error);
    }
    expect(
      peerAskFailureSentence(l10n, 'usage_limit: person'),
      l10n.peerAskFailUsageLimit,
    );
    expect(peerAskFailureSentence(l10n, 'novel'), isNull);
  });

  test('hold details: known, valued, unknown', () {
    final stalled = goalHoldDetailSentence(l10n, 'stalled_waiting');
    expect(stalled.sentence, 'Waiting, after segments without progress.');
    final checker = goalHoldDetailSentence(l10n, 'checker_unavailable');
    expect(checker.sentence, startsWith('Its checker agent is unavailable'));
    final skipped = goalHoldDetailSentence(l10n, 'wake_skipped: agent_paused');
    expect(skipped.followUp, 'The agent is paused.');
    final unknown = goalHoldDetailSentence(l10n, 'odd: thing');
    expect(unknown.sentence, isNull);
    expect(unknown.code, 'odd: thing');
  });

  test('refusals: each family by kind, and an unknown kind names itself', () {
    expect(
      workRefusalMessage(l10n, 'watch_target_unreadable'),
      "You can't read what this would watch.",
    );
    expect(
      workRefusalMessage(l10n, 'wake_lineage_ended'),
      'This chain of wakes has used its runs or its time.',
    );
    expect(
      workRefusalMessage(l10n, 'goal_checker_is_goal_agent'),
      'The checker must be another agent than the one doing the work.',
    );
    expect(
      workRefusalMessage(l10n, 'wake_settled'),
      'This wake has already settled.',
    );
    expect(
      workRefusalMessage(l10n, 'brand_new_kind'),
      'The server refused this: brand_new_kind',
    );
    expect(wakeRuleEndReasonSentence(l10n, 'member_removed'), isNotNull);
    expect(wakeRuleEndReasonSentence(l10n, 'novel'), isNull);
  });

  test(
    'inert text neutralizes control and bidi characters, keeps the rest',
    () {
      expect(
        inertText('a\u001b[31mb\u202Ec\u2066d'),
        'a\uFFFD[31mb\uFFFDc\uFFFDd',
      );
      expect(inertText('line one\nline two'), 'line one\nline two');
      expect(
        inertText('line one\nline two', singleLine: true),
        'line one line two',
      );
      expect(inertText('**bold** [x](y)'), '**bold** [x](y)');
    },
  );
}
