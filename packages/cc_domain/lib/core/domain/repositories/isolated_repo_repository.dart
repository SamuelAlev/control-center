import 'package:cc_domain/core/domain/entities/isolated_repo.dart';

/// Persistence for [IsolatedRepo] rows. Every read is workspace-scoped except
/// [forSpaceAcrossWorkspaces], a documented teardown path used when a space
/// (and its workspace context) has already been deleted.
abstract class IsolatedRepoRepository {
  /// The worktree for a specific `(workspace, space, repo)`, or null.
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  );

  /// All worktrees for a conversation, scoped to [workspaceId].
  Future<List<IsolatedRepo>> forSpace(String workspaceId, String spaceId);

  /// All worktrees for a ticket, scoped to [workspaceId].
  Future<List<IsolatedRepo>> forTicket(String workspaceId, String ticketId);

  /// CROSS-WORKSPACE BY DESIGN: teardown lookup by globally-unique space id.
  /// Each row carries its own workspaceId. Prefer [forSpace] when known.
  Future<List<IsolatedRepo>> forSpaceAcrossWorkspaces(String spaceId);

  /// CROSS-WORKSPACE BY DESIGN: teardown lookup by ticket id (ticket events
  /// carry no workspaceId). Each row carries its own workspaceId.
  Future<List<IsolatedRepo>> forTicketAcrossWorkspaces(String ticketId);

  /// Watches every worktree in a workspace.
  Stream<List<IsolatedRepo>> watchForWorkspace(String workspaceId);

  /// Inserts or updates a worktree row.
  Future<void> upsert(IsolatedRepo repo);

  /// Deletes the worktree row [id] within [workspaceId]. The id resolves only
  /// inside that workspace, so a row belonging to another one is untouched.
  Future<void> deleteById(String workspaceId, String id);
}
