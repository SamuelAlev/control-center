import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';

/// Persistence contract for the action-guardrail rules store (PRD 24 §2).
///
/// Rules are workspace-scoped; every read filters by workspace id (the
/// workspace-isolation invariant). The resolver loads the full rule set once
/// per evaluation batch and resolves in memory.
abstract interface class ActionPolicyRepository {
  /// Inserts or replaces a rule by id.
  Future<void> upsertRule(ActionPolicyRule rule);

  /// All rules in [workspaceId].
  Future<List<ActionPolicyRule>> rules(String workspaceId);

  /// Live rules in [workspaceId] (the policy surface).
  Stream<List<ActionPolicyRule>> watchRules(String workspaceId);

  /// Rules for the [scopeType]/[scopeId] scope within [workspaceId].
  Future<List<ActionPolicyRule>> rulesForScope(
    String workspaceId,
    ActionScopeType scopeType,
    String scopeId,
  );

  /// One rule by [id] within [workspaceId], or null.
  Future<ActionPolicyRule?> ruleById(String workspaceId, String id);

  /// Deletes the rule [id] within [workspaceId].
  Future<void> deleteRule(String workspaceId, String id);
}
