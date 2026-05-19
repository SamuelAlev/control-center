import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:cc_domain/features/governance/domain/entities/budget_incident.dart';
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
    monthlyBudgetCents: row.monthlyBudgetCents,
    softThresholdPercent: row.softThresholdPercent,
    hardStopEnabled: row.hardStopEnabled,
    spentCents: row.spentCents,
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
        scopeType: Value(p.scopeType),
        scopeId: Value(p.scopeId),
        monthlyBudgetCents: Value(p.monthlyBudgetCents),
        softThresholdPercent: Value(p.softThresholdPercent),
        hardStopEnabled: Value(p.hardStopEnabled),
        spentCents: Value(p.spentCents),
        status: Value(p.status),
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
        spentCents: row.spentCents,
        budgetCents: row.budgetCents,
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
        scopeType: Value(i.scopeType),
        scopeId: Value(i.scopeId),
        spentCents: Value(i.spentCents),
        budgetCents: Value(i.budgetCents),
        isHardStop: Value(i.isHardStop),
        reason: Value(i.reason),
        triggeredAt: Value(i.triggeredAt),
      );
}
