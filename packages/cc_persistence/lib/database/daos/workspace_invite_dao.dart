import 'package:cc_persistence/database/tables/workspace_invites_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'workspace_invite_dao.g.dart';

/// Data access object for [WorkspaceInvitesTable].
///
/// Workspace-scoped except [getByCodeHash], the pre-auth redemption lookup:
/// possession of the (unstored) code is the proof and its hash is unique
/// across workspaces.
@DriftAccessor(tables: [WorkspaceInvitesTable])
class WorkspaceInviteDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$WorkspaceInviteDaoMixin {
  /// Creates a [WorkspaceInviteDao] for the given database.
  WorkspaceInviteDao(super.attachedDatabase);

  /// Invites of [workspaceId], newest first.
  Future<List<WorkspaceInvitesTableData>> getForWorkspace(String workspaceId) =>
      (select(workspaceInvitesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Watches invites of [workspaceId], newest first.
  Stream<List<WorkspaceInvitesTableData>> watchForWorkspace(
    String workspaceId,
  ) =>
      (select(workspaceInvitesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// The invite whose stored hash matches [codeHash], or null.
  ///
  /// Pre-auth redemption lookup: the caller holds the one-time code (the
  /// proof) and no workspace.
  ///
  /// The workspace is resolved first through the global `workspace_routes` index
  /// (`WorkspaceRouteKind.inviteCode`) and this then runs against that
  /// workspace's database. A route miss is a miss — there is deliberately no
  /// scan across workspaces for an unauthenticated caller to probe with.
  Future<WorkspaceInvitesTableData?> getByCodeHash(String codeHash) => (select(
    workspaceInvitesTable,
  )..where((t) => t.codeHash.equals(codeHash))).getSingleOrNull();

  /// Inserts or updates an invite row.
  Future<void> upsert(WorkspaceInvitesTableCompanion entry) =>
      into(workspaceInvitesTable).insertOnConflictUpdate(entry);

  /// Deletes invite [id] scoped to [workspaceId].
  Future<int> deleteInvite(String workspaceId, String id) => (delete(
    workspaceInvitesTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();
}
