/// Provisions a per-conversation working root with isolated copy-on-write
/// worktrees of the workspace's repos, and tears them down on unit completion.
///
/// Layout produced (so an agent cwd'd at the root sees its repos under
/// `repos/`, and keeps its `AGENTS.md` + `.mcp.json`):
/// ```
/// <workspace>/<workspaceId>/conversations/<channelId>/
///   AGENTS.md        # symlink to the dispatched agent's instructions
///   .mcp.json        # symlink to the workspace MCP config
///   repos/<repo>/    # isolated CoW worktree on its own branch
/// ```
///
/// Implementations live in the data layer (filesystem + rift). This port lets
/// the domain `TicketDispatcher` and the messaging dispatch path provision
/// without importing infrastructure. All methods are no-op-safe and never throw
/// to the caller for provisioning failures — they degrade to the fallback dir.
abstract interface class RepoWorkspaceProvisionerPort {
  /// Ensures the conversation working root exists with an isolated worktree per
  /// linked repo (reusing existing ones), and returns the agent working
  /// directory. Returns [fallbackDir] when the workspace has no linked repo or
  /// provisioning fails.
  ///
  /// Branch naming: when [ticketKey] or [ticketTitle] is provided the
  /// configured branch template is rendered; otherwise a default
  /// `conv/<short-channel>` branch is used. Always fetches the latest base from
  /// GitHub (when a remote + token are available) before branching.
  Future<String> ensureConversationWorkspace({
    required String workspaceId,
    required String channelId,
    required String fallbackDir,
    String? agentConfigDir,
    String? ticketId,
    String? ticketKey,
    String? ticketTitle,
    String branchType,
  });

  /// Tears down every worktree for a conversation, scoped to [workspaceId].
  Future<void> releaseConversation({
    required String workspaceId,
    required String channelId,
  });

  /// CROSS-WORKSPACE teardown by channel id, used when the channel (and its
  /// workspace context) has already been deleted.
  Future<void> releaseConversationAnyWorkspace({required String channelId});

  /// Teardown by ticket id (ticket lifecycle events don't carry a workspaceId).
  Future<void> releaseTicket({required String ticketId});

  /// Tears down the worktrees a ticket owns, scoped to [workspaceId] — a ticket
  /// belonging to another workspace simply matches no rows. Returns the number
  /// of worktrees reaped. Use this from workspace-scoped callers (e.g. the
  /// cleanup pipeline) so the run never touches another workspace's data; the
  /// cross-workspace [releaseTicket] is reserved for the global GC listener,
  /// where ticket events carry no workspace context.
  Future<int> releaseTicketInWorkspace({
    required String workspaceId,
    required String ticketId,
  });

  /// Sweeps stale isolated worktrees in [workspaceId]: registry rows whose
  /// on-disk copy has vanished are destroyed (which also prunes the rift trash)
  /// and removed from the registry. Returns the number reaped. Safe to call
  /// repeatedly; healthy, in-use worktrees are left untouched. Used by the
  /// manual / scheduled cleanup pipeline as a catch-all for worktrees whose
  /// teardown event was missed (e.g. the app was closed when the unit ended).
  Future<int> sweepStale({required String workspaceId});
}
