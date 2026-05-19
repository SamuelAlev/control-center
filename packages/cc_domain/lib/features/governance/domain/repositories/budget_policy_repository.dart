import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:cc_domain/features/governance/domain/entities/budget_incident.dart';

/// Repository for budget policies and the incidents they raise. Every method is
/// workspace-scoped — `workspaceId` is required and never optional.
abstract interface class BudgetPolicyRepository {
  /// Watches all budget policies for [workspaceId].
  Stream<List<BudgetPolicy>> watchPolicies(String workspaceId);

  /// Returns all budget policies for [workspaceId].
  Future<List<BudgetPolicy>> listPolicies(String workspaceId);

  /// Returns a single policy by [id] within [workspaceId], or null.
  Future<BudgetPolicy?> getPolicyById(String workspaceId, String id);

  /// Returns the policy governing [scopeType]/[scopeId] in [workspaceId], or
  /// null when the scope is uncapped.
  Future<BudgetPolicy?> getPolicyForScope(
    String workspaceId,
    String scopeType,
    String scopeId,
  );

  /// Inserts or updates a budget policy.
  Future<void> upsertPolicy(BudgetPolicy policy);

  /// Deletes a policy by [id] within [workspaceId].
  Future<void> deletePolicy(String workspaceId, String id);

  /// Watches budget incidents for [workspaceId], newest first.
  Stream<List<BudgetIncident>> watchIncidents(String workspaceId);

  /// Returns budget incidents for a specific scope within [workspaceId].
  Future<List<BudgetIncident>> incidentsForScope(
    String workspaceId,
    String scopeType,
    String scopeId,
  );

  /// Records a budget incident.
  Future<void> recordIncident(BudgetIncident incident);
}
