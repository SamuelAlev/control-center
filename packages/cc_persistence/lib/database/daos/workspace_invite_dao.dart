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

  /// One SQL update arbitrates simultaneous redemptions on this workspace DB.
  Future<bool> consume(String id, String codeHash, DateTime now) async {
    final changed =
        await (update(workspaceInvitesTable)..where(
              (t) =>
                  t.id.equals(id) &
                  t.codeHash.equals(codeHash) &
                  t.usedAt.isNull() &
                  t.revokedAt.isNull() &
                  t.expiresAt.isBiggerThanValue(now),
            ))
            .write(WorkspaceInvitesTableCompanion(usedAt: Value(now)));
    return changed == 1;
  }

  /// Records the recipient without undoing the claim or reopening the code.
  Future<void> recordUsedBy(String id, String userId) async {
    await (update(workspaceInvitesTable)
          ..where((t) => t.id.equals(id) & t.usedAt.isNotNull()))
        .write(WorkspaceInvitesTableCompanion(usedBy: Value(userId)));
  }

  /// Inserts or updates an invite row.
  Future<void> upsert(WorkspaceInvitesTableCompanion entry) =>
      into(workspaceInvitesTable).insertOnConflictUpdate(entry);

  /// Deletes invite [id] scoped to [workspaceId].
  Future<int> deleteInvite(String workspaceId, String id) => (delete(
    workspaceInvitesTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();
}
