part of 'repo_ide_data_service.dart';

/// The worktree reads [RepoIdeDataService] coalesces, and the mutations that
/// fence them.
///
/// The Source Control poll re-reads a tree every few seconds, and on a large
/// checkout one read can outlast both that interval and the session's request
/// budget. Concurrent identical reads therefore share one capture, and every
/// mutation is a generation boundary so a read issued after it never joins a
/// capture taken before (or during) it. The bodies live on the service as the
/// private `_name` methods declared at the end.
mixin _WorktreeChangeGate {
  /// Bumped when a worktree mutation (stage, revert, commit, checkout, …)
  /// starts and again when it ends. A change read only joins an in-flight
  /// read of the same generation, so the read a client issues right after its
  /// own stage never returns a capture taken before (or during) that stage.
  int _mutationGeneration = 0;

  Future<T> _mutating<T>(Future<T> Function() mutation) async {
    _mutationGeneration++;
    try {
      return await mutation();
    } finally {
      _mutationGeneration++;
    }
  }

  /// Change reads still running, by `(workspace, repo, space, generation)`.
  /// A large tree's capture can outlast the client's poll interval and the session's request
  /// budget (which answers the client but leaves the handler running), so
  /// each tick used to start one more whole-tree git capture beside the ones
  /// already going — until the session's in-flight slots were all held by
  /// them and every other request was refused. Concurrent identical reads now
  /// share one capture. Keyed by workspace too, so one workspace never
  /// receives another's result.
  final _changesInFlight =
      <(String, String, String?, int), Future<List<PrFile>>>{};
  final _groupedInFlight =
      <(String, String, String?, int), Future<RepoChangeGroups>>{};

  /// Working-tree diff vs HEAD (incl. untracked) for Source Control.
  ///
  /// With [spaceId]: only the conversation's CoW worktree — never fall back to the linked checkout
  /// (that would disagree with what commit stages). Missing worktree → empty. Without [spaceId]: linked checkout.
  /// Unlinked repo → empty.
  Future<List<PrFile>> repoChanges(
    String workspaceId,
    String repoId, {
    String? spaceId,
  }) {
    final key = (workspaceId, repoId, spaceId, _mutationGeneration);
    return _changesInFlight[key] ??=
        _repoChanges(workspaceId, repoId, spaceId: spaceId).whenComplete(() {
          // A block, not `=> remove(key)`: remove returns this very future, and
          // whenComplete would wait on it — the read would never complete.
          _changesInFlight.remove(key);
        });
  }

  /// The worktree's changes split into staged (index vs HEAD) and unstaged
  /// (worktree vs index + untracked) buckets — the VS Code Source Control model.
  /// Same workspace/space scoping as [repoChanges]; empty buckets when the
  /// space has no worktree for [repoId].
  ///
  /// Also reports how the branch sits against its upstream from local refs:
  /// ahead is commits to push, behind is commits to pull. A worktree branch
  /// with an upstream is fetched in the background at most once per
  /// [RepoIdeDataService._autoFetchInterval] (VS Code's autofetch), so
  /// commits pushed elsewhere reach behind on a later poll; this call never waits on the network. A branch
  /// with no tracking ref and no `origin/<branch>` is still published when an
  /// open pull request names it — the head commit from that snapshot stands
  /// in for the missing remote-tracking ref, so a pull request opened outside
  /// this worktree is not offered as "Publish branch". With neither, ahead is
  /// commits the remote default does not contain, so a local conversation
  /// commit is still visible.
  Future<RepoChangeGroups> repoChangesGrouped(
    String workspaceId,
    String repoId, {
    String? spaceId,
  }) {
    final key = (workspaceId, repoId, spaceId, _mutationGeneration);
    return _groupedInFlight[key] ??=
        _repoChangesGrouped(
          workspaceId,
          repoId,
          spaceId: spaceId,
        ).whenComplete(() {
          // A block, not `=> remove(key)`: remove returns this very future, and
          // whenComplete would wait on it — the read would never complete.
          _groupedInFlight.remove(key);
        });
  }

  /// Stages [paths] (empty ⇒ all changes) into the git index of the
  /// conversation's isolated worktree for [repoId] via `git add`. Paths are
  /// confined to the worktree root. Returns false when the space has no
  /// worktree for [repoId].
  Future<bool> stageFiles(
    String workspaceId,
    String spaceId,
    String repoId,
    List<String> paths,
  ) => _mutating(() => _stageFiles(workspaceId, spaceId, repoId, paths));

  /// Unstages [paths] (empty ⇒ all) from the git index of the conversation's
  /// isolated worktree for [repoId] via `git reset HEAD`. The working-tree
  /// content is untouched — only the index entry reverts. Returns false when the
  /// space has no worktree for [repoId].
  Future<bool> unstageFiles(
    String workspaceId,
    String spaceId,
    String repoId,
    List<String> paths,
  ) => _mutating(() => _unstageFiles(workspaceId, spaceId, repoId, paths));

  /// Writes a draft file into the conversation's isolated copy-on-write
  /// worktree. Backs the IDE's "untitled" draft save (⌘S). The worktree is
  /// resolved through [IsolatedRepoRepository.forSpace] (the worktree
  /// isolation boundary), so a space the caller's workspace does not own is
  /// simply not found — no cross-workspace leak. The [path] is confined to the
  /// worktree root (rejecting `..`/absolute escapes) and the payload is capped
  /// at [RepoIdeDataService._writeMaxBytes]. Returns the resolved path, or
  /// null when the space has no worktree for [repoId] / the path escapes / the payload is too big.
  Future<WorktreeWriteResult?> writeFile(
    String workspaceId,
    String spaceId,
    String repoId,
    String path,
    String content,
  ) => _mutating(() => _writeFile(workspaceId, spaceId, repoId, path, content));

  /// Reverts one or more working-tree files in the conversation's isolated
  /// worktree to HEAD via `git checkout-index -f` (matches the snapshot-restore
  /// path in `ProcessGitSnapshotAdapter`). Tracked modified/deleted files are
  /// restored; untracked/new files are skipped (`checkout-index` cannot remove
  /// them — the client surfaces them as `skipped`). Paths outside the worktree
  /// root are rejected. Returns null when the space has no worktree for
  /// [repoId].
  Future<WorktreeRevertResult?> revertFiles(
    String workspaceId,
    String spaceId,
    String repoId,
    List<String> paths,
  ) => _mutating(() => _revertFiles(workspaceId, spaceId, repoId, paths));

  /// Stage/commit/(optional) push in the conversation worktree. Token via `GIT_CONFIG_PARAMETERS` (not argv).
  /// Push authenticates as [actingUserId]; commit authored by [authorName]/[authorEmail] or Control Center.
  /// [amend] rewrites HEAD; [sync] fetch+rebase before push (conflict returns git error).
  Future<Map<String, dynamic>?> commitAndPush({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    required String message,
    List<String> paths = const [],
    bool push = true,
    bool amend = false,
    bool sync = false,
    String? pushBranch,
    String? authorName,
    String? authorEmail,
    String? actingUserId,
  }) => _mutating(
    () => _commitAndPush(
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: repoId,
      message: message,
      paths: paths,
      push: push,
      amend: amend,
      sync: sync,
      pushBranch: pushBranch,
      authorName: authorName,
      authorEmail: authorEmail,
      actingUserId: actingUserId,
    ),
  );

  /// Push-only publish of the conversation worktree branch to `origin` (needed before forge PR creation).
  /// Never stages/commits/amends/rebases; token via `GIT_CONFIG_PARAMETERS`. Null if no worktree.
  Future<Map<String, dynamic>?> publishBranch({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    String? branchOverride,
    String? actingUserId,
  }) => _mutating(
    () => _publishBranch(
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: repoId,
      branchOverride: branchOverride,
      actingUserId: actingUserId,
    ),
  );

  /// VS Code's Sync for the conversation worktree: fetch the branch, rebase when
  /// the remote has commits this side does not, then push when this side is
  /// ahead or the branch has never been published. Never commits.
  ///
  /// A dirty tree that still needs the rebase is refused (`dirty: true`) so
  /// uncommitted edits are not clobbered. A rebase conflict aborts and returns
  /// git's message. A rejected push — branch protection, a pre-push or
  /// pre-receive hook, a non-fast-forward — returns `pushRefused: true` with
  /// the hook or remote's own text, and does not report the sync as done. A
  /// pull that already landed stays landed. Null when the space has no
  /// worktree for [repoId].
  Future<Map<String, dynamic>?> syncBranch({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    String? actingUserId,
  }) => _mutating(
    () => _syncBranch(
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: repoId,
      actingUserId: actingUserId,
    ),
  );

  /// Checks [branch] out in the conversation worktree, or creates it.
  ///
  /// Stays inside the isolated copy: local refs and remote-tracking refs
  /// already in the worktree, never a fetch and never a write into the
  /// source checkout. A dirty tree is left for git to accept or refuse —
  /// creating a branch at HEAD keeps uncommitted work, switching to another
  /// commit does not overwrite files.
  ///
  /// On success the isolated-repo row's branch is updated to the checked-out
  /// name, because commit and push publish that stored name. A detached
  /// checkout stores an empty branch so a later push cannot invent
  /// `refs/heads/HEAD`. If recording the row fails, the checkout is rolled
  /// back. Null when the space has no worktree for [repoId].
  Future<Map<String, dynamic>?> checkoutBranch({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    String? branch,
    String? startPoint,
    bool create = false,
    bool detach = false,
  }) => _mutating(
    () => _checkoutBranch(
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: repoId,
      branch: branch,
      startPoint: startPoint,
      create: create,
      detach: detach,
    ),
  );

  /// Re-syncs the conversation worktree for [repoId] to the current PR head.
  ///
  /// A PR-review worktree is checked out at the PR head **when it is
  /// provisioned** and never moves after that — so commits pushed to the PR
  /// later don't show up. This re-fetches [headRef] (e.g. `refs/pull/42/head`)
  /// and, when the worktree is CLEAN, hard-resets it to those commits ([branch]
  /// recreated at `FETCH_HEAD`) then scrubs untracked cruft (`git clean -ffdx`),
  /// so the review tree tracks the latest PR commits.
  ///
  /// When the worktree is DIRTY it no-ops and returns `{dirty: true}` — it never
  /// clobbers uncommitted edits; the client asks the user to commit/discard
  /// first. Returns null when the space has no worktree for [repoId]; a map
  /// with `ok:false` + `error` on fetch/checkout failure.
  Future<Map<String, dynamic>?> syncToPrHead(
    String workspaceId,
    String spaceId,
    String repoId, {
    required String headRef,
    required String branch,
  }) => _mutating(
    () => _syncToPrHead(
      workspaceId,
      spaceId,
      repoId,
      headRef: headRef,
      branch: branch,
    ),
  );

  // Implemented by [RepoIdeDataService].

  Future<List<PrFile>> _repoChanges(
    String workspaceId,
    String repoId, {
    String? spaceId,
  });

  Future<RepoChangeGroups> _repoChangesGrouped(
    String workspaceId,
    String repoId, {
    String? spaceId,
  });

  Future<bool> _stageFiles(
    String workspaceId,
    String spaceId,
    String repoId,
    List<String> paths,
  );

  Future<bool> _unstageFiles(
    String workspaceId,
    String spaceId,
    String repoId,
    List<String> paths,
  );

  Future<WorktreeWriteResult?> _writeFile(
    String workspaceId,
    String spaceId,
    String repoId,
    String path,
    String content,
  );

  Future<WorktreeRevertResult?> _revertFiles(
    String workspaceId,
    String spaceId,
    String repoId,
    List<String> paths,
  );

  Future<Map<String, dynamic>?> _commitAndPush({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    required String message,
    List<String> paths = const [],
    bool push = true,
    bool amend = false,
    bool sync = false,
    String? pushBranch,
    String? authorName,
    String? authorEmail,
    String? actingUserId,
  });

  Future<Map<String, dynamic>?> _publishBranch({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    String? branchOverride,
    String? actingUserId,
  });

  Future<Map<String, dynamic>?> _syncBranch({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    String? actingUserId,
  });

  Future<Map<String, dynamic>?> _checkoutBranch({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    String? branch,
    String? startPoint,
    bool create = false,
    bool detach = false,
  });

  Future<Map<String, dynamic>?> _syncToPrHead(
    String workspaceId,
    String spaceId,
    String repoId, {
    required String headRef,
    required String branch,
  });
}
