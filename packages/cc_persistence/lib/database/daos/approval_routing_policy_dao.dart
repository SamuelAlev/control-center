import 'package:cc_persistence/database/tables/approval_routing_policies_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'approval_routing_policy_dao.g.dart';

/// Data access object for the [ApprovalRoutingPoliciesTable] — the durable
/// per-workspace approval routing policy (formerly a `caches` row, which the
/// retention sweep deleted after 21 quiet days).
@DriftAccessor(tables: [ApprovalRoutingPoliciesTable])
class ApprovalRoutingPolicyDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ApprovalRoutingPolicyDaoMixin {
  /// Creates an [ApprovalRoutingPolicyDao] bound to the given database.
  ApprovalRoutingPolicyDao(super.attachedDatabase);

  /// The stored policy JSON for [workspaceId], or null when never configured.
  Future<String?> read(String workspaceId) async {
    final row = await (select(
      approvalRoutingPoliciesTable,
    )..where((t) => t.workspaceId.equals(workspaceId))).getSingleOrNull();
    return row?.policyJson;
  }

  /// Writes [policyJson] as [workspaceId]'s policy (insert-or-replace).
  Future<void> write(String workspaceId, String policyJson) =>
      into(approvalRoutingPoliciesTable).insert(
        ApprovalRoutingPoliciesTableCompanion.insert(
          workspaceId: workspaceId,
          policyJson: policyJson,
          updatedAt: Value(DateTime.now()),
        ),
        mode: InsertMode.insertOrReplace,
      );
}
