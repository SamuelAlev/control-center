import 'package:cc_harness/cancellation.dart';

/// Provisions a per-SPACE working root with isolated copy-on-write worktrees of
/// the workspace's repos and tears them down on unit completion.
///
/// Layout produced (a per-agent cwd sharing the SPACE's `repos/`):
/// ```
/// <workspace>/<workspaceId>/spaces/<spaceId>/   # spaceRoot
///   repos/<repo>/        # shared isolated CoW worktree on its own branch
///   agents/<agentSlug>/  # THIS agent's cwd (returned)
///     AGENTS.md          # symlink to the dispatched agent's instructions
///     .agents            # symlink to the agent's global skills dir
///     repos              # symlink -> ../../repos (the shared worktrees)
/// ```
///
/// **The SPACE owns the clone.** Every conversation in a space works in the
/// same `repos/` checkout, so forking a conversation or opening a second one
/// costs nothing on disk and neither of them can see a different tree. A
/// conversation id is never a key here — it names no worktree.
///
/// The cwd's `.mcp.json` is NOT provisioned here — cc_server derives it from
/// `mcp_config.json` at dispatch time. Implementations live in the data layer
/// (filesystem + rift). This port lets the domain `TicketDispatcher` and the
/// messaging dispatch path provision without importing infrastructure. All
/// methods are no-op-safe and never throw to the caller for provisioning
/// failures — they degrade to the fallback dir.
abstract interface class RepoWorkspaceProvisionerPort {
  /// Ensures the space's working root exists with an isolated worktree per
  /// linked repo (reusing existing ones), builds the per-agent overlay at
  /// `agents/<agentSlug>/` (AGENTS.md + .agents + repos symlinks) and returns
  /// that overlay dir as the agent's working directory. Returns [fallbackDir]
  /// when the workspace has no linked repo or provisioning fails.
  ///
  /// [agentSlug] is the dispatched agent's slugified name — the per-agent cwd is
  /// keyed by it so two agents in the same space get distinct overlays that
  /// share `repos/`. [agentConfigDir] is the agent's global dir (the symlink
  /// target source for AGENTS.md + .agents).
  ///
  /// Branch naming: when [ticketKey] or [ticketTitle] is provided the
  /// configured branch template is rendered; otherwise a default
  /// `conv/<short-space>` branch is used. Always fetches the latest base from
  /// GitHub (when a remote + token are available) before branching.
  /// When [prHeadRef] is set (e.g. `refs/pull/42/head`), the repo whose
  /// `owner/name` equals [prHeadRepoFullName] is checked out at that ref on a
  /// [prBranch] (default `pr/<number>`) instead of the default base branch — so
  /// a PR-review space's worktree IS the PR's proposed tree (checked out
  /// clean/pristine). Other repos provision normally.
  ///
  /// When [repoAllowlist] is non-null, only the workspace repos whose id is in
  /// the set are provisioned (a PR space passes just the PR's repo; a space
  /// created with an explicit repo selection passes those). Null → every linked
  /// repo, preserving pre-selection behaviour.
  ///
  /// [onRepoProvision] fires right before a repo worktree is actually
  /// materialized (reused worktrees don't fire), with the repo's display name
  /// and whether it is being checked out at a PR head — so callers can surface
  /// live provisioning progress. Must not throw.
  ///
  /// [onRepoSetupScript] fires right before a FRESHLY materialized worktree's
  /// configured setup script runs (never for reused worktrees, and only when
  /// the repo actually has a setup script) — so callers can surface "running
  /// the setup script for X" progress. Must not throw.
  ///
  /// [cancel] stops the run: the in-flight git command is killed and no further
  /// repo is materialized. The call still returns [fallbackDir] rather than
  /// throwing (same contract as any other failure) — read
  /// [isSpaceProvisioningCancelled] to tell a cancellation from a failure. The
  /// caller-supplied token is combined with the space's own registered token,
  /// so [cancelSpaceProvisioning] interrupts this call too.
  Future<String> ensureSpaceWorkspace({
    required String workspaceId,
    required String spaceId,
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
    void Function(String repoName)? onRepoSetupScript,
    CancellationToken? cancel,
  });

