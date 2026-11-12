import 'package:cc_persistence/database/tables/workspace_roles_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'workspace_role_dao.g.dart';

/// Data access object for the [WorkspaceRolesTable] — custom (subtractive)
/// workspace roles.
@DriftAccessor(tables: [WorkspaceRolesTable])
class WorkspaceRoleDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$WorkspaceRoleDaoMixin {
  /// Creates a [WorkspaceRoleDao] bound to the given database.
  WorkspaceRoleDao(super.attachedDatabase);

  /// All custom roles in [workspaceId], by name.
  Future<List<WorkspaceRolesTableData>> forWorkspace(String workspaceId) =>
      (select(workspaceRolesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  /// Streams [forWorkspace].
  Stream<List<WorkspaceRolesTableData>> watchForWorkspace(String workspaceId) =>
      (select(workspaceRolesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  /// One custom role by id, scoped to [workspaceId] (a foreign id is simply
  /// not found).
  Future<WorkspaceRolesTableData?> byId(String workspaceId, String id) =>
      (select(workspaceRolesTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.id.equals(id),
          ))
          .getSingleOrNull();

  /// Inserts a role row, or updates the one with its id. A name another role
  /// holds is refused by the unique key, never resolved by replacing that
  /// role (members holding it would silently fall to guest).
  Future<void> upsert(WorkspaceRolesTableCompanion row) =>
      into(workspaceRolesTable).insertOnConflictUpdate(row);

  /// Deletes a role by id within [workspaceId].
  Future<void> deleteById(String workspaceId, String id) =>
      (delete(workspaceRolesTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.id.equals(id),
          ))
          .go();
}
