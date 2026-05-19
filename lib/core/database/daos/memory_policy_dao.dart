import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/memory_policies.dart';
import 'package:drift/drift.dart';

part 'memory_policy_dao.g.dart';

@DriftAccessor(tables: [MemoryPoliciesTable])
class MemoryPolicyDao extends DatabaseAccessor<AppDatabase>
    with _$MemoryPolicyDaoMixin {
  MemoryPolicyDao(super.attachedDatabase);

  Stream<List<MemoryPoliciesTableData>> watchByWorkspace(String workspaceId) =>
      (select(memoryPoliciesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<List<MemoryPoliciesTableData>> getByWorkspace(String workspaceId) =>
      (select(memoryPoliciesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<MemoryPoliciesTableData?> getById(String id) =>
      (select(memoryPoliciesTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsert(MemoryPoliciesTableCompanion entry) =>
      into(memoryPoliciesTable).insertOnConflictUpdate(entry);

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

  Future<void> deleteById(String id) =>
      (delete(memoryPoliciesTable)..where((t) => t.id.equals(id))).go();
}
