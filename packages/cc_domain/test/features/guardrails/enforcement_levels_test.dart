import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// The three enforcement levels, at the gate rather than in the resolver:
/// advisory allows-and-records, soft is overridable WITH a justification, and
/// hard is the floor.
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

void main() {
  final now = DateTime.utc(2026, 6, 1);

  ActionPolicyRule rule(
    ActionDecision decision,
    EnforcementLevel enforcement, {
    ActionClass cls = ActionClass.gitPush,
  }) => ActionPolicyRule(
    id: 'r1',
    workspaceId: 'ws',
    scopeType: ActionScopeType.workspace,
    scopeId: '',
    actionClass: cls,
    decision: decision,
    enforcement: enforcement,
    createdAt: now,
    updatedAt: now,
  );

  ActionGuardService guardFor(
    List<ActionPolicyRule> rules, {
    List<GuardAudit>? audits,
  }) => ActionGuardService(
    repository: _Rules([...rules]),
    onAudit: audits?.add,
  );

  group('advisory allows and records', () {
    test('a prompt rule marked advisory allows without asking', () async {
      final audits = <GuardAudit>[];
      final verdict = await guardFor([
        rule(ActionDecision.prompt, EnforcementLevel.advisory),
      ], audits: audits).check(
        workspaceId: 'ws',
        classes: {ActionClass.gitPush},
        actionSummary: 'git_push',
      );
      expect(verdict.allowed, isTrue);
      // Recorded, which is the whole point: an operator reads the trail to
      // see what the rule WOULD have blocked before promoting it.
      expect(audits, hasLength(1));
      expect(audits.single.decision, ActionDecision.allow);
      expect(audits.single.ruleId, 'r1');
    });

    test('with no approver connected it still allows (it is not a gate)',
        () async {
      final verdict = await guardFor([
        rule(ActionDecision.prompt, EnforcementLevel.advisory),
      ]).check(workspaceId: 'ws', classes: {ActionClass.gitPush});
      expect(verdict.allowed, isTrue);
    });
  });

  group('soft-mandatory is overridable, but only properly', () {
    test('denies by default, and says it is overridable', () async {
      final verdict = await guardFor([
        rule(ActionDecision.deny, EnforcementLevel.soft),
      ]).check(workspaceId: 'ws', classes: {ActionClass.gitPush});
      expect(verdict.allowed, isFalse);
      expect(verdict.reason, contains('overridden'));
    });

    test('permission WITHOUT a reason does not override', () async {
      final verdict = await guardFor([
        rule(ActionDecision.deny, EnforcementLevel.soft),
      ]).check(
        workspaceId: 'ws',
        classes: {ActionClass.gitPush},
        canOverride: true,
      );
      expect(verdict.allowed, isFalse, reason: 'an unaudited override is none');
    });

    test('a reason WITHOUT the permission does not override', () async {
      final verdict = await guardFor([
        rule(ActionDecision.deny, EnforcementLevel.soft),
      ]).check(
        workspaceId: 'ws',
        classes: {ActionClass.gitPush},
        overrideReason: 'incident response',
      );
      expect(verdict.allowed, isFalse);
    });

    test('a blank reason does not override', () async {
      final verdict = await guardFor([
        rule(ActionDecision.deny, EnforcementLevel.soft),
      ]).check(
        workspaceId: 'ws',
        classes: {ActionClass.gitPush},
        canOverride: true,
        overrideReason: '   ',
      );
      expect(verdict.allowed, isFalse);
    });

    test('both together override, and the override is audited', () async {
      final audits = <GuardAudit>[];
      final verdict = await guardFor([
        rule(ActionDecision.deny, EnforcementLevel.soft),
      ], audits: audits).check(
        workspaceId: 'ws',
        classes: {ActionClass.gitPush},
        canOverride: true,
        overrideReason: 'incident response, ticket OPS-4821',
      );
      expect(verdict.allowed, isTrue);
      expect(audits.single.decision, ActionDecision.allow);
    });
  });

  group('THE FLOOR: hard enforcement overrides nothing', () {
    test('a hard deny refuses even with the permission AND a reason',
        () async {
      final verdict = await guardFor([
        rule(ActionDecision.deny, EnforcementLevel.hard),
      ]).check(
        workspaceId: 'ws',
        classes: {ActionClass.gitPush},
        canOverride: true,
        overrideReason: 'I really mean it',
      );
      expect(
        verdict.allowed,
        isFalse,
        reason: 'hard is the documented safety floor; nothing overrides it',
      );
    });

    test('and it is not even described as overridable', () async {
      final verdict = await guardFor([
        rule(ActionDecision.deny, EnforcementLevel.hard),
      ]).check(workspaceId: 'ws', classes: {ActionClass.gitPush});
      expect(verdict.reason, isNot(contains('overridden')));
    });

    test('an operator-initiated call cannot override a deny either', () async {
      final verdict = await guardFor([
        rule(ActionDecision.deny, EnforcementLevel.hard),
      ]).check(
        workspaceId: 'ws',
        classes: {ActionClass.gitPush},
        operatorInitiated: true,
      );
      expect(verdict.allowed, isFalse);
    });
  });

  group('fail-closed prompting is unchanged', () {
    test('a hard prompt with no approver denies', () async {
      final verdict = await guardFor([
        rule(ActionDecision.prompt, EnforcementLevel.hard),
      ]).check(workspaceId: 'ws', classes: {ActionClass.gitPush});
      expect(verdict.allowed, isFalse);
      expect(verdict.reason, contains('fail-closed'));
    });
  });
}
