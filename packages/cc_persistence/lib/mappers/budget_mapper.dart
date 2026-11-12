import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:cc_domain/features/governance/domain/entities/budget_incident.dart';
import 'package:cc_domain/features/governance/domain/value_objects/budget_scope.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [BudgetPolicy] / [BudgetIncident] domain entities and their
/// table rows.
class BudgetMapper {
  /// Creates a [BudgetMapper].
  const BudgetMapper();

  /// Policy to domain.
  BudgetPolicy policyToDomain(BudgetPolicyTableData row) => BudgetPolicy(
    id: row.id,
    workspaceId: row.workspaceId,
    scopeType: row.scopeType,
    scopeId: row.scopeId,
    monthlyBudgetMicros: row.monthlyBudgetMicros,
    softThresholdPercent: row.softThresholdPercent,
    hardStopEnabled: row.hardStopEnabled,
    spentMicros: row.spentMicros,
    status: row.status,
    periodStart: row.periodStart,
    periodEnd: row.periodEnd,
    createdAt: row.createdAt,
  );

  /// Policy list to domain.
  List<BudgetPolicy> policiesToDomain(List<BudgetPolicyTableData> rows) =>
      rows.map(policyToDomain).toList(growable: false);

  /// Policy to companion.
  BudgetPolicyTableCompanion policyToCompanion(BudgetPolicy p) =>
      BudgetPolicyTableCompanion(
        id: Value(p.id),
        workspaceId: Value(p.workspaceId),
        scopeType: Value(BudgetScopeType.parse(p.scopeType).wire),
        scopeId: Value(p.scopeId),
        monthlyBudgetMicros: Value(p.monthlyBudgetMicros),
        softThresholdPercent: Value(p.softThresholdPercent),
        hardStopEnabled: Value(p.hardStopEnabled),
        spentMicros: Value(p.spentMicros),
        status: Value(BudgetPolicyStatus.parse(p.status).wire),
        periodStart: p.periodStart == null
            ? const Value.absent()
            : Value(p.periodStart!),
        periodEnd: Value(p.periodEnd),
        createdAt: p.createdAt == null
            ? const Value.absent()
            : Value(p.createdAt!),
      );

  /// Incident to domain.
  BudgetIncident incidentToDomain(BudgetIncidentsTableData row) =>
      BudgetIncident(
        id: row.id,
        workspaceId: row.workspaceId,
        policyId: row.policyId,
        scopeType: row.scopeType,
        scopeId: row.scopeId,
        spentMicros: row.spentMicros,
        budgetMicros: row.budgetMicros,
        isHardStop: row.isHardStop,
        reason: row.reason,
        triggeredAt: row.triggeredAt,
      );

  /// Incident list to domain.
  List<BudgetIncident> incidentsToDomain(List<BudgetIncidentsTableData> rows) =>
      rows.map(incidentToDomain).toList(growable: false);

  /// Incident to companion.
  BudgetIncidentsTableCompanion incidentToCompanion(BudgetIncident i) =>
      BudgetIncidentsTableCompanion(
        id: Value(i.id),
        workspaceId: Value(i.workspaceId),
        policyId: Value(i.policyId),
        scopeType: Value(BudgetScopeType.parse(i.scopeType).wire),
        scopeId: Value(i.scopeId),
        spentMicros: Value(i.spentMicros),
        budgetMicros: Value(i.budgetMicros),
        isHardStop: Value(i.isHardStop),
        reason: Value(i.reason),
        triggeredAt: Value(i.triggeredAt),
      );
}
