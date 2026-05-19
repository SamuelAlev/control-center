import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Argument-level authorization: "may push" and "may push to `feature/*`" are
/// different claims, and only the second is a control.
void main() {
  const resolver = PolicyResolver();
  final now = DateTime.utc(2026, 6, 1, 12);

  ActionPolicyRule rule({
    required ActionClass cls,
    required ActionDecision decision,
    ActionConstraint? constraint,
    DateTime? expiresAt,
    ActionScopeType scope = ActionScopeType.workspace,
    String scopeId = '',
    String id = 'r1',
  }) => ActionPolicyRule(
    id: id,
    workspaceId: 'ws',
    scopeType: scope,
    scopeId: scopeId,
    actionClass: cls,
    decision: decision,
    constraint: constraint,
    expiresAt: expiresAt,
    createdAt: now,
    updatedAt: now,
  );

  group('ActionConstraint matching', () {
    test('ref negation beats a broad allow', () {
      const c = ActionConstraint(refs: ['**', '!main']);
      expect(c.matches(const ActionRequest(refs: ['feature/x'])), isTrue);
      expect(c.matches(const ActionRequest(refs: ['main'])), isFalse);
    });

    test('every value must be covered, not just one', () {
      const c = ActionConstraint(refs: ['feature/*']);
      expect(
        c.matches(const ActionRequest(refs: ['feature/a', 'feature/b'])),
        isTrue,
      );
      expect(
        c.matches(const ActionRequest(refs: ['feature/a', 'main'])),
        isFalse,
        reason: 'a rule about feature/* must not cover a push that also '
            'writes main',
      );
    });

    test('a constraint that names a facet does not match an empty request',
        () {
      // An unimplemented extractor must degrade to the UNCONSTRAINED rule,
      // never silently satisfy a narrow one.
      const c = ActionConstraint(refs: ['feature/*']);
      expect(c.matches(ActionRequest.empty), isFalse);
    });

    test('path globs are segment-aware; ** crosses directories', () {
      const single = ActionConstraint(paths: ['repos/*']);
      expect(single.matches(const ActionRequest(paths: ['repos/app'])), isTrue);
      expect(
        single.matches(const ActionRequest(paths: ['repos/app/lib/x.dart'])),
        isFalse,
      );
      const deep = ActionConstraint(paths: ['repos/**']);
      expect(
        deep.matches(const ActionRequest(paths: ['repos/app/lib/x.dart'])),
        isTrue,
      );
    });

    test('host patterns support subdomain wildcards and negation', () {
      const c = ActionConstraint(hosts: ['*.internal', 'pub.dev']);
      expect(c.matches(const ActionRequest(hosts: ['api.internal'])), isTrue);
      expect(c.matches(const ActionRequest(hosts: ['internal'])), isTrue);
      expect(c.matches(const ActionRequest(hosts: ['pub.dev'])), isTrue);
      expect(c.matches(const ActionRequest(hosts: ['evil.com'])), isFalse);
      const denied = ActionConstraint(hosts: ['!evil.com']);
      expect(denied.matches(const ActionRequest(hosts: ['evil.com'])), isFalse);
      expect(denied.matches(const ActionRequest(hosts: ['ok.com'])), isTrue);
    });

    test('command prefixes match on a word boundary', () {
      const c = ActionConstraint(commands: ['git push']);
      expect(
        c.matches(const ActionRequest(command: 'git push origin main')),
        isTrue,
      );
      expect(c.matches(const ActionRequest(command: 'git push')), isTrue);
      expect(
        c.matches(const ActionRequest(command: 'git pushx --force')),
        isFalse,
      );
    });

    test('ceilings refuse a request above them, and one with no magnitude',
        () {
      const c = ActionConstraint(maxCount: 50);
      expect(c.matches(const ActionRequest(magnitude: 10)), isTrue);
      expect(c.matches(const ActionRequest(magnitude: 500)), isFalse);
      expect(c.matches(ActionRequest.empty), isFalse);
    });

    test('json round-trips and an empty object reads as no constraint', () {
      const c = ActionConstraint(refs: ['**', '!main'], maxCount: 5);
      final decoded = ActionConstraint.decode(c.encode());
      expect(decoded, isNotNull);
      expect(decoded!.refs, ['**', '!main']);
      expect(decoded.maxCount, 5);
      expect(ActionConstraint.decode('{}'), isNull);
      expect(ActionConstraint.decode('not json'), isNull);
      expect(ActionConstraint.decode(null), isNull);
    });
  });

  group('resolver honours constraints', () {
    test('a constrained deny beats an unconstrained allow at the same scope',
        () {
      final rules = [
        rule(cls: ActionClass.gitPush, decision: ActionDecision.allow),
        rule(
          id: 'r2',
          cls: ActionClass.gitPush,
          decision: ActionDecision.deny,
          constraint: const ActionConstraint(refs: ['main', 'release/*']),
        ),
      ];
      final toMain = resolver.resolveClass(
        ActionClass.gitPush,
        rules: rules,
        request: const ActionRequest(refs: ['main']),
      );
      expect(toMain.decision, ActionDecision.deny);
      expect(toMain.rule?.id, 'r2');

      final toFeature = resolver.resolveClass(
        ActionClass.gitPush,
        rules: rules,
        request: const ActionRequest(refs: ['feature/x']),
      );
      expect(toFeature.decision, ActionDecision.allow);
      expect(toFeature.rule?.id, 'r1');
    });

    test('an unconstrained rule still matches a request with no arguments',
        () {
      final rules = [
        rule(cls: ActionClass.gitPush, decision: ActionDecision.allow),
      ];
      expect(
        resolver
            .resolveClass(ActionClass.gitPush, rules: rules)
            .decision,
        ActionDecision.allow,
        reason: 'every pre-constraint row must keep its exact meaning',
      );
    });
  });

  group('expiry', () {
    test('an expired rule is ignored and the default applies again', () {
      final rules = [
        rule(
          cls: ActionClass.gitPush,
          decision: ActionDecision.allow,
          expiresAt: now.subtract(const Duration(minutes: 1)),
        ),
      ];
      final res = resolver.resolveClass(
        ActionClass.gitPush,
        rules: rules,
        now: now,
      );
      expect(res.decision, ActionDecision.prompt);
      expect(res.source, 'default');
    });

    test('a live rule still applies', () {
      final rules = [
        rule(
          cls: ActionClass.gitPush,
          decision: ActionDecision.allow,
          expiresAt: now.add(const Duration(hours: 8)),
        ),
      ];
      expect(
        resolver
            .resolveClass(ActionClass.gitPush, rules: rules, now: now)
            .decision,
        ActionDecision.allow,
      );
    });

    test('without a clock nothing expires (pure, caller-supplied time)', () {
      final rules = [
        rule(
          cls: ActionClass.gitPush,
          decision: ActionDecision.allow,
          expiresAt: now.subtract(const Duration(days: 1)),
        ),
      ];
      expect(
        resolver.resolveClass(ActionClass.gitPush, rules: rules).decision,
        ActionDecision.allow,
      );
    });
  });

  group('the managed tier clamps and never loosens', () {
    test('managed deny overrides a workspace allow', () {
      final res = resolver.resolveAction(
        {ActionClass.gitPush},
        rules: [rule(cls: ActionClass.gitPush, decision: ActionDecision.allow)],
        managedRules: [
          rule(
            id: 'm1',
            cls: ActionClass.gitPush,
            decision: ActionDecision.deny,
          ),
        ],
      );
      expect(res.decision, ActionDecision.deny);
      expect(res.driving.source, 'managed');
    });

    test('managed allow does NOT override a workspace deny', () {
      // The whole point of a clamp: an install-wide rule can tighten what a
      // workspace decided, never widen it.
      final res = resolver.resolveAction(
        {ActionClass.gitPush},
        rules: [rule(cls: ActionClass.gitPush, decision: ActionDecision.deny)],
        managedRules: [
          rule(
            id: 'm1',
            cls: ActionClass.gitPush,
            decision: ActionDecision.allow,
          ),
        ],
      );
      expect(res.decision, ActionDecision.deny);
      expect(res.driving.source, ActionScopeType.workspace.wire);
    });

    test('managed prompt tightens an allow but not a deny', () {
      final overAllow = resolver.resolveAction(
        {ActionClass.gitCommit},
        rules: [
          rule(cls: ActionClass.gitCommit, decision: ActionDecision.allow),
        ],
        managedRules: [
          rule(
            id: 'm1',
            cls: ActionClass.gitCommit,
            decision: ActionDecision.prompt,
          ),
        ],
      );
      expect(overAllow.decision, ActionDecision.prompt);

      final overDeny = resolver.resolveAction(
        {ActionClass.gitCommit},
        rules: [
          rule(cls: ActionClass.gitCommit, decision: ActionDecision.deny),
        ],
        managedRules: [
          rule(
            id: 'm1',
            cls: ActionClass.gitCommit,
            decision: ActionDecision.prompt,
          ),
        ],
      );
      expect(overDeny.decision, ActionDecision.deny);
    });

    test('a managed rule can be argument-scoped too', () {
      final managed = [
        rule(
          id: 'm1',
          cls: ActionClass.networkEgress,
          decision: ActionDecision.deny,
          constraint: const ActionConstraint(hosts: ['!*.internal']),
        ),
      ];
      // Reaching an internal host is negated out of the deny → falls through.
      expect(
        resolver
            .resolveAction(
              {ActionClass.networkEgress},
              rules: const [],
              managedRules: managed,
              request: const ActionRequest(hosts: ['api.internal']),
            )
            .decision,
        ActionDecision.allow,
      );
      expect(
        resolver
            .resolveAction(
              {ActionClass.networkEgress},
              rules: const [],
              managedRules: managed,
              request: const ActionRequest(hosts: ['evil.com']),
            )
            .decision,
        ActionDecision.deny,
      );
    });
  });

  group('enforcement levels', () {
    test('a rule defaults to hard enforcement', () {
      expect(
        rule(cls: ActionClass.gitPush, decision: ActionDecision.deny)
            .enforcement,
        EnforcementLevel.hard,
      );
    });

    test('an unknown stored level reads as hard, never as weaker', () {
      expect(EnforcementLevel.fromWire('nonsense'), EnforcementLevel.hard);
      expect(EnforcementLevel.fromWire(null), EnforcementLevel.hard);
      expect(EnforcementLevel.fromWire('advisory'), EnforcementLevel.advisory);
      expect(EnforcementLevel.fromWire('soft'), EnforcementLevel.soft);
    });
  });
}
