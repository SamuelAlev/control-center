import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';

/// How the agent-permissions page sorts rules.
///
/// The page's picker owns exactly one rule per scope and action class: the
/// plain one. Everything else (an "Approve for 8 hours" answer, a rule with a
/// condition, one that expires, a command rule) is listed on its own with a
/// revoke action, so a picker change can never turn "pushes to `feature/**`
/// until 18:40" into "every push, forever".
extension GuardrailRuleKind on ActionPolicyRule {
  /// Set by a person for a whole action class, with no condition and no end.
  bool get isPlainClassRule =>
      actionClass != null &&
      commandPrefix == null &&
      provenance == 'user' &&
      constraint == null &&
      expiresAt == null;

  /// Whether this rule sits at the scope ([type], [id]).
  bool isAt(ActionScopeType type, String id) =>
      scopeType == type && scopeId == id;
}
