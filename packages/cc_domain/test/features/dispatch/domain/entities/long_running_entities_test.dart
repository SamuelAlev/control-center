import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 1, 12);

  group('Wake', () {
    Wake wake({
      String id = 'w-1',
      String payload = 'go on',
      String dedupKey = 'k',
      WakeState state = WakeState.pending,
      String? stateReason,
      List<String> chain = const [],
      int attempt = 0,
      DateTime? expiresAt,
    }) => Wake(
      id: id,
      workspaceId: 'ws',
      spaceId: 'sp',
      conversationId: 'c',
      agentId: 'a',
      reason: WakeReason.schedule,
      payload: payload,
      dedupKey: dedupKey,
      notBefore: t0,
      expiresAt: expiresAt,
      chain: chain,
      state: state,
      stateReason: stateReason,
      attempt: attempt,
      createdAt: t0,
    );

    test('defaults', () {
      final w = wake();
      expect(w.lane, WakeLane.aside);
      expect(w.detail, WakeDetail.empty);
      expect(w.runOptions, isNull);
      expect(w.expectsReply, isFalse);
      expect(w.isSettled, isFalse);
    });

    test('validates its fields', () {
      expect(() => wake(id: ''), throwsArgumentError);
      expect(
        () => wake(payload: 'x' * (Wake.maxPayloadLength + 1)),
        throwsArgumentError,
      );
      expect(() => wake(dedupKey: ''), throwsArgumentError);
      expect(
        () => wake(dedupKey: 'k' * (Wake.maxDedupKeyLength + 1)),
        throwsArgumentError,
      );
      expect(() => wake(stateReason: ''), throwsArgumentError);
      expect(
        () => wake(stateReason: 'r' * (Wake.maxStateReasonLength + 1)),
        throwsArgumentError,
      );
      expect(
        () => wake(chain: List.filled(Wake.maxChainLength + 1, 'a')),
        throwsArgumentError,
      );
      expect(() => wake(chain: const ['']), throwsArgumentError);
      expect(() => wake(attempt: -1), throwsArgumentError);
      expect(
        () => wake(expiresAt: t0.subtract(const Duration(seconds: 1))),
        throwsArgumentError,
      );
    });

    test('due and expiry', () {
      final w = wake(expiresAt: t0.add(const Duration(hours: 1)));
      expect(w.isDueAt(t0), isTrue);
      expect(w.isDueAt(t0.subtract(const Duration(seconds: 1))), isFalse);
      expect(
        wake(state: WakeState.held, stateReason: 'paused').isDueAt(t0),
        isFalse,
      );
      expect(w.expiredAt(t0), isFalse);
      expect(w.expiredAt(t0.add(const Duration(hours: 1))), isTrue);
      expect(wake().expiredAt(DateTime.utc(2100)), isFalse);
    });

    test('equality, hash and copyWith', () {
      expect(wake(), wake());
      expect(wake().hashCode, wake().hashCode);
      expect(wake(chain: const ['x']), isNot(wake(chain: const ['y'])));
      final settled = wake().copyWith(
        state: WakeState.delivered,
        deliveredRunId: 'run-1',
        settledAt: t0,
      );
      expect(settled.isSettled, isTrue);
      expect(
        settled.copyWith(removeDeliveredRunId: true).deliveredRunId,
        isNull,
      );
      expect(wake().chain, isA<List<String>>());
      expect(
        () => wake(chain: const ['a']).chain.add('b'),
        throwsUnsupportedError,
      );
    });
  });

  group('WakeRule', () {
    WakeRule rule({
      WakeTrigger? trigger,
      String note = 'n',
      int costCapMicros = 100,
      int? maxRuns,
      int runCount = 0,
      int costMicros = 0,
      int? nextDelaySeconds,
      WakeRuleStatus status = WakeRuleStatus.active,
      WakeRuleEndReason? endReason,
      DateTime? expiresAt,
    }) => WakeRule(
      id: 'r',
      workspaceId: 'ws',
      spaceId: 'sp',
      conversationId: 'c',
      agentId: 'a',
      trigger: trigger ?? Every(const Duration(hours: 1)),
      note: note,
      costCapMicros: costCapMicros,
      maxRuns: maxRuns,
      runCount: runCount,
      costMicros: costMicros,
      nextDelaySeconds: nextDelaySeconds,
      expiresAt: expiresAt ?? t0.add(const Duration(days: 7)),
      origin: WakeRuleOrigin.agent,
      status: status,
      endReason: endReason,
      createdAt: t0,
      updatedAt: t0,
    );

    test('validates its fields', () {
      expect(
        () => rule(note: 'x' * (WakeRule.maxNoteLength + 1)),
        throwsArgumentError,
      );
      expect(() => rule(costCapMicros: 0), throwsArgumentError);
      expect(() => rule(maxRuns: 0), throwsArgumentError);
      expect(() => rule(runCount: -1), throwsArgumentError);
      expect(() => rule(expiresAt: t0), throwsArgumentError);
      expect(() => rule(nextDelaySeconds: 600), throwsArgumentError);
      expect(
        () => rule(trigger: const SelfPaced(), nextDelaySeconds: 30),
        throwsArgumentError,
      );
      expect(
        () => rule(trigger: const SelfPaced(), nextDelaySeconds: 3601),
        throwsArgumentError,
      );
      expect(
        rule(
          trigger: const SelfPaced(),
          nextDelaySeconds: 600,
        ).nextDelaySeconds,
        600,
      );
      expect(() => rule(status: WakeRuleStatus.ended), throwsArgumentError);
      expect(
        () => rule(endReason: WakeRuleEndReason.fired),
        throwsArgumentError,
      );
    });

    test('caps and kinds', () {
      expect(rule(maxRuns: 2, runCount: 2).runCapReached, isTrue);
      expect(rule(maxRuns: 2, runCount: 1).runCapReached, isFalse);
      expect(rule(runCount: 999).runCapReached, isFalse);
      expect(rule(costMicros: 100).costCapReached, isTrue);
      expect(rule(trigger: OnEvent(WakeEventKind.prChecks)).isWatch, isTrue);
      expect(rule().isActive, isTrue);
      expect(rule().expiredAt(t0.add(const Duration(days: 7))), isTrue);
    });

    test('equality, hash and copyWith', () {
      expect(rule(), rule());
      expect(rule().hashCode, rule().hashCode);
      expect(rule(), isNot(rule(trigger: Cron('* * * * *', 'UTC'))));
      final ended = rule().copyWith(
        status: WakeRuleStatus.ended,
        endReason: WakeRuleEndReason.costCap,
      );
      expect(ended.isActive, isFalse);
      expect(ended.endReason, WakeRuleEndReason.costCap);
      final chained = rule().copyWith(
        rootRuleId: 'r-0',
        noteEditedByUserId: 'u-1',
      );
      expect(chained, isNot(rule()));
      expect(chained.rootRuleId, 'r-0');
      expect(chained.noteEditedByUserId, 'u-1');
    });

    test('a lineage names another rule, never on a goal-bound rule', () {
      expect(() => rule().copyWith(rootRuleId: 'r'), throwsArgumentError);
      expect(() => rule().copyWith(rootRuleId: ''), throwsArgumentError);
      expect(
        () => rule().copyWith(rootRuleId: 'r-0', goalId: 'g-1'),
        throwsArgumentError,
      );
    });

    test('every time is UTC; a slot is a whole second', () {
      final local = DateTime(2026, 5, 1, 14, 20, 5, 250);
      final r = WakeRule(
        id: 'r',
        workspaceId: 'ws',
        spaceId: 'sp',
        conversationId: 'c',
        agentId: 'a',
        trigger: Every(const Duration(hours: 1)),
        note: 'n',
        costCapMicros: 1,
        expiresAt: local.add(const Duration(days: 1)),
        lastFiredAt: local,
        nextFireAt: local,
        origin: WakeRuleOrigin.agent,
        createdAt: local,
        updatedAt: local,
      );
      for (final t in [
        r.expiresAt,
        r.lastFiredAt!,
        r.nextFireAt!,
        r.createdAt,
        r.updatedAt,
      ]) {
        expect(t.isUtc, isTrue);
      }
      expect(r.nextFireAt, wakeSlotOf(local));
      expect(r.nextFireAt!.millisecond, 0);
      expect(r.lastFiredAt!.isAtSameMomentAs(local), isTrue);
    });
  });

  group('PeerAsk', () {
    PeerAsk ask({
      String asker = 'a1',
      String recipient = 'a2',
      String questionHash = 'h',
      String? error,
      List<String> chain = const [],
      DateTime? expiresAt,
    }) => PeerAsk(
      id: 'q',
      workspaceId: 'ws',
      askerAgentId: asker,
      askerConversationId: 'c',
      askerSpaceId: 'sp',
      recipientAgentId: recipient,
      questionHash: questionHash,
      error: error,
      chain: chain,
      createdAt: t0,
      expiresAt: expiresAt ?? t0.add(const Duration(hours: 1)),
    );

    test('defaults and validation', () {
      final a = ask();
      expect(a.kind, PeerAskKind.ask);
      expect(a.mode, PeerAskMode.wait);
      expect(a.isPending, isTrue);
      expect(a.replyInline, isFalse);
      expect(() => ask(recipient: 'a1'), throwsArgumentError);
      expect(() => ask(questionHash: ''), throwsArgumentError);
      expect(
        () => ask(error: 'x' * (PeerAsk.maxErrorLength + 1)),
        throwsArgumentError,
      );
      expect(
        () => ask(chain: List.filled(PeerAsk.maxChainLength + 1, 'a')),
        throwsArgumentError,
      );
      expect(() => ask(expiresAt: t0), throwsArgumentError);
    });

    test('expiry, equality and copyWith', () {
      expect(ask().expiredAt(t0.add(const Duration(hours: 1))), isTrue);
      expect(ask(), ask());
      expect(ask().hashCode, ask().hashCode);
      final answered = ask().copyWith(
        status: PeerAskStatus.answered,
        replyMessageId: 'm',
      );
      expect(answered.isPending, isFalse);
      expect(answered, isNot(ask()));
    });

    test('the once-only markers', () {
      final a = ask();
      expect(a.promisedAt, isNull);
      expect(a.blockedNoticedAt, isNull);
      expect(a.stallNoticedRunId, isNull);
      final marked = a.copyWith(
        promisedAt: t0,
        blockedNoticedAt: t0,
        stallNoticedRunId: 'run-1',
      );
      expect(marked, isNot(a));
      expect(marked.hashCode, isNot(a.hashCode));
      expect(
        marked.copyWith(
          removePromisedAt: true,
          removeBlockedNoticedAt: true,
          removeStallNoticedRunId: true,
        ),
        a,
      );
      expect(() => a.copyWith(stallNoticedRunId: ''), throwsArgumentError);
    });

    test('every time is UTC, and equality compares instants', () {
      // A local time, as the database reads one back.
      final local = DateTime.fromMicrosecondsSinceEpoch(
        DateTime.utc(2026, 5, 1, 12).microsecondsSinceEpoch,
      );
      final made = PeerAsk(
        id: 'q',
        workspaceId: 'ws',
        askerAgentId: 'a1',
        askerConversationId: 'c',
        askerSpaceId: 'sp',
        recipientAgentId: 'a2',
        questionHash: 'h',
        createdAt: local,
        expiresAt: local.add(const Duration(hours: 1)),
        settledAt: local,
        promisedAt: local,
        blockedNoticedAt: local,
      );
      for (final at in [
        made.createdAt,
        made.expiresAt,
        made.settledAt!,
        made.promisedAt!,
        made.blockedNoticedAt!,
      ]) {
        expect(at.isUtc, isTrue);
      }
      expect(made.createdAt, DateTime.utc(2026, 5, 1, 12));
      final copied = made.copyWith(promisedAt: local);
      expect(copied.promisedAt!.isUtc, isTrue);
      expect(copied, made);
      expect(copied.hashCode, made.hashCode);
    });
  });

  group('ImprovementProposal', () {
    ImprovementProposal proposal({
      ImprovementKind kind = ImprovementKind.memoryFact,
      ImprovementScope scope = ImprovementScope.agent,
      String? scopeRefId,
      ImprovementOperation operation = ImprovementOperation.add,
      String? targetRef,
      String change = 'c',
      String expected = 'e',
      ImprovementCampaignState campaignState = ImprovementCampaignState.none,
      DateTime? expiresAt,
    }) => ImprovementProposal(
      id: 'p',
      workspaceId: 'ws',
      agentId: 'a',
      kind: kind,
      scope: scope,
      scopeRefId: scopeRefId,
      operation: operation,
      targetRef: targetRef,
      change: change,
      expected: expected,
      campaignState: campaignState,
      createdAt: t0,
      expiresAt: expiresAt ?? t0.add(ImprovementProposal.lifetime),
    );

    test('validation', () {
      expect(
        () => proposal(change: 'x' * (ImprovementProposal.maxChangeLength + 1)),
        throwsArgumentError,
      );
      expect(() => proposal(change: ' '), throwsArgumentError);
      expect(() => proposal(expected: ''), throwsArgumentError);
      expect(
        () => proposal(scope: ImprovementScope.repository),
        throwsArgumentError,
      );
      expect(
        () => proposal(operation: ImprovementOperation.replace),
        throwsArgumentError,
      );
      expect(() => proposal(expiresAt: t0), throwsArgumentError);
    });

    test('a skill change is accepted only after its campaign passed', () {
      expect(proposal().canAccept, isTrue);
      expect(proposal(kind: ImprovementKind.skillEdit).canAccept, isFalse);
      expect(
        proposal(
          kind: ImprovementKind.skillNew,
          campaignState: ImprovementCampaignState.passed,
        ).canAccept,
        isTrue,
      );
    });

    test('evidence round-trips and degrades', () {
      final evidence = ImprovementEvidence(
        runIds: const ['r1'],
        messageIds: const ['m1'],
        checkResults: [
          GoalCheckResult(
            run: 'make test',
            where: GoalCheckLocation.worktree,
            exitCode: 2,
          ),
        ],
      );
      expect(ImprovementEvidence.tryParse(evidence.encode()), evidence);
      expect(ImprovementEvidence.tryParse('nope'), ImprovementEvidence.empty);
      expect(
        () => ImprovementEvidence(
          runIds: List.filled(ImprovementEvidence.maxIds + 1, 'r'),
        ),
        throwsArgumentError,
      );
    });

    test('equality and copyWith', () {
      expect(proposal(), proposal());
      expect(proposal().hashCode, proposal().hashCode);
      expect(
        proposal().copyWith(status: ImprovementStatus.rejected).status,
        ImprovementStatus.rejected,
      );
    });
  });

  group('AgentGoalRun verification state', () {
    AgentGoalRun goal({
      int noProgressStreak = 0,
      int verificationRounds = 0,
      int parkCount = 0,
      String? holdDetail,
      String? checkerAgentId,
      String? lastActivityDigest,
    }) => AgentGoalRun(
      id: 'g',
      workspaceId: 'ws',
      spaceId: 'sp',
      conversationId: 'c',
      agentId: 'a',
      userText: 'ship it',
      costCapMicros: 100,
      noProgressStreak: noProgressStreak,
      verificationRounds: verificationRounds,
      parkCount: parkCount,
      holdDetail: holdDetail,
      checkerAgentId: checkerAgentId,
      lastActivityDigest: lastActivityDigest,
      createdAt: t0,
      updatedAt: t0,
    );

    test('defaults', () {
      final g = goal();
      expect(g.contract, isNull);
      expect(g.hold, isNull);
      expect(g.unattended, GoalUnattendedPolicy.wait);
      expect(g.fresh, isFalse);
      expect(g.verification, isNull);
    });

    test('validation', () {
      expect(() => goal(noProgressStreak: -1), throwsArgumentError);
      expect(() => goal(verificationRounds: -1), throwsArgumentError);
      expect(() => goal(parkCount: -1), throwsArgumentError);
      expect(
        () => goal(holdDetail: 'x' * (AgentGoalRun.maxHoldDetailLength + 1)),
        throwsArgumentError,
      );
      expect(() => goal(checkerAgentId: ''), throwsArgumentError);
      expect(() => goal(lastActivityDigest: ''), throwsArgumentError);
      expect(
        () => goal(
          lastActivityDigest: 'x' * (AgentGoalRun.maxActivityDigestLength + 1),
        ),
        throwsArgumentError,
      );
      expect(
        goal(
          lastActivityDigest: 'x' * AgentGoalRun.maxActivityDigestLength,
        ).lastActivityDigest,
        hasLength(128),
      );
    });

    test('the activity digest takes part in equality and copyWith', () {
      final digested = goal().copyWith(lastActivityDigest: 'd-1');
      expect(digested, isNot(goal()));
      expect(digested.hashCode, isNot(goal().hashCode));
      expect(digested.copyWith(fresh: true).lastActivityDigest, 'd-1');
      expect(digested.copyWith(removeLastActivityDigest: true), goal());
    });

    test('the new fields take part in equality and copyWith', () {
      final held = goal().copyWith(
        hold: GoalHold.limit,
        holdUntil: t0,
        contract: GoalContract(criteria: const ['done']),
        unattended: GoalUnattendedPolicy.assume,
        fresh: true,
      );
      expect(held, isNot(goal()));
      expect(held.hashCode, isNot(goal().hashCode));
      final cleared = held.copyWith(
        removeHold: true,
        removeHoldUntil: true,
        removeContract: true,
      );
      expect(cleared.hold, isNull);
      expect(cleared.holdUntil, isNull);
      expect(cleared.contract, isNull);
      expect(cleared.unattended, GoalUnattendedPolicy.assume);
    });
  });
}
