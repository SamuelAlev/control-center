import 'dart:async';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// The guard tells a caller exactly when it asks a person, and marks the card
/// of a script's call with the script, without changing anything it decides,
/// records or audits.
class _Rules implements ActionPolicyRepository {
  _Rules(this._rules);

  final List<ActionPolicyRule> _rules;

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => _rules;

  @override
  Stream<List<ActionPolicyRule>> watchRules(String workspaceId) =>
      Stream.value(_rules);

  @override
  Future<List<ActionPolicyRule>> rulesForScope(
    String workspaceId,
    ActionScopeType scopeType,
    String scopeId,
  ) async => _rules;

  @override
  Future<ActionPolicyRule?> ruleById(String workspaceId, String id) async =>
      _rules.where((r) => r.id == id).firstOrNull;

  @override
  Future<void> upsertRule(ActionPolicyRule rule) async => _rules.add(rule);

  @override
  Future<void> deleteRule(String workspaceId, String id) async =>
      _rules.removeWhere((r) => r.id == id);
}

/// Answers [answer]; records what it was shown and what the listener had
/// heard when it was asked.
class _Port implements ConfirmationPort {
  _Port({this.answer = true, this.heardBeforeAsk});

  final bool answer;
  final List<bool>? heardBeforeAsk;
  final asked = <ConfirmationRequest>[];
  List<bool>? heardAtAsk;

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    asked.add(request);
    heardAtAsk = [...?heardBeforeAsk];
    return answer;
  }
}

class _Throws implements ConfirmationPort {
  @override
  Future<bool> requestApproval(ConfirmationRequest request) async =>
      throw StateError('the approver went away');
}

/// Lets every card come down with nobody's answer, as the server's
/// pending-confirmation registry does on an expiry: `onUnanswered`, then no.
class _Unanswered implements ConfirmationPort {
  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    request.onUnanswered?.call();
    return false;
  }
}

/// Never answers; resolves false once the card is withdrawn.
class _Withdrawable implements ConfirmationPort {
  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    await request.withdrawn;
    return false;
  }
}

