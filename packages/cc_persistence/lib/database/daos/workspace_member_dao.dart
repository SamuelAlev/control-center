import 'package:cc_persistence/database/tables/workspace_member_repo_grants_table.dart';
import 'package:cc_persistence/database/tables/workspace_members_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'workspace_member_dao.g.dart';

/// Data access object for [WorkspaceMembersTable] and
/// [WorkspaceMemberRepoGrantsTable].
///
/// Membership is the workspace access boundary; every query here is scoped by
/// `workspaceId` or `userId`. There is deliberately no unscoped listing.
@DriftAccessor(tables: [WorkspaceMembersTable, WorkspaceMemberRepoGrantsTable])
class WorkspaceMemberDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$WorkspaceMemberDaoMixin {
  /// Creates a [WorkspaceMemberDao] for the given database.
  WorkspaceMemberDao(super.attachedDatabase);

  /// Members of [workspaceId], oldest first.
  Future<List<WorkspaceMembersTableData>> getForWorkspace(String workspaceId) =>
      (select(workspaceMembersTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.joinedAt)]))
          .get();

  /// Watches members of [workspaceId], oldest first.
  Stream<List<WorkspaceMembersTableData>> watchForWorkspace(
    String workspaceId,
  ) =>
      (select(workspaceMembersTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.joinedAt)]))
          .watch();

  /// The membership of [userId] in [workspaceId], or null.
  Future<WorkspaceMembersTableData?> getMember(
    String workspaceId,
    String userId,
  ) =>
      (select(workspaceMembersTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.userId.equals(userId),
          ))
          .getSingleOrNull();

  /// All memberships of [userId] across workspaces (drives the picker: a user
  /// sees only workspaces they belong to). Scoped by user, not workspace.
  Future<List<WorkspaceMembersTableData>> getForUser(String userId) => (select(
    workspaceMembersTable,
  )..where((t) => t.userId.equals(userId))).get();

  /// Watches all memberships of [userId] across workspaces.
  Stream<List<WorkspaceMembersTableData>> watchForUser(String userId) =>
      (select(
        workspaceMembersTable,
      )..where((t) => t.userId.equals(userId))).watch();

  /// Inserts or updates a membership row.
  Future<void> upsert(WorkspaceMembersTableCompanion entry) =>
      into(workspaceMembersTable).insertOnConflictUpdate(entry);

  /// Changes [userId]'s role in [workspaceId].
  Future<int> setRole(String workspaceId, String userId, String role) =>
      (update(workspaceMembersTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.userId.equals(userId),
          ))
          .write(WorkspaceMembersTableCompanion(role: Value(role)));

  /// Removes [userId] from [workspaceId], along with their repo grants.
  Future<void> remove(String workspaceId, String userId) async {
    await (delete(workspaceMemberRepoGrantsTable)..where(
          (t) => t.workspaceId.equals(workspaceId) & t.userId.equals(userId),
        ))
        .go();
    await (delete(workspaceMembersTable)..where(
          (t) => t.workspaceId.equals(workspaceId) & t.userId.equals(userId),
        ))
        .go();
  }

  /// Per-repo grants of [userId] in [workspaceId].
  Future<List<WorkspaceMemberRepoGrantsTableData>> getRepoGrants(
    String workspaceId,
    String userId,
  ) =>
      (select(workspaceMemberRepoGrantsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.userId.equals(userId),
          ))
          .get();

  /// Watches per-repo grants of [userId] in [workspaceId].
  Stream<List<WorkspaceMemberRepoGrantsTableData>> watchRepoGrants(
    String workspaceId,
    String userId,
  ) =>
      (select(workspaceMemberRepoGrantsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.userId.equals(userId),
          ))
          .watch();

  /// Inserts or updates a repo grant row.
  Future<void> upsertRepoGrant(WorkspaceMemberRepoGrantsTableCompanion entry) =>
      into(workspaceMemberRepoGrantsTable).insertOnConflictUpdate(entry);

  /// Removes [userId]'s grant on [repoId] in [workspaceId].
  Future<int> removeRepoGrant(
    String workspaceId,
    String userId,
    String repoId,
  ) =>
      (delete(workspaceMemberRepoGrantsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.userId.equals(userId) &
                t.repoId.equals(repoId),
          ))
          .go();
}
