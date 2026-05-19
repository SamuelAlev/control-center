import 'package:cc_persistence/database/tables/sandbox_exec_grants_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'sandbox_exec_grant_dao.g.dart';

/// Data access for sandbox exec grants. Every read filters by `workspaceId`
/// (workspace isolation invariant).
@DriftAccessor(tables: [SandboxExecGrantsTable])
class SandboxExecGrantDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$SandboxExecGrantDaoMixin {
  /// Creates a [SandboxExecGrantDao].
  SandboxExecGrantDao(super.db);

  /// Inserts or replaces a grant by id.
  Future<void> upsert(SandboxExecGrantsTableCompanion entry) =>
      into(sandboxExecGrantsTable).insertOnConflictUpdate(entry);

  /// All grants in [workspaceId], newest first.
  Future<List<SandboxExecGrantsTableData>> grants(String workspaceId) =>
      (select(sandboxExecGrantsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Live grants in [workspaceId] (the Settings surface).
  Stream<List<SandboxExecGrantsTableData>> watchGrants(String workspaceId) =>
      (select(sandboxExecGrantsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// The grant on exactly [path] within [workspaceId], or null.
  Future<SandboxExecGrantsTableData?> byPath(String workspaceId, String path) =>
      (select(sandboxExecGrantsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.path.equals(path),
          ))
          .getSingleOrNull();

  /// Deletes a grant within [workspaceId].
  Future<void> revoke(String workspaceId, String id) => (delete(
    sandboxExecGrantsTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();
}
