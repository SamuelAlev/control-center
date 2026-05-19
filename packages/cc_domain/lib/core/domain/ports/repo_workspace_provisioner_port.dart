/// Provisions a per-conversation working root with isolated copy-on-write
/// worktrees of the workspace's repos and tears them down on unit completion.
///
/// Layout produced (a per-agent cwd sharing the conversation's `repos/`):
/// ```
/// <workspace>/<workspaceId>/conversations/<channelId>/   # convRoot
///   repos/<repo>/        # shared isolated CoW worktree on its own branch
///   agents/<agentSlug>/  # THIS agent's cwd (returned)
///     AGENTS.md          # symlink to the dispatched agent's instructions
///     .agents            # symlink to the agent's global skills dir
///     repos              # symlink -> ../../repos (the shared worktrees)
/// ```
///
/// The cwd's `.mcp.json` is NOT provisioned here — cc_server derives it from
/// `mcp_config.json` at dispatch time. Implementations live in the data layer
/// (filesystem + rift). This port lets the domain `TicketDispatcher` and the
/// messaging dispatch path provision without importing infrastructure. All
/// methods are no-op-safe and never throw to the caller for provisioning
/// failures — they degrade to the fallback dir.
abstract interface class RepoWorkspaceProvisionerPort {
  /// Ensures the conversation working root exists with an isolated worktree per
  /// linked repo (reusing existing ones), builds the per-agent overlay at
  /// `agents/<agentSlug>/` (AGENTS.md + .agents + repos symlinks) and returns
  /// that overlay dir as the agent's working directory. Returns [fallbackDir]
  /// when the workspace has no linked repo or provisioning fails.
  ///
  /// [agentSlug] is the dispatched agent's slugified name — the per-agent cwd is
  /// keyed by it so two agents in the same channel get distinct overlays that
  /// share `repos/`. [agentConfigDir] is the agent's global dir (the symlink
  /// target source for AGENTS.md + .agents).
  ///
  /// Branch naming: when [ticketKey] or [ticketTitle] is provided the
  /// configured branch template is rendered; otherwise a default
  /// `conv/<short-channel>` branch is used. Always fetches the latest base from
  /// GitHub (when a remote + token are available) before branching.
  /// When [prHeadRef] is set (e.g. `refs/pull/42/head`), the repo whose
  /// `owner/name` equals [prHeadRepoFullName] is checked out at that ref on a
  /// [prBranch] (default `pr/<number>`) instead of the default base branch — so
  /// a PR-review conversation's worktree IS the PR's proposed tree (checked out
  /// clean/pristine). Other repos provision normally.
  ///
  /// When [repoAllowlist] is non-null, only the workspace repos whose id is in
  /// the set are provisioned (a PR channel passes just the PR's repo; a channel
  /// created with an explicit repo selection passes those). Null → every linked
  /// repo, preserving pre-selection behaviour.
  ///
  /// [onRepoProvision] fires right before a repo worktree is actually
  /// materialized (reused worktrees don't fire), with the repo's display name
  /// and whether it is being checked out at a PR head — so callers can surface
  /// live provisioning progress. Must not throw.
  Future<String> ensureConversationWorkspace({
    required String workspaceId,
    required String channelId,
    required String agentSlug,
    required String fallbackDir,
    String? agentConfigDir,
    String? ticketId,
    String? ticketKey,
    String? ticketTitle,
    String branchType,
    String? prHeadRef,
    String? prHeadRepoFullName,
    String? prBranch,
    Set<String>? repoAllowlist,
    void Function(String repoName, {required bool prHead})? onRepoProvision,
  });

  /// Tears down every worktree for a conversation, scoped to [workspaceId].
  Future<void> releaseConversation({
    required String workspaceId,
    required String channelId,
  });

  /// CROSS-WORKSPACE teardown by channel id.
  ///
  /// NOTHING ROUTES HERE AUTOMATICALLY any more. It existed because
  /// `ChannelDeleted` carried an optional workspace and the GC listener fell
  /// back to scanning every workspace file when one was missing — a
  /// cross-workspace scan as the failure mode of an omitted argument. The
  /// event now requires its workspace, so this survives only as an explicit
  /// repair tool for a channel whose workspace context is genuinely lost
  /// (a half-finished import, a registry that lost a row). If nothing calls
  /// it by the next sweep of this file, delete it — and note that the cost
  /// went up when `CrossWorkspaceQueries` moved to
  /// `WorkspaceDatabaseManager.useTransiently`: a scan now OPENS AND CLOSES
  /// every workspace file to answer one channel delete.
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

  /// Sweeps stale isolated worktrees in [workspaceId] and returns the number
  /// reaped. Safe to call repeatedly; healthy, in-use worktrees are untouched.
  ///
  /// Three kinds of staleness, all destroyed (which also prunes the rift trash)
  /// and removed from the registry:
  ///
  /// * the worktree's on-disk copy has VANISHED — the original signal;
  /// * its CHANNEL no longer exists. Deleting a conversation fires
  ///   `ChannelDeleted` → `releaseConversation`, but an event missed while the
  ///   server was down (or a row deleted straight from the database) leaves a
  ///   fully-intact worktree that nothing else will ever reclaim — along with
  ///   the code-graph partition hanging off it;
  /// * an orphan conversation FOLDER whose channel is gone: the per-agent
  ///   overlays and their token-bearing `.mcp.json` files, which linger even
  ///   after the worktree rows are reaped.
  ///
  /// Fails safe: when channel existence cannot be determined the worktree is
  /// treated as live, so an unavailable lookup never destroys real work.
  Future<int> sweepStale({required String workspaceId});
}
