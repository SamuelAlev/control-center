import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Scope precedence must survive the constraint work.
///
/// Constraint specificity is a tie-break WITHIN one scope. If it ever leaked
/// across scopes, a narrow workspace rule would start beating a space rule and
/// the documented `space > agent > workspace` order would quietly be a lie.
void main() {
  const resolver = PolicyResolver();
  final now = DateTime.utc(2026, 6, 1);

  ActionPolicyRule rule({
    required ActionScopeType scope,
    required ActionDecision decision,
    String scopeId = '',
    ActionConstraint? constraint,
    String id = 'r',
    ActionClass cls = ActionClass.gitPush,
  }) => ActionPolicyRule(
    id: id,
    workspaceId: 'ws',
    scopeType: scope,
    scopeId: scopeId,
    actionClass: cls,
    decision: decision,
    constraint: constraint,
    createdAt: now,
    updatedAt: now,
  );

  test('a space rule still beats a MORE specific workspace rule', () {
    final res = resolver.resolveClass(
      ActionClass.gitPush,
      rules: [
        rule(
          id: 'space',
          scope: ActionScopeType.space,
          scopeId: 's1',
          decision: ActionDecision.allow,
        ),
        rule(
          id: 'workspace-narrow',
          scope: ActionScopeType.workspace,
          decision: ActionDecision.deny,
          constraint: const ActionConstraint(refs: ['main']),
        ),
      ],
      spaceId: 's1',
      request: const ActionRequest(refs: ['main']),
    );
    expect(res.rule?.id, 'space');
    expect(res.decision, ActionDecision.allow);
  });

  test('an agent rule still beats a workspace rule', () {
    final res = resolver.resolveClass(
      ActionClass.gitPush,
      rules: [
        rule(
          id: 'agent',
          scope: ActionScopeType.agent,
          scopeId: 'a1',
          decision: ActionDecision.allow,
        ),
        rule(
          id: 'workspace',
          scope: ActionScopeType.workspace,
          decision: ActionDecision.deny,
        ),
      ],
      agentId: 'a1',
      request: const ActionRequest(refs: ['feature/x']),
    );
    expect(res.rule?.id, 'agent');
  });

  test('within one scope, the constrained rule wins when it applies', () {
    final rules = [
      rule(
        id: 'broad',
        scope: ActionScopeType.workspace,
        decision: ActionDecision.allow,
      ),
      rule(
        id: 'narrow',
        scope: ActionScopeType.workspace,
        decision: ActionDecision.deny,
        constraint: const ActionConstraint(refs: ['main']),
      ),
    ];
    expect(
      resolver
          .resolveClass(
            ActionClass.gitPush,
            rules: rules,
            request: const ActionRequest(refs: ['main']),
          )
          .rule
          ?.id,
      'narrow',
    );
    expect(
      resolver
          .resolveClass(
            ActionClass.gitPush,
            rules: rules,
            request: const ActionRequest(refs: ['feature/x']),
          )
          .rule
          ?.id,
      'broad',
    );
  });

  test('a space rule that does not apply falls through to the next scope', () {
    final res = resolver.resolveClass(
      ActionClass.gitPush,
      rules: [
        rule(
          id: 'space',
          scope: ActionScopeType.space,
          scopeId: 's1',
          decision: ActionDecision.allow,
          constraint: const ActionConstraint(refs: ['feature/**']),
        ),
        rule(
          id: 'workspace',
          scope: ActionScopeType.workspace,
          decision: ActionDecision.deny,
        ),
      ],
      spaceId: 's1',
      request: const ActionRequest(refs: ['main']),
    );
    expect(res.rule?.id, 'workspace');
    expect(res.decision, ActionDecision.deny);
  });
}
