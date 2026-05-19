import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:cc_domain/features/governance/domain/entities/budget_incident.dart';
import 'package:cc_domain/features/governance/domain/repositories/budget_policy_repository.dart';
import 'package:cc_persistence/database/daos/budget_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/budget_mapper.dart';

/// Drift-backed [BudgetPolicyRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).budgetDao` per call: budget policies and incidents live
/// in their workspace's own database file, so the workspace id picks the file
/// before any SQL runs.
class DaoBudgetPolicyRepository implements BudgetPolicyRepository {
  /// Creates a [DaoBudgetPolicyRepository] over the per-workspace databases.
  DaoBudgetPolicyRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final BudgetMapper _mapper = const BudgetMapper();

  BudgetDao _dao(String workspaceId) => _dbs.of(workspaceId).budgetDao;

  @override
  Stream<List<BudgetPolicy>> watchPolicies(String workspaceId) => _dao(
    workspaceId,
  ).watchPolicies(workspaceId).map(_mapper.policiesToDomain);

  @override
  Future<List<BudgetPolicy>> listPolicies(String workspaceId) async => _mapper
      .policiesToDomain(await _dao(workspaceId).getPolicies(workspaceId));

  @override
  Future<BudgetPolicy?> getPolicyById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getPolicyById(workspaceId, id);
    return row == null ? null : _mapper.policyToDomain(row);
  }

  @override
  Future<BudgetPolicy?> getPolicyForScope(
    String workspaceId,
    String scopeType,
    String scopeId,
  ) async {
    final row = await _dao(
      workspaceId,
    ).getPolicyForScope(workspaceId, scopeType, scopeId);
    return row == null ? null : _mapper.policyToDomain(row);
  }

  @override
  Future<void> upsertPolicy(BudgetPolicy policy) =>
      // The policy carries its own workspace, so the file is picked from the
      // entity rather than from a parameter that could disagree with it.
      _dao(policy.workspaceId).upsertPolicy(_mapper.policyToCompanion(policy));

  @override
  Future<void> deletePolicy(String workspaceId, String id) =>
      _dao(workspaceId).deletePolicy(workspaceId, id).then((_) {});

  @override
  Stream<List<BudgetIncident>> watchIncidents(String workspaceId) => _dao(
    workspaceId,
  ).watchIncidents(workspaceId).map(_mapper.incidentsToDomain);

  @override
  Future<List<BudgetIncident>> incidentsForScope(
    String workspaceId,
    String scopeType,
    String scopeId,
  ) async => _mapper.incidentsToDomain(
    await _dao(workspaceId).incidentsForScope(workspaceId, scopeType, scopeId),
  );

  @override
  Future<void> recordIncident(BudgetIncident incident) =>
      // The incident carries the workspace whose budget it belongs to.
      _dao(
        incident.workspaceId,
      ).insertIncident(_mapper.incidentToCompanion(incident));
}
