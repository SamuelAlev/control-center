import 'package:cc_domain/core/domain/entities/isolated_repo.dart';

/// Persistence for [IsolatedRepo] rows. Every read is workspace-scoped except
/// [forChannelAcrossWorkspaces], a documented teardown path used when a channel
/// (and its workspace context) has already been deleted.
abstract class IsolatedRepoRepository {
  /// The worktree for a specific `(workspace, channel, repo)`, or null.
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String channelId,
    String repoId,
  );

  /// All worktrees for a conversation, scoped to [workspaceId].
  Future<List<IsolatedRepo>> forChannel(String workspaceId, String channelId);

  /// All worktrees for a ticket, scoped to [workspaceId].
  Future<List<IsolatedRepo>> forTicket(String workspaceId, String ticketId);

  /// CROSS-WORKSPACE BY DESIGN: teardown lookup by globally-unique channel id.
  /// Each row carries its own workspaceId. Prefer [forChannel] when known.
  Future<List<IsolatedRepo>> forChannelAcrossWorkspaces(String channelId);

  /// CROSS-WORKSPACE BY DESIGN: teardown lookup by ticket id (ticket events
  /// carry no workspaceId). Each row carries its own workspaceId.
  Future<List<IsolatedRepo>> forTicketAcrossWorkspaces(String ticketId);

  /// Watches every worktree in a workspace.
  Stream<List<IsolatedRepo>> watchForWorkspace(String workspaceId);

  /// Inserts or updates a worktree row.
  Future<void> upsert(IsolatedRepo repo);

  /// Deletes a worktree row by [id].
  Future<void> deleteById(String id);
}
