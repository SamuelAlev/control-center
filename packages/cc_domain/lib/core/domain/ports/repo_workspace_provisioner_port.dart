import 'package:cc_harness/cancellation.dart';

/// Provisions a per-space working root with isolated CoW worktrees and tears
/// them down on unit completion.
///
/// Layout: `spaces/<spaceId>/repos/<repo>/` (shared CoW worktrees) and
/// `agents/<agentSlug>/` (returned cwd: AGENTS.md + `.agents` + `repos`
/// symlinks). Every conversation in a space shares `repos/`; a conversation
/// id is never a worktree key. `.mcp.json` is not provisioned here —
/// cc_server derives it at dispatch. No-op-safe: provisioning failures
/// degrade to the fallback dir rather than throwing.
abstract interface class RepoWorkspaceProvisionerPort {
  /// Ensures space root + isolated worktrees + per-agent overlay at
  /// `agents/<agentSlug>/`; returns that cwd or [fallbackDir] on failure.
  ///
  /// [agentSlug] keys the overlay; [agentConfigDir] targets AGENTS.md+`.agents`.
  /// Branch from [ticketKey]/[ticketTitle] else `conv/<short-space>`; fetches
  /// latest base when remote+token available. [prHeadRef] checks out that ref
  /// on [prBranch] for [prHeadRepoFullName], pristine. [repoAllowlist] null →
  /// all linked repos. [onRepoProvision]/[onRepoSetupScript] fire on fresh
  /// materialize only; must not throw. [cancel] kills git and stops; still
  /// returns [fallbackDir] — use [isSpaceProvisioningCancelled].
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
  /// Not routed automatically. Survives only as an explicit repair tool when
  /// a space's workspace context is genuinely lost (half-finished import,
  /// missing registry row). `SpaceDeleted` now requires its workspace, so the
  /// old scan-on-missing-workspace path is gone. A scan now opens and closes
  /// every workspace file via `CrossWorkspaceQueries` /
  /// `WorkspaceDatabaseManager.useTransiently` — delete if unused.
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

  /// Sweeps stale isolated worktrees in [workspaceId]; returns count reaped.
  /// Safe to call repeatedly; healthy in-use worktrees are untouched.
  ///
  /// Reaped when: the on-disk copy has vanished; the SPACE no longer exists
  /// (missed `SpaceDeleted` / direct DB delete — also drops the hanging
  /// code-graph partition); or an orphan space folder remains after worktree
  /// rows were reaped (overlays + token-bearing `.mcp.json`). Fails safe:
  /// if space existence cannot be determined, the worktree is treated as live.
  Future<int> sweepStale({required String workspaceId});
}
