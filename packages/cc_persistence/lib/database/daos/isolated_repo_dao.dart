import 'package:cc_persistence/database/tables/isolated_repos.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'isolated_repo_dao.g.dart';

/// Data access object for [IsolatedReposTable]. All reads are workspace-scoped
/// except [findBySpaceAcrossWorkspaces], which is a documented teardown path.
@DriftAccessor(tables: [IsolatedReposTable])
class IsolatedRepoDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$IsolatedRepoDaoMixin {
  /// Creates an [IsolatedRepoDao].
  IsolatedRepoDao(super.attachedDatabase);

  /// The worktree for a specific `(workspace, space, repo)`, or null.
  Future<IsolatedReposTableData?> findForUnit(
    String workspaceId,
    String spaceId,
    String repoId,
  ) =>
      (select(isolatedReposTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId) &
                t.repoId.equals(repoId),
          ))
          .getSingleOrNull();

  /// All worktrees for a conversation, scoped to [workspaceId].
  Future<List<IsolatedReposTableData>> forSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(isolatedReposTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId),
          ))
          .get();

  /// All worktrees for a ticket, scoped to [workspaceId].
  Future<List<IsolatedReposTableData>> forTicket(
    String workspaceId,
    String ticketId,
  ) =>
      (select(isolatedReposTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) & t.ticketId.equals(ticketId),
          ))
          .get();

  /// Teardown lookup by space id, for when the space — and with it the
  /// workspace context — has already been deleted.
  ///
  /// Answering it across the install means asking each workspace's database in
  /// turn; each returned row still carries its own `workspaceId`, which is what
  /// the GC use case then passes to `deleteById`. Prefer [forSpace] when the
  /// workspace is known.
  Future<List<IsolatedReposTableData>> findBySpaceAcrossWorkspaces(
    String spaceId,
  ) => (select(
    isolatedReposTable,
  )..where((t) => t.spaceId.equals(spaceId))).get();

  /// Teardown lookup by ticket id, for ticket lifecycle events
  /// (TicketCompleted/TicketCancelled) that carry only a ticket id.
  ///
  /// Each returned row carries its own `workspaceId`, which is what the caller
  /// then passes to `deleteById`.
  Future<List<IsolatedReposTableData>> findByTicketAcrossWorkspaces(
    String ticketId,
  ) => (select(
    isolatedReposTable,
  )..where((t) => t.ticketId.equals(ticketId))).get();

  /// Watches every worktree in a workspace (used by diagnostics/UI).
  Stream<List<IsolatedReposTableData>> watchForWorkspace(String workspaceId) =>
      (select(isolatedReposTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// All worktrees in a workspace (non-stream), for the current-ticket /
  /// worktree-link resolution path.
  Future<List<IsolatedReposTableData>> listForWorkspace(String workspaceId) =>
      (select(
        isolatedReposTable,
      )..where((t) => t.workspaceId.equals(workspaceId))).get();

  /// A single worktree scoped to [workspaceId], or null.
  Future<IsolatedReposTableData?> findById(String workspaceId, String id) =>
      (select(isolatedReposTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Sets the ticket link on a worktree, scoped to [workspaceId]. Returns rows
  /// updated (0 when the worktree is missing / in another workspace).
  Future<int> setTicketLink(
    String workspaceId,
    String id, {
    String? ticketId,
    String? vendor,
    String? externalId,
  }) =>
      (update(isolatedReposTable)
            ..where((t) => t.id.equals(id) & t.workspaceId.equals(workspaceId)))
          .write(
            IsolatedReposTableCompanion(
              ticketId: Value(ticketId),
              linkedTicketVendor: Value(vendor),
              linkedTicketExternalId: Value(externalId),
            ),
          );

  /// Inserts or updates a worktree row.
  Future<void> upsert(IsolatedReposTableCompanion entry) =>
      into(isolatedReposTable).insertOnConflictUpdate(entry);

  /// Deletes a worktree row by [id].
  Future<void> deleteById(String id) =>
      (delete(isolatedReposTable)..where((t) => t.id.equals(id))).go();
}
