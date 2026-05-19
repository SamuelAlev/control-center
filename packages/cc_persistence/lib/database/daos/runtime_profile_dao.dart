import 'package:cc_persistence/database/tables/runtime_profiles_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'runtime_profile_dao.g.dart';

/// Data access for custom runtime profiles. Every read filters by
/// `workspaceId`.
@DriftAccessor(tables: [RuntimeProfilesTable])
class RuntimeProfileDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$RuntimeProfileDaoMixin {
  /// Creates a [RuntimeProfileDao].
  RuntimeProfileDao(super.db);

  /// Watches all runtime profiles for [workspaceId], by name.
  Stream<List<RuntimeProfilesTableData>> watchByWorkspace(String workspaceId) =>
      (select(runtimeProfilesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  /// Returns all runtime profiles for [workspaceId].
  Future<List<RuntimeProfilesTableData>> getByWorkspace(String workspaceId) =>
      (select(
        runtimeProfilesTable,
      )..where((t) => t.workspaceId.equals(workspaceId))).get();

  /// Returns a single profile by [id] within [workspaceId], or null.
  Future<RuntimeProfilesTableData?> getById(String workspaceId, String id) =>
      (select(runtimeProfilesTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Inserts or updates a runtime profile.
  Future<void> upsert(RuntimeProfilesTableCompanion entry) =>
      into(runtimeProfilesTable).insertOnConflictUpdate(entry);

  /// Deletes a profile by [id] within [workspaceId]. Returns rows deleted.
  Future<int> deleteById(String workspaceId, String id) => (delete(
    runtimeProfilesTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();
}
