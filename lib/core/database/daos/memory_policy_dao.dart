import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/memory_policies.dart';
import 'package:drift/drift.dart';

part 'memory_policy_dao.g.dart';

@DriftAccessor(tables: [MemoryPoliciesTable])
/// Data access for memory policies.
class MemoryPolicyDao extends DatabaseAccessor<AppDatabase>
    with _$MemoryPolicyDaoMixin {
  /// Creates a [MemoryPolicyDao].
  MemoryPolicyDao(super.attachedDatabase);

  /// Watches policies in a workspace, newest first.
  Stream<List<MemoryPoliciesTableData>> watchByWorkspace(String workspaceId) =>
      (select(memoryPoliciesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Reads policies in a workspace, newest first.
  Future<List<MemoryPoliciesTableData>> getByWorkspace(String workspaceId) =>
      (select(memoryPoliciesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  /// Looks up a policy by id, scoped to [workspaceId]. A policy owned by
  /// another workspace is simply not found (policy ids are global UUIDs, so the
  /// workspace clause — not id uniqueness — is the isolation boundary).
  Future<MemoryPoliciesTableData?> getById(String workspaceId, String id) =>
      (select(memoryPoliciesTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .getSingleOrNull();

  /// Inserts or updates a policy.
  Future<void> upsert(MemoryPoliciesTableCompanion entry) =>
      into(memoryPoliciesTable).insertOnConflictUpdate(entry);

  /// Watches active policies in a workspace, newest first.
  Stream<List<MemoryPoliciesTableData>> watchActiveByWorkspace(
    String workspaceId,
  ) =>
      (select(memoryPoliciesTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.active.equals(true),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Reads active policies in a workspace, optionally filtered by [domain].
  Future<List<MemoryPoliciesTableData>> getActiveByWorkspace(
    String workspaceId, {
    String? domain,
  }) {
    final query = select(memoryPoliciesTable)
      ..where(
        (t) =>
            t.workspaceId.equals(workspaceId) &
            t.active.equals(true) &
            (domain != null ? t.domain.equals(domain) : const Constant(true)),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.get();
  }

  /// Deletes a policy by id, scoped to [workspaceId] so one workspace can never
  /// delete another's policy.
  Future<void> deleteById(String workspaceId, String id) =>
      (delete(memoryPoliciesTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .go();
}
