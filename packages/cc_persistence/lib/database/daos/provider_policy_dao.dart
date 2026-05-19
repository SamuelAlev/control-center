import 'package:cc_persistence/database/tables/provider_policies.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'provider_policy_dao.g.dart';

@DriftAccessor(tables: [ProviderPoliciesTable])
/// Data access for per-workspace provider-governance policy (PRD 05).
class ProviderPolicyDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ProviderPolicyDaoMixin {
  /// Creates a [ProviderPolicyDao].
  ProviderPolicyDao(super.attachedDatabase);

  /// Watches a workspace's statements, oldest-created first (stable order).
  Stream<List<ProviderPoliciesTableData>> watchByWorkspace(
    String workspaceId,
  ) =>
      (select(providerPoliciesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// Reads a workspace's statements, oldest-created first.
  Future<List<ProviderPoliciesTableData>> getByWorkspace(String workspaceId) =>
      (select(providerPoliciesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// Inserts or updates a statement.
  Future<void> upsert(ProviderPoliciesTableCompanion entry) =>
      into(providerPoliciesTable).insertOnConflictUpdate(entry);

  /// Deletes a statement by id, scoped to [workspaceId] so one workspace can
  /// never delete another's rule.
  Future<int> deleteById(String workspaceId, String id) => (delete(
    providerPoliciesTable,
  )..where((t) => t.id.equals(id) & t.workspaceId.equals(workspaceId))).go();
}
