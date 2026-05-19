/// A lightweight view of a worktree's ticket link, enough to resolve the
/// "current" ticket from a working directory without coupling the ticketing
/// feature to the full worktree entity.
///
/// [ticketId] is the Control Center ticket the worktree is working on (the CC
/// link). [vendor] / [externalId] capture the same ticket on an external vendor
/// (e.g. `linear` / `ENG-123`), so an agent that pasted a vendor key can be
/// resolved back to the CC ticket and vice-versa.
class WorktreeTicketRef {
  /// Creates a [WorktreeTicketRef].
  const WorktreeTicketRef({
    required this.worktreeId,
    required this.workspaceId,
    required this.path,
    this.ticketId,
    this.vendor,
    this.externalId,
  });

  /// The worktree's row id.
  final String worktreeId;

  /// Workspace scope.
  final String workspaceId;

  /// Absolute path to the worktree on disk.
  final String path;

  /// Linked Control Center ticket id, if any.
  final String? ticketId;

  /// Vendor the ticket is mirrored to (e.g. `linear`), if known.
  final String? vendor;

  /// Vendor-native key / id for the linked ticket (e.g. `ENG-123`), if known.
  final String? externalId;

  /// Whether this worktree is linked to a ticket at all.
  bool get hasTicket => ticketId != null || externalId != null;
}

/// Persistence boundary for the worktree↔ticket link (workspace-scoped). Backed
/// by the worktree (`isolated_repos`) rows; the ticketing feature talks only to
/// this narrow port.
abstract interface class WorktreeTicketLinkPort {
  /// All worktrees in a workspace, with their ticket links. Used to resolve the
  /// current ticket from a working directory.
  Future<List<WorktreeTicketRef>> forWorkspace(String workspaceId);

  /// The worktree with the given id, scoped to [workspaceId], or null.
  Future<WorktreeTicketRef?> byId(String workspaceId, String worktreeId);

  /// Persists / updates the ticket link on a worktree, scoped to [workspaceId].
  Future<void> linkTicket({
    required String workspaceId,
    required String worktreeId,
    String? ticketId,
    String? vendor,
    String? externalId,
  });
}
