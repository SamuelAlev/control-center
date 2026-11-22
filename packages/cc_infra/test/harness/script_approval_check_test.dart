import 'dart:async';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/harness/script_approval_check.dart';
import 'package:test/test.dart';

/// A script's approval budget on the gateway (a push or an environment
/// command a run's command makes while one of its scripts is in flight): the
/// ask is counted before the card is awaited, so asks that arrive together
/// cannot all pass a check none of them has counted yet, and an ask whose
/// card never went up is given back.
void main() {
  const push = {ActionClass.gitPush};
  late _HeldApprover approver;
  late List<GuardAudit> audits;
  late ActionGuardService guard;

  setUp(() {
    approver = _HeldApprover();
    audits = [];
    guard = ActionGuardService(
      repository: _NoRules(),
      confirmationPort: approver,
      onAudit: audits.add,
    );
  });

  Future<GuardVerdict> ask(
    ScriptApprovalBudget budget, {
    Future<GuardVerdict> Function(
      void Function(bool)? onPersonWait,
      String? Function()? beforeCard,
    )?
    check,
  }) => checkWithinScriptApprovals(
    guard: guard,
    approvals: [budget],
    workspaceId: 'ws-1',
    classes: push,
    request: const ActionRequest(classes: push),
    actionSummary: 'push',
    check:
        check ??
        (onPersonWait, beforeCard) => guard.check(
          workspaceId: 'ws-1',
          classes: push,
          actionSummary: 'push',
          request: const ActionRequest(classes: push),
          onPersonWait: onPersonWait,
          beforeCard: beforeCard,
        ),
  );

  /// A card the resolution did not foresee: resolved under the space's
  /// propose-only dial, which refuses without asking, while the check runs
  /// without it, as when the policy changes between the two.
  Future<GuardVerdict> unforeseen(ScriptApprovalBudget budget) =>
      checkWithinScriptApprovals(
        guard: guard,
        approvals: [budget],
        workspaceId: 'ws-1',
        classes: push,
        request: const ActionRequest(classes: push),
        actionSummary: 'push',
        autonomy: AutonomyLevel.proposeOnly,
        check: (onPersonWait, beforeCard) => guard.check(
          workspaceId: 'ws-1',
          classes: push,
          actionSummary: 'push',
          request: const ActionRequest(classes: push),
          onPersonWait: onPersonWait,
          beforeCard: beforeCard,
        ),
      );

  test('30 asks that arrive together put up '
      '${CodeModeLimits.maxApprovalAsks} cards and refuse the rest with the '
      'true reason, in the audit trail too', () async {
    final budget = ScriptApprovalBudget();
    final settled = <GuardVerdict>[];
    final all = [for (var i = 0; i < 30; i++) ask(budget).then(settled.add)];
    for (var i = 0; i < 50 && settled.length < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(approver.cards, CodeModeLimits.maxApprovalAsks);
    expect(settled, hasLength(20));
    expect(
      settled,
      everyElement(
        isA<GuardVerdict>()
            .having((v) => v.allowed, 'allowed', isFalse)
            .having(
              (v) => v.reason,
              'reason',
              ScriptApprovalBudget.exhaustedReason,
            ),
      ),
    );
    final refused = [
      for (final a in audits)
        if (a.decision == ActionDecision.deny) a,
    ];
    expect(refused, hasLength(20));
    expect(
      refused.map((a) => a.reason),
      everyElement(ScriptApprovalBudget.exhaustedReason),
    );
    approver.release.complete();
    await Future.wait(all);
    expect(approver.cards, CodeModeLimits.maxApprovalAsks);
    expect(budget.asked, CodeModeLimits.maxApprovalAsks);
  });

  test('an ask whose card never went up is given back', () async {
    final budget = ScriptApprovalBudget();
    // The policy would ask, but the check is answered without a card (a
    // standing approval or an earlier answer covered the call).
    final verdict = await ask(
      budget,
      check: (_, _) async => const GuardVerdict.allow(),
    );
    expect(verdict.allowed, isTrue);
    expect(budget.asked, 0);
    // And when the check throws.
    await expectLater(
      ask(budget, check: (_, _) async => throw StateError('broken')),
      throwsStateError,
    );
    expect(budget.asked, 0);
    expect(approver.cards, 0);
  });

  group('a card the resolution did not foresee takes the same step', () {
    test('past the limit it is refused without a card, with the true '
        'reason, in the audit trail too', () async {
      final budget = ScriptApprovalBudget();
      for (var i = 0; i < CodeModeLimits.maxApprovalAsks; i++) {
        budget.asking();
      }
      final verdict = await unforeseen(budget);
      expect(verdict.allowed, isFalse);
      expect(verdict.reason, ScriptApprovalBudget.exhaustedReason);
      expect(approver.cards, 0);
      expect(budget.asked, CodeModeLimits.maxApprovalAsks);
      expect(audits.map((a) => (a.decision, a.reason)), [
        (ActionDecision.deny, ScriptApprovalBudget.exhaustedReason),
      ]);
    });

    test('after a decline it is refused without a card', () async {
      final budget = ScriptApprovalBudget()
        ..asking()
        ..answered(approved: false, unanswered: false);
      final verdict = await unforeseen(budget);
      expect(verdict.reason, ScriptApprovalBudget.declinedReason);
      expect(approver.cards, 0);
    });

    test('within the budget it goes up and is counted once', () async {
      final budget = ScriptApprovalBudget();
      approver.release.complete();
      final verdict = await unforeseen(budget);
      expect(verdict.allowed, isTrue);
      expect(approver.cards, 1);
      expect(budget.asked, 1);
    });
  });

  test('a card nobody answered refuses only its call: the next call asks '
      'again, and a person\'s decline still refuses the rest without a '
      'card', () async {
    final port = _ScriptedApprover([null, false]);
    guard = ActionGuardService(
      repository: _NoRules(),
      confirmationPort: port,
      onAudit: audits.add,
    );
    final budget = ScriptApprovalBudget();

    final expired = await ask(budget);
    expect(expired.allowed, isFalse);
    expect(expired.unanswered, isTrue);
    expect(budget.declined, isFalse);

    final declined = await ask(budget);
    expect(declined.allowed, isFalse);
    expect(declined.unanswered, isFalse);
    expect(port.requests, hasLength(2));

    final refused = await ask(budget);
    expect(refused.reason, ScriptApprovalBudget.declinedReason);
    expect(port.requests, hasLength(2));
    expect(budget.asked, 2);
  });

  test('a script a person declined once is refused without a card', () async {
    final budget = ScriptApprovalBudget()
      ..asking()
      ..answered(approved: false, unanswered: false);
    final verdict = await ask(budget);
    expect(verdict.reason, ScriptApprovalBudget.declinedReason);
    expect(approver.cards, 0);
  });
}

/// Answers each card with the next of [answers]; null is a card nobody
/// answered, which calls `onUnanswered` and resolves no, as the server's
/// pending-confirmation registry does on a timeout or an expiry.
class _ScriptedApprover implements ConfirmationPort {
  _ScriptedApprover(this.answers);

  final List<bool?> answers;
  final requests = <ConfirmationRequest>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    requests.add(request);
    final answer = answers.removeAt(0);
    if (answer == null) {
      request.onUnanswered?.call();
      return false;
    }
    return answer;
  }
}

/// Holds every card until [release], then approves it.
class _HeldApprover implements ConfirmationPort {
  int cards = 0;
  final release = Completer<void>();

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    cards++;
    await release.future;
    return true;
  }
}

class _NoRules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
