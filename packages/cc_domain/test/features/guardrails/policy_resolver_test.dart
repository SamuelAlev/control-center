import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Builds an [ActionPolicyRule] inline with fixed timestamps. Exactly one of
/// [actionClass] / [commandPrefix] must be set (entity invariant).
ActionPolicyRule _rule({
  required ActionScopeType scopeType,
  required ActionDecision decision,
  String scopeId = '',
  ActionClass? actionClass,
  String? commandPrefix,
}) => ActionPolicyRule(
  id:
      '${scopeType.wire}:$scopeId:'
      '${actionClass?.wire ?? commandPrefix}:${decision.wire}',
  workspaceId: 'w1',
  scopeType: scopeType,
  scopeId: scopeId,
  actionClass: actionClass,
  commandPrefix: commandPrefix,
  decision: decision,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  const resolver = PolicyResolver();

  group(
    'scope precedence (space > agent > workspace > preset > default)',
    () {
      test('space rule wins over agent, workspace and mode preset', () {
        final rules = [
          _rule(
            scopeType: ActionScopeType.space,
            scopeId: 'c1',
            actionClass: ActionClass.gitPush,
            decision: ActionDecision.allow,
          ),
          _rule(
            scopeType: ActionScopeType.agent,
            scopeId: 'a1',
            actionClass: ActionClass.gitPush,
            decision: ActionDecision.prompt,
          ),
          _rule(
            scopeType: ActionScopeType.workspace,
            actionClass: ActionClass.gitPush,
            decision: ActionDecision.deny,
          ),
        ];

        // Even under a read-only mode (whose preset would deny gitPush), the
        // space rule is found first in the scope chain and decides.
        final r = resolver.resolveClass(
          ActionClass.gitPush,
          rules: rules,
          spaceId: 'c1',
          agentId: 'a1',
          mode: Mode.plan,
        );

        expect(r.decision, ActionDecision.allow);
        expect(r.source, 'space');
        expect(r.rule, isNotNull);
      });

      test('agent rule wins when no space rule matches', () {
        final rules = [
          _rule(
            scopeType: ActionScopeType.agent,
            scopeId: 'a1',
            actionClass: ActionClass.gitPush,
            decision: ActionDecision.prompt,
          ),
          _rule(
            scopeType: ActionScopeType.workspace,
            actionClass: ActionClass.gitPush,
            decision: ActionDecision.deny,
          ),
        ];

        final r = resolver.resolveClass(
          ActionClass.gitPush,
          rules: rules,
          spaceId: 'c1',
          agentId: 'a1',
        );

        expect(r.decision, ActionDecision.prompt);
        expect(r.source, 'agent');
      });

      test('workspace rule wins over the mode preset', () {
        final rules = [
          _rule(
            scopeType: ActionScopeType.workspace,
            actionClass: ActionClass.gitPush,
            decision: ActionDecision.allow,
          ),
        ];

        // plan mode preset would deny gitPush; an explicit store rule beats it.
        final r = resolver.resolveClass(
          ActionClass.gitPush,
          rules: rules,
          mode: Mode.plan,
        );

        expect(r.decision, ActionDecision.allow);
        expect(r.source, 'workspace');
      });
    },
  );

  group('determinism', () {
    test('same inputs produce the same decision across repeated calls', () {
      final rules = [
        _rule(
          scopeType: ActionScopeType.agent,
          scopeId: 'a1',
          actionClass: ActionClass.gitPush,
          decision: ActionDecision.prompt,
        ),
        _rule(
          scopeType: ActionScopeType.workspace,
          actionClass: ActionClass.gitPush,
          decision: ActionDecision.deny,
        ),
      ];

      final first = resolver.resolveClass(
        ActionClass.gitPush,
        rules: rules,
        agentId: 'a1',
      );
      for (var i = 0; i < 20; i++) {
        final again = resolver.resolveClass(
          ActionClass.gitPush,
          rules: rules,
          agentId: 'a1',
        );
        expect(again.decision, first.decision);
        expect(again.source, first.source);
      }
    });
  });

  group('command longest-prefix carve-out', () {
    final rules = [
      _rule(
        scopeType: ActionScopeType.workspace,
        commandPrefix: 'git push',
        decision: ActionDecision.prompt,
      ),
      _rule(
        scopeType: ActionScopeType.workspace,
        commandPrefix: 'git push origin',
        decision: ActionDecision.allow,
      ),
    ];

    test('longer prefix carve-out wins: git push origin main -> allow', () {
      final r = resolver.resolveCommand('git push origin main', rules: rules);
      expect(r, isNotNull);
      expect(r!.decision, ActionDecision.allow);
      expect(r.rule?.commandPrefix, 'git push origin');
    });

    test('shorter prefix applies when the carve-out does not: git push -> '
        'prompt', () {
      final r = resolver.resolveCommand('git push', rules: rules);
      expect(r, isNotNull);
      expect(r!.decision, ActionDecision.prompt);
      expect(r.rule?.commandPrefix, 'git push');
    });

    test('no matching prefix returns null (caller falls back)', () {
      final r = resolver.resolveCommand('ls -la', rules: rules);
      expect(r, isNull);
    });
  });

  group('equally-specific most-restrictive (class-level combine)', () {
    // A same-length command-prefix collision is unreachable through the store:
    // the unique key forbids identical prefixes and two DIFFERENT prefixes of
    // equal length cannot both be a leading segment of one command. The
    // equally-specific "most restrictive wins" rule (allow-beats-deny is GONE)
    // therefore manifests in the class-level combine, asserted here directly
    // and via resolveAction below.
    test(
      'ActionDecision.mostRestrictive picks deny over allow (order-free)',
      () {
        expect(
          ActionDecision.mostRestrictive(
            ActionDecision.allow,
            ActionDecision.deny,
          ),
          ActionDecision.deny,
        );
        expect(
          ActionDecision.mostRestrictive(
            ActionDecision.deny,
            ActionDecision.allow,
          ),
          ActionDecision.deny,
        );
        expect(
          ActionDecision.deny.isMoreRestrictiveThan(ActionDecision.allow),
          isTrue,
        );
        expect(
          ActionDecision.allow.isMoreRestrictiveThan(ActionDecision.deny),
          isFalse,
        );
      },
    );

    test('a same-scope allow class combined with a deny class -> deny', () {
      final rules = [
        _rule(
          scopeType: ActionScopeType.workspace,
          actionClass: ActionClass.networkEgress,
          decision: ActionDecision.allow,
        ),
        _rule(
          scopeType: ActionScopeType.workspace,
          actionClass: ActionClass.fileDelete,
          decision: ActionDecision.deny,
        ),
      ];

      final r = resolver.resolveAction({
        ActionClass.networkEgress,
        ActionClass.fileDelete,
      }, rules: rules);

      expect(r.decision, ActionDecision.deny);
      expect(r.driving.actionClass, ActionClass.fileDelete);
    });
  });

  group('allow-beats-deny is gone; scope specificity decides', () {
    test('agent allow + workspace deny on the same class -> allow (agent > '
        'workspace, NOT allow > deny)', () {
      final rules = [
        _rule(
          scopeType: ActionScopeType.agent,
          scopeId: 'a1',
          actionClass: ActionClass.gitPush,
          decision: ActionDecision.allow,
        ),
        _rule(
          scopeType: ActionScopeType.workspace,
          actionClass: ActionClass.gitPush,
          decision: ActionDecision.deny,
        ),
      ];

      final r = resolver.resolveClass(
        ActionClass.gitPush,
        rules: rules,
        agentId: 'a1',
      );

      expect(r.decision, ActionDecision.allow);
      expect(r.source, 'agent');
    });

    test('within one scope there is only one rule per class (unique key), so '
        'the found rule decides on its own', () {
      final rules = [
        _rule(
          scopeType: ActionScopeType.workspace,
          actionClass: ActionClass.gitPush,
          decision: ActionDecision.deny,
        ),
      ];

      final r = resolver.resolveClass(ActionClass.gitPush, rules: rules);

      expect(r.decision, ActionDecision.deny);
      expect(r.source, 'workspace');
    });

    // Defense-in-depth (security review finding): SQLite treats the NULL-bearing
    // unique key as distinct, so a logical-duplicate rule for the same (scope,
    // class) could slip in. The resolver must pick MOST-RESTRICTIVE regardless
    // of list order — never first-match (which would be order-dependent and
    // could let an allow shadow a deny).
    test(
      'duplicate same-scope/class rules resolve most-restrictive, order-free',
      () {
        // Distinct ids (the helper folds the decision into the id), same
        // (scope, class) — a logical duplicate the DB cannot reject.
        final allowFirst = [
          _rule(
            scopeType: ActionScopeType.workspace,
            actionClass: ActionClass.gitPush,
            decision: ActionDecision.allow,
          ),
          _rule(
            scopeType: ActionScopeType.workspace,
            actionClass: ActionClass.gitPush,
            decision: ActionDecision.deny,
          ),
        ];
        final denyFirst = allowFirst.reversed.toList();

        expect(
          resolver
              .resolveClass(ActionClass.gitPush, rules: allowFirst)
              .decision,
          ActionDecision.deny,
        );
        expect(
          resolver.resolveClass(ActionClass.gitPush, rules: denyFirst).decision,
          ActionDecision.deny,
        );
      },
    );
  });

  group('multi-class most-restrictive combine', () {
    test('fileDelete (prompt default) + networkEgress (allow default), no '
        'rules -> prompt, prompting lists fileDelete', () {
      final r = resolver.resolveAction({
        ActionClass.fileDelete,
        ActionClass.networkEgress,
      }, rules: const []);

      expect(r.decision, ActionDecision.prompt);
      expect(r.driving.actionClass, ActionClass.fileDelete);
      expect(r.prompting.map((p) => p.actionClass), [ActionClass.fileDelete]);
    });
  });

  group('scope chain without a space', () {
    test('resolveClass(gitPush, spaceId: null, agentId: a1) with an agent '
        'allow rule -> allow (agent scope)', () {
      final rules = [
        _rule(
          scopeType: ActionScopeType.agent,
          scopeId: 'a1',
          actionClass: ActionClass.gitPush,
          decision: ActionDecision.allow,
        ),
      ];

      final r = resolver.resolveClass(
        ActionClass.gitPush,
        rules: rules,
        agentId: 'a1',
      );

      expect(r.decision, ActionDecision.allow);
      expect(r.source, 'agent');
    });
  });

  group('read-only mode preset', () {
    test('resolveClass(gitPush, mode: plan) with no rules -> deny, source '
        'preset', () {
      final r = resolver.resolveClass(
        ActionClass.gitPush,
        rules: const [],
        mode: Mode.plan,
      );

      expect(r.decision, ActionDecision.deny);
      expect(r.source, 'preset');
    });
  });

  group('built-in defaults (chat mode, no rules)', () {
    test('gitPush -> prompt (default)', () {
      final r = resolver.resolveClass(ActionClass.gitPush, rules: const []);
      expect(r.decision, ActionDecision.prompt);
      expect(r.source, 'default');
    });

    test('gitCommit -> allow (default)', () {
      final r = resolver.resolveClass(ActionClass.gitCommit, rules: const []);
      expect(r.decision, ActionDecision.allow);
      expect(r.source, 'default');
    });
  });
}