  /// Aborts every in-flight [ensureSpaceWorkspace] for [spaceId]: the running
  /// git command is killed and no further repo is materialized.
  ///
  /// One space can be provisioning on two paths at once — the background
  /// provisioner off `SpaceCreated` and the inline call a dispatch makes to
  /// resolve its cwd — so cancellation is registered PER SPACE here rather than
  /// held by whichever caller happened to start first. Stopping the work must
  /// stop both, or the clone the operator cancelled simply finishes on the
  /// other path.
  ///
  /// Idempotent, and a no-op when nothing is in flight. The mark is remembered
  /// so a call that starts moments later (a dispatch already past its own
  /// check) is refused too; the next [ensureSpaceWorkspace] with a
  /// fresh intent clears it.
  void cancelSpaceProvisioning(String workspaceId, String spaceId);

  /// Whether the last provisioning run for [spaceId] was cancelled rather than
  /// having failed or completed. Lets a caller report "stopped" instead of
  /// "failed" for work the operator interrupted.
  bool isSpaceProvisioningCancelled(String workspaceId, String spaceId);

  /// Clears the standing cancellation mark for [spaceId] so a deliberate
  /// re-provision (the banner's Retry) can run.
  ///
  /// Only the surface that re-provisions calls this — a stop that any passing
  /// caller could undo by asking for a working directory would not be a stop.
  void clearSpaceProvisioningCancellation(String workspaceId, String spaceId);

  /// Tears down every worktree for a space, scoped to [workspaceId].
  Future<void> releaseSpace({
    required String workspaceId,
    required String spaceId,
  });

  /// Tears down the space's worktrees whose repo is NOT in [keepRepoIds]
  /// (null → keep everything, a no-op). Driven when a space's repo selection
  /// shrinks: a deselected repo's folder leaves the space's `repos/` tree —
  /// through the ordinary destroy path, so uncommitted work is rescued
  /// rather than deleted. Worktrees for repos still selected (or provisioned
  /// lazily later) are untouched.
  Future<void> releaseSpaceReposOutside({
    required String workspaceId,
    required String spaceId,
    required Set<String>? keepRepoIds,
  });

  /// CROSS-WORKSPACE teardown by space id.
  ///
  /// NOTHING ROUTES HERE AUTOMATICALLY any more. It existed because
  /// `SpaceDeleted` carried an optional workspace and the GC listener fell
  /// back to scanning every workspace file when one was missing — a
  /// cross-workspace scan as the failure mode of an omitted argument. The
  /// event now requires its workspace, so this survives only as an explicit
  /// repair tool for a space whose workspace context is genuinely lost
  /// (a half-finished import, a registry that lost a row). If nothing calls
  /// it by the next sweep of this file, delete it — and note that the cost
  /// went up when `CrossWorkspaceQueries` moved to
  /// `WorkspaceDatabaseManager.useTransiently`: a scan now OPENS AND CLOSES
  /// every workspace file to answer one space delete.
  Future<void> releaseSpaceAnyWorkspace({required String spaceId});

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
  /// * its SPACE no longer exists. Deleting a space fires
  ///   `SpaceDeleted` → `releaseSpace`, but an event missed while the
  ///   server was down (or a row deleted straight from the database) leaves a
  ///   fully-intact worktree that nothing else will ever reclaim — along with
  ///   the code-graph partition hanging off it;
  /// * an orphan SPACE FOLDER whose space is gone: the per-agent
  ///   overlays and their token-bearing `.mcp.json` files, which linger even
  ///   after the worktree rows are reaped.
  ///
  /// Fails safe: when space existence cannot be determined the worktree is
  /// treated as live, so an unavailable lookup never destroys real work.
  Future<int> sweepStale({required String workspaceId});
}
