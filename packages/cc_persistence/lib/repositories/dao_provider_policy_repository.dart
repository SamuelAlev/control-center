import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_persistence/database/daos/provider_policy_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [ProviderPolicyRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).providerPolicyDao` per call: policies live in their
/// workspace's own database file, so the workspace id picks the file before any
/// SQL runs.
class DaoProviderPolicyRepository implements ProviderPolicyRepository {
  /// Creates a [DaoProviderPolicyRepository] over the per-workspace databases.
  DaoProviderPolicyRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  ProviderPolicyDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).providerPolicyDao;

  @override
  Future<List<WorkspaceProviderPolicy>> listForWorkspace(
    String workspaceId,
  ) async {
    final rows = await _dao(workspaceId).getByWorkspace(workspaceId);
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<List<WorkspaceProviderPolicy>> watchForWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchByWorkspace(workspaceId)
          .map((rows) => rows.map(_toEntity).toList());

  @override
  Future<void> upsert(
    String workspaceId,
    String id,
    PolicyStatement statement,
  ) => _dao(workspaceId).upsert(
    ProviderPoliciesTableCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      action: Value(statement.action),
      resource: Value(statement.resource),
      effect: Value(statement.effect.id),
      layer: Value(statement.layer.name),
      updatedAt: Value(DateTime.now()),
    ),
  );

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(workspaceId, id);

  @override
  Future<ProviderPolicyEngine> engineFor(String workspaceId) async {
    final policies = await listForWorkspace(workspaceId);
    return ProviderPolicyEngine.fromStatements(
      policies.map((p) => p.statement),
    );
  }

  WorkspaceProviderPolicy _toEntity(ProviderPoliciesTableData row) =>
      WorkspaceProviderPolicy(
        id: row.id,
        statement: PolicyStatement(
          action: row.action,
          resource: row.resource,
          effect: PolicyEffect.fromRaw(row.effect),
          layer: PolicyLayer.values.firstWhere(
            (l) => l.name == row.layer,
            orElse: () => PolicyLayer.workspace,
          ),
        ),
      );
}
