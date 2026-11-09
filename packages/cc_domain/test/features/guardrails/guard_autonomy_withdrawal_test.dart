import 'dart:async';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// The space autonomy dial and approval withdrawal at the guard itself, so
/// every runtime that asks it (Claude Code's hook, the push gateway, ACP,
/// environment commands) applies them the same way the harness gate does.
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

class _Port implements ConfirmationPort {
  ConfirmationRequest? asked;
  final answer = Completer<bool>();

  @override
  Future<bool> requestApproval(ConfirmationRequest request) {
    asked = request;
    return Future.any([
      answer.future,
      if (request.withdrawn case final w?) w.then((_) => false),
    ]);
  }
}

void main() {
  final now = DateTime.utc(2026, 6, 1);
  ActionPolicyRule rule(ActionDecision decision) => ActionPolicyRule(
    id: 'r1',
    workspaceId: 'ws',
    scopeType: ActionScopeType.workspace,
    scopeId: '',
    actionClass: ActionClass.gitPush,
    decision: decision,
    enforcement: EnforcementLevel.hard,
    createdAt: now,
    updatedAt: now,
  );

  test('propose-only refuses an action policy allows', () async {
    final audits = <GuardAudit>[];
    final verdict =
        await ActionGuardService(
          repository: _Rules([rule(ActionDecision.allow)]),
          onAudit: audits.add,
        ).check(
          workspaceId: 'ws',
          classes: {ActionClass.gitPush},
          autonomy: AutonomyLevel.proposeOnly,
        );
    expect(verdict.allowed, isFalse);
    expect(verdict.reason, kProposeOnlyReason);
    expect(audits.single.decision, ActionDecision.deny);
  });

  test('propose-only does not apply to an ungated action', () async {
    final verdict =
        await ActionGuardService(
          repository: _Rules([rule(ActionDecision.allow)]),
        ).check(
          workspaceId: 'ws',
          classes: {ActionClass.gitPush},
          autonomy: AutonomyLevel.proposeOnly,
          autonomyGated: false,
        );
    expect(verdict.allowed, isTrue);
  });

  test('act-freely never answers a policy prompt', () async {
    final port = _Port();
    final pending =
        ActionGuardService(
          repository: _Rules([rule(ActionDecision.prompt)]),
          confirmationPort: port,
        ).check(
          workspaceId: 'ws',
          classes: {ActionClass.gitPush},
          autonomy: AutonomyLevel.actFreely,
        );
    await Future<void>.delayed(Duration.zero);
    expect(port.asked, isNotNull, reason: 'the operator is still asked');
    port.answer.complete(true);
    expect((await pending).allowed, isTrue);
  });

  test('a withdrawn ask reaches the port and resolves as a deny', () async {
    final port = _Port();
    final withdraw = Completer<void>();
    final pending =
        ActionGuardService(
          repository: _Rules([rule(ActionDecision.prompt)]),
          confirmationPort: port,
        ).check(
          workspaceId: 'ws',
          classes: {ActionClass.gitPush},
          withdrawn: withdraw.future,
        );
    await Future<void>.delayed(Duration.zero);
    expect(port.asked?.withdrawn, isNotNull);
    withdraw.complete();
    final verdict = await pending;
    expect(verdict.allowed, isFalse);
    expect(verdict.prompted, isTrue);
  });
}