void main() {
  final now = DateTime.utc(2026, 6, 1);
  ActionPolicyRule rule(
    ActionDecision decision, {
    EnforcementLevel enforcement = EnforcementLevel.hard,
  }) => ActionPolicyRule(
    id: 'r-${decision.wire}',
    workspaceId: 'ws',
    scopeType: ActionScopeType.workspace,
    scopeId: '',
    actionClass: ActionClass.gitPush,
    decision: decision,
    enforcement: enforcement,
    createdAt: now,
    updatedAt: now,
  );
  final origin = ScriptCallOrigin(
    parentToolCallId: 'toolu_repl',
    executionId: 'run-1/toolu_repl#2',
  );
  const request = ActionRequest(
    classes: {ActionClass.gitPush},
    refs: ['feature/x'],
  );

  Future<GuardVerdict> check(
    ActionGuardService guard, {
    List<bool>? heard,
    ScriptCallOrigin? withOrigin,
    bool operatorInitiated = false,
    Future<void>? withdrawn,
  }) => guard.check(
    workspaceId: 'ws',
    classes: const {ActionClass.gitPush},
    spaceId: 'sp',
    conversationId: 'conv',
    agentId: 'agent',
    actionSummary: 'git push',
    runId: 'run-1',
    request: request,
    operatorInitiated: operatorInitiated,
    withdrawn: withdrawn,
    origin: withOrigin,
    onPersonWait: heard?.add,
  );

  test('a prompt tells the listener right before the card and right after '
      'the answer, and the card names the script', () async {
    final heard = <bool>[];
    final port = _Port(heardBeforeAsk: heard);
    final guard = ActionGuardService(
      repository: _Rules([rule(ActionDecision.prompt)]),
      confirmationPort: port,
    );

    final verdict = await check(guard, heard: heard, withOrigin: origin);

    expect(verdict.allowed, isTrue);
    expect(verdict.prompted, isTrue);
    expect(port.heardAtAsk, [true]);
    expect(heard, [true, false]);
    expect(port.asked.single.origin, origin);
    // The run that asked rides on the card (the hook and the gateway check
    // here), so the server matches the approval to that run only.
    expect(port.asked.single.runId, 'run-1');
  });

  test('a card for the model\'s own call has no origin', () async {
    final port = _Port();
    final guard = ActionGuardService(
      repository: _Rules([rule(ActionDecision.prompt)]),
      confirmationPort: port,
    );

    await check(guard);

    expect(port.asked.single.origin, isNull);
  });

  group('nobody asked, nothing heard', () {
    for (final (name, rules, operator, hasPort) in [
      ('allow', [rule(ActionDecision.allow)], false, true),
      ('deny', [rule(ActionDecision.deny)], false, true),
      (
        'advisory prompt',
        [rule(ActionDecision.prompt, enforcement: EnforcementLevel.advisory)],
        false,
        true,
      ),
      ('operator initiated', [rule(ActionDecision.prompt)], true, true),
      ('no approver', [rule(ActionDecision.prompt)], false, false),
    ]) {
      test(name, () async {
        final heard = <bool>[];
        final port = _Port();
        final guard = ActionGuardService(
          repository: _Rules(rules),
          confirmationPort: hasPort ? port : null,
        );

        await check(
          guard,
          heard: heard,
          withOrigin: origin,
          operatorInitiated: operator,
        );

        expect(heard, isEmpty);
        expect(port.asked, isEmpty);
      });
    }
  });

  test('an approver that throws still ends the wait, and the check throws '
      'as before', () async {
    final heard = <bool>[];
    final audits = <GuardAudit>[];
    final guard = ActionGuardService(
      repository: _Rules([rule(ActionDecision.prompt)]),
      confirmationPort: _Throws(),
      onAudit: audits.add,
    );

    await expectLater(check(guard, heard: heard), throwsStateError);

    expect(heard, [true, false]);
    expect(audits, isEmpty);
  });

  test('a withdrawn card ends the wait and denies', () async {
    final heard = <bool>[];
    final withdraw = Completer<void>();
    final guard = ActionGuardService(
      repository: _Rules([rule(ActionDecision.prompt)]),
      confirmationPort: _Withdrawable(),
    );

    final pending = check(guard, heard: heard, withdrawn: withdraw.future);
    await Future<void>.delayed(Duration.zero);
    expect(heard, [true]);
    withdraw.complete();
    final verdict = await pending;

    expect(verdict.allowed, isFalse);
    expect(heard, [true, false]);
  });

  test('a card nobody answered denies, says nobody answered, and is '
      'audited apart from a person\'s decline', () async {
    final audits = <GuardAudit>[];
    final guard = ActionGuardService(
      repository: _Rules([rule(ActionDecision.prompt)]),
      confirmationPort: _Unanswered(),
      onAudit: audits.add,
    );

    final verdict = await check(guard);

    expect(verdict.allowed, isFalse);
    expect(verdict.unanswered, isTrue);
    expect(verdict.prompted, isTrue);
    expect(verdict.reason, startsWith('Nobody answered at confirmation'));
    expect(audits.single.decision, ActionDecision.deny);
    expect(audits.single.prompted, isTrue);
    expect(audits.single.unanswered, isTrue);

    final declines = <GuardAudit>[];
    final declined = await check(
      ActionGuardService(
        repository: _Rules([rule(ActionDecision.prompt)]),
        confirmationPort: _Port(answer: false),
        onAudit: declines.add,
      ),
    );
    expect(declined.unanswered, isFalse);
    expect(declined.reason, startsWith('Denied at confirmation'));
    expect(declines.single.unanswered, isFalse);
  });

  test('a listener that throws changes nothing about the answer', () async {
    final port = _Port();
    final guard = ActionGuardService(
      repository: _Rules([rule(ActionDecision.prompt)]),
      confirmationPort: port,
    );

    final verdict = await guard.check(
      workspaceId: 'ws',
      classes: const {ActionClass.gitPush},
      request: request,
      onPersonWait: (_) => throw StateError('a broken clock'),
    );

    expect(verdict.allowed, isTrue);
    expect(verdict.prompted, isTrue);
    expect(port.asked, hasLength(1));
  });

  group('the decision, the card and the audit are the same with and without '
      'the new arguments', () {
    for (final (name, rules, answer) in [
      ('allow', [rule(ActionDecision.allow)], true),
      ('deny', [rule(ActionDecision.deny)], true),
      ('prompt approved', [rule(ActionDecision.prompt)], true),
      ('prompt declined', [rule(ActionDecision.prompt)], false),
    ]) {
      test(name, () async {
        Future<(GuardVerdict, List<GuardAudit>, List<ConfirmationRequest>)> run(
          bool withArgs,
        ) async {
          final audits = <GuardAudit>[];
          final port = _Port(answer: answer);
          final guard = ActionGuardService(
            repository: _Rules(rules),
            confirmationPort: port,
            onAudit: audits.add,
          );
          final verdict = await check(
            guard,
            heard: withArgs ? <bool>[] : null,
            withOrigin: withArgs ? origin : null,
          );
          return (verdict, audits, port.asked);
        }

        final (plain, plainAudits, plainCards) = await run(false);
        final (marked, markedAudits, markedCards) = await run(true);

        expect(marked.allowed, plain.allowed);
        expect(marked.reason, plain.reason);
        expect(marked.source, plain.source);
        expect(marked.prompted, plain.prompted);
        expect(marked.resolution?.decision, plain.resolution?.decision);
        expect(markedAudits, hasLength(plainAudits.length));
        for (var i = 0; i < plainAudits.length; i++) {
          final a = plainAudits[i];
          final b = markedAudits[i];
          expect(
            [
              b.workspaceId,
              b.decision,
              b.reason,
              b.source,
              b.agentId,
              b.spaceId,
              b.actionSummary,
              b.actionClasses,
              b.ruleId,
              b.prompted,
              b.onBehalfOfUserId,
              b.runId,
              b.command,
            ],
            [
              a.workspaceId,
              a.decision,
              a.reason,
              a.source,
              a.agentId,
              a.spaceId,
              a.actionSummary,
              a.actionClasses,
              a.ruleId,
              a.prompted,
              a.onBehalfOfUserId,
              a.runId,
              a.command,
            ],
          );
        }
        expect(markedCards, hasLength(plainCards.length));
        for (var i = 0; i < plainCards.length; i++) {
          final a = plainCards[i];
          final b = markedCards[i];
          expect(b.origin, origin);
          expect(a.origin, isNull);
          expect(
            [
              b.title,
              b.detail,
              b.command,
              b.severity,
              b.kind,
              b.rememberChoice,
              b.fingerprint,
              b.actionClasses,
              b.constraintJson,
              b.spaceId,
              b.conversationId,
              b.workspaceId,
              b.agentId,
            ],
            [
              a.title,
              a.detail,
              a.command,
              a.severity,
              a.kind,
              a.rememberChoice,
              a.fingerprint,
              a.actionClasses,
              a.constraintJson,
              a.spaceId,
              a.conversationId,
              a.workspaceId,
              a.agentId,
            ],
          );
        }
      });
    }
  });

  test('a gate that asks on its own puts the origin on its card too', () {
    final card = ActionGuardService.approvalRequest(
      resolution: null,
      classes: const {ActionClass.gitPush},
      askedByPolicy: false,
      request: request,
      origin: origin,
    );
    final plain = ActionGuardService.approvalRequest(
      resolution: null,
      classes: const {ActionClass.gitPush},
      askedByPolicy: false,
      request: request,
    );

    expect(card.origin, origin);
    expect(plain.origin, isNull);
    expect(card.fingerprint, plain.fingerprint);
  });

  test('confirmCommand carries the origin to the card it raises', () async {
    final port = _Port();

    await ActionGuardService.confirmCommand(
      guard: null,
      port: port,
      workspaceId: 'ws',
      classes: const {ActionClass.processSpawn},
      command: 'make deploy',
      origin: origin,
      runId: 'run-7',
    );

    expect(port.asked.single.origin, origin);
    expect(port.asked.single.runId, 'run-7');
  });

  group('a script\'s action longer than the audit stores whole', () {
    final long =
        'bash: ${'a' * ActionGuardService.maxScriptActionSummaryBytes}';

    Future<(GuardVerdict, _Port, List<GuardAudit>)> run(
      String summary, {
      ScriptCallOrigin? withOrigin,
    }) async {
      final port = _Port();
      final audits = <GuardAudit>[];
      final guard = ActionGuardService(
        repository: _Rules([rule(ActionDecision.prompt)]),
        confirmationPort: port,
        onAudit: audits.add,
      );
      final verdict = await guard.check(
        workspaceId: 'ws',
        classes: const {ActionClass.gitPush},
        actionSummary: summary,
        origin: withOrigin,
      );
      return (verdict, port, audits);
    }

    test('is refused without a card, with the size and what to do, and '
        'audited', () async {
      final (verdict, port, audits) = await run(long, withOrigin: origin);

      expect(verdict.allowed, isFalse);
      expect(
        verdict.reason,
        'The command is 16,390 bytes; a command a script runs takes at most '
        '16,384. Write long content to a file and run that.',
      );
      expect(port.asked, isEmpty);
      expect(audits.single.decision, ActionDecision.deny);
      expect(audits.single.source, kScriptActionSizeSource);
      expect(audits.single.reason, verdict.reason);
    });

    test('one byte shorter is decided by the policy', () async {
      final (verdict, port, _) = await run(
        long.substring(0, ActionGuardService.maxScriptActionSummaryBytes),
        withOrigin: origin,
      );

      expect(verdict.allowed, isTrue);
      expect(port.asked, hasLength(1));
    });

    test('a direct call is not refused for its length', () async {
      final (verdict, port, _) = await run(long);

      expect(verdict.allowed, isTrue);
      expect(port.asked, hasLength(1));
    });
  });
}
