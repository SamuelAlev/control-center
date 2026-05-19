import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between the action-policy table rows ([ActionPoliciesTableData]) and
/// [ActionPolicyRule] domain entities (PRD 24). Exactly one of `actionClass` /
/// `commandPrefix` is set on a row, preserved across the round-trip.
class ActionPolicyMapper {
  /// Creates an [ActionPolicyMapper].
  const ActionPolicyMapper();

  /// Row to domain entity.
  ActionPolicyRule ruleFromRow(ActionPoliciesTableData row) => ActionPolicyRule(
    id: row.id,
    workspaceId: row.workspaceId,
    scopeType: ActionScopeType.fromWire(row.scopeType),
    scopeId: row.scopeId,
    actionClass: row.actionClass == null
        ? null
        : ActionClass.fromWire(row.actionClass!),
    commandPrefix: row.commandPrefix,
    decision: ActionDecision.fromWire(row.decision),
    provenance: row.provenance,
    createdBy: row.createdBy,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  /// Domain entity to companion.
  ActionPoliciesTableCompanion ruleToCompanion(ActionPolicyRule rule) =>
      ActionPoliciesTableCompanion(
        id: Value(rule.id),
        workspaceId: Value(rule.workspaceId),
        scopeType: Value(rule.scopeType.wire),
        scopeId: Value(rule.scopeId),
        actionClass: Value(rule.actionClass?.wire),
        commandPrefix: Value(rule.commandPrefix),
        decision: Value(rule.decision.wire),
        provenance: Value(rule.provenance),
        createdBy: Value(rule.createdBy),
        createdAt: Value(rule.createdAt),
        updatedAt: Value(rule.updatedAt),
      );
}
