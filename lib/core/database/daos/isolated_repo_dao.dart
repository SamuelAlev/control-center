import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/isolated_repos.dart';
import 'package:drift/drift.dart';

part 'isolated_repo_dao.g.dart';

/// Data access object for [IsolatedReposTable]. All reads are workspace-scoped
/// except [findByChannelAcrossWorkspaces], which is a documented teardown path.
@DriftAccessor(tables: [IsolatedReposTable])
class IsolatedRepoDao extends DatabaseAccessor<AppDatabase>
    with _$IsolatedRepoDaoMixin {
  /// Creates an [IsolatedRepoDao].
  IsolatedRepoDao(super.attachedDatabase);

  /// The worktree for a specific `(workspace, channel, repo)`, or null.
  Future<IsolatedReposTableData?> findForUnit(
    String workspaceId,
    String channelId,
    String repoId,
  ) =>
      (select(isolatedReposTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.channelId.equals(channelId) &
                  t.repoId.equals(repoId),
            ))
          .getSingleOrNull();

  /// All worktrees for a conversation, scoped to [workspaceId].
  Future<List<IsolatedReposTableData>> forChannel(
    String workspaceId,
    String channelId,
  ) =>
      (select(isolatedReposTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.channelId.equals(channelId),
            ))
          .get();

  /// All worktrees for a ticket, scoped to [workspaceId].
  Future<List<IsolatedReposTableData>> forTicket(
    String workspaceId,
    String ticketId,
  ) =>
      (select(isolatedReposTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.ticketId.equals(ticketId),
            ))
          .get();

  /// CROSS-WORKSPACE BY DESIGN: teardown lookup by globally-unique channel id
  /// used when the channel (and thus its workspace context) has already been
  /// deleted. Each returned row still carries its own `workspaceId`; the GC use
  /// case validates against it. Prefer [forChannel] when the workspace is known.
  Future<List<IsolatedReposTableData>> findByChannelAcrossWorkspaces(
    String channelId,
  ) =>
      (select(isolatedReposTable)..where((t) => t.channelId.equals(channelId)))
          .get();

  /// CROSS-WORKSPACE BY DESIGN: teardown lookup by ticket id. Ticket lifecycle
  /// events (TicketCompleted/TicketCancelled) carry only a ticketId, not a
  /// workspaceId; each returned row still carries its own `workspaceId`.
  Future<List<IsolatedReposTableData>> findByTicketAcrossWorkspaces(
    String ticketId,
  ) =>
      (select(isolatedReposTable)..where((t) => t.ticketId.equals(ticketId)))
          .get();

  /// Watches every worktree in a workspace (used by diagnostics/UI).
  Stream<List<IsolatedReposTableData>> watchForWorkspace(String workspaceId) =>
      (select(isolatedReposTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Inserts or updates a worktree row.
  Future<void> upsert(IsolatedReposTableCompanion entry) =>
      into(isolatedReposTable).insertOnConflictUpdate(entry);

  /// Deletes a worktree row by [id].
  Future<void> deleteById(String id) =>
      (delete(isolatedReposTable)..where((t) => t.id.equals(id))).go();
}
