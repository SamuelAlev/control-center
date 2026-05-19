import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Adversarial: a constrained DENY must not be evadable.
///
/// These pin the two ways a naive "the rule covers the whole request" model
/// lets an agent walk past a deny — by batching one innocent value alongside
/// the forbidden one, and by simply not naming the value at all.
void main() {
  const resolver = PolicyResolver();
  final now = DateTime.utc(2026, 6, 1);

  ActionPolicyRule rule({
    required ActionClass cls,
    required ActionDecision decision,
    ActionConstraint? constraint,
    String id = 'r',
  }) => ActionPolicyRule(
    id: id,
    workspaceId: 'ws',
    scopeType: ActionScopeType.workspace,
    scopeId: '',
    actionClass: cls,
    decision: decision,
    constraint: constraint,
    createdAt: now,
    updatedAt: now,
  );

  group('a constrained deny cannot be evaded by batching', () {
    test('deleting a protected file alongside an innocent one still denies',
        () {
      final rules = [
        rule(id: 'allow', cls: ActionClass.fileDelete,
            decision: ActionDecision.allow),
        rule(id: 'deny', cls: ActionClass.fileDelete,
            decision: ActionDecision.deny,
            constraint: const ActionConstraint(paths: ['**/.env'])),
      ];
      final res = resolver.resolveClass(
        ActionClass.fileDelete,
        rules: rules,
        request: const ActionRequest(paths: ['lib/a.dart', 'app/.env']),
      );
      expect(
        res.decision,
        ActionDecision.deny,
        reason: 'batching an innocent path must not launder a denied one',
      );
    });

    test('pushing several refs, one of them protected, still denies', () {
      final rules = [
        rule(id: 'allow', cls: ActionClass.gitPush,
            decision: ActionDecision.allow),
        rule(id: 'deny', cls: ActionClass.gitPush,
            decision: ActionDecision.deny,
            constraint: const ActionConstraint(refs: ['main'])),
      ];
      final res = resolver.resolveClass(
        ActionClass.gitPush,
        rules: rules,
        request: const ActionRequest(refs: ['feature/x', 'main']),
      );
      expect(res.decision, ActionDecision.deny);
    });
  });

  group('an unevaluable restrictive rule escalates instead of guessing', () {
    test('a push whose ref was never extracted does NOT slip past the deny',
        () {
      // The real shape: `worktree.commitAndPush` names its branch in
      // `push_branch`, and a tool that pushes the current branch names it
      // nowhere at all. If an unnamed ref means "the deny does not apply",
      // then "never push to main" protects nothing.
      final rules = [
        rule(id: 'allow', cls: ActionClass.gitPush,
            decision: ActionDecision.allow),
        rule(id: 'deny', cls: ActionClass.gitPush,
            decision: ActionDecision.deny,
            constraint: const ActionConstraint(
              refs: ['main', 'master', 'release/*'],
            )),
      ];
      final res = resolver.resolveClass(
        ActionClass.gitPush,
        rules: rules,
        request: ActionRequest.empty,
      );
      // It resolves to PROMPT, not allow: the rule applies but cannot be
      // evaluated, so a human is asked — and with no approver connected the
      // guard's existing fail-closed rule turns that into a denial. Silently
      // allowing would make every protected-branch rule inert; silently
      // denying would refuse every push the extractor cannot describe.
      expect(res.decision, ActionDecision.prompt);
      expect(
        res.decision,
        isNot(ActionDecision.allow),
        reason: 'the protected-branch rule the templates ship must not be '
            'inert',
      );
      expect(res.reason, contains('needs approval'));
    });

    test('and the same is true when the deny is install-wide (managed)', () {
      final res = resolver.resolveAction(
        {ActionClass.gitPush},
        rules: [
          rule(id: 'allow', cls: ActionClass.gitPush,
              decision: ActionDecision.allow),
        ],
        managedRules: [
          rule(id: 'm', cls: ActionClass.gitPush,
              decision: ActionDecision.deny,
              constraint: const ActionConstraint(refs: ['main'])),
        ],
        request: ActionRequest.empty,
      );
      expect(res.decision, ActionDecision.prompt);
    });

    test('a provable miss still falls through to the broader allow', () {
      final rules = [
        rule(id: 'allow', cls: ActionClass.gitPush,
            decision: ActionDecision.allow),
        rule(id: 'deny', cls: ActionClass.gitPush,
            decision: ActionDecision.deny,
            constraint: const ActionConstraint(refs: ['main'])),
      ];
      final res = resolver.resolveClass(
        ActionClass.gitPush,
        rules: rules,
        request: const ActionRequest(refs: ['feature/x']),
      );
      expect(res.decision, ActionDecision.allow,
          reason: 'escalation must not swallow the ordinary case');
    });
  });

  group('a constrained ALLOW stays narrow', () {
    test('an allow scoped to feature/** does not cover a push to main', () {
      final rules = [
        rule(id: 'allow', cls: ActionClass.gitPush,
            decision: ActionDecision.allow,
            constraint: const ActionConstraint(refs: ['feature/**'])),
      ];
      final res = resolver.resolveClass(
        ActionClass.gitPush,
        rules: rules,
        request: const ActionRequest(refs: ['main']),
      );
      expect(res.decision, ActionDecision.prompt,
          reason: 'falls through to the built-in default, not to allow');
    });

    test('an allow does not cover a request it cannot prove is inside it', () {
      final rules = [
        rule(id: 'allow', cls: ActionClass.gitPush,
            decision: ActionDecision.allow,
            constraint: const ActionConstraint(refs: ['feature/**'])),
      ];
      final res = resolver.resolveClass(
        ActionClass.gitPush,
        rules: rules,
        request: ActionRequest.empty,
      );
      expect(res.decision, ActionDecision.prompt);
    });

    test('an allow DOES cover a request entirely inside it', () {
      final rules = [
        rule(id: 'allow', cls: ActionClass.gitPush,
            decision: ActionDecision.allow,
            constraint: const ActionConstraint(refs: ['feature/**'])),
      ];
      final res = resolver.resolveClass(
        ActionClass.gitPush,
        rules: rules,
        request: const ActionRequest(refs: ['feature/a', 'feature/b']),
      );
      expect(res.decision, ActionDecision.allow);
    });
  });
}
