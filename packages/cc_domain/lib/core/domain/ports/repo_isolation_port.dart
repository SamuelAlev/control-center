import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';

/// The outcome of provisioning an isolated worktree: where it landed and how.
class RepoIsolationResult {
  /// Creates a [RepoIsolationResult].
  const RepoIsolationResult({required this.path, required this.backend});

  /// Absolute path to the provisioned worktree.
  final String path;

  /// Which backend produced it.
  final RepoIsolationBackend backend;
}

/// Provisions and tears down isolated, copy-on-write worktrees of a local repo.
///
/// Invariant: the original repo is never mutated. The CoW copy is created
/// first, then `git fetch` + branch happen INSIDE the copy. The git-worktree
/// fallback is the one exception (it writes into the source `.git`) and is used
/// only when CoW is unavailable.
abstract interface class RepoIsolationPort {
  /// True when the native CoW backend is loadable. When false, [provision]
  /// uses the git-worktree fallback.
  bool get isCowAvailable;

  /// Creates an isolated worktree of [sourcePath] inside [destParentDir] under
  /// directory [name], then checks out [branch].
  ///
  /// Sequence (rift path): ensure the source is rift-registered → CoW create →
  /// fetch the latest default branch into FETCH_HEAD (never
  /// `refs/remotes/origin/*`) → `git checkout -B [branch]` at that commit.
  /// [baseRef] names the default branch; when empty it is auto-detected
  /// read-only from `origin/HEAD`, then `origin/main` / `origin/master` —
  /// never the source's currently checked-out branch. The fetch URL is
  /// [authUrl] (token passed transiently, never written to git config) or,
  /// if that is empty, the copy's `origin` remote URL.
  ///
  /// When [headRef] is non-null (e.g. `refs/pull/42/head`), that ref is fetched
  /// from [authUrl] and checked out as [branch] instead — landing the worktree
  /// on those exact commits rather than a fresh branch off the base. Used by
  /// the "open PR in editor" flow; [authUrl] is then required.
  ///
  /// On `cow_unavailable` (or the native lib being absent) it falls back to
  /// `git worktree add` on the source. On `unsafe_git` it rethrows (the source
  /// is mid-operation; a worktree would fail too).
  ///
  /// When [pristine] is true, the working tree is scrubbed to exactly the
  /// checked-out ref after checkout (`git clean -ffdx`) — the CoW copy inherits
  /// every inode of the source working dir (untracked/ignored/dirty files), and
  /// `git checkout` only resets *tracked* files, so without this a PR-review
  /// worktree would carry the source checkout's local cruft (`.bak`, private
  /// config, stale build output). Reserved for review surfaces that must show the
  /// ref's tree verbatim; agent/ticket worktrees keep [pristine] false so their
  /// dependencies and untracked scratch survive.
  Future<RepoIsolationResult> provision({
    required String sourcePath,
    required String destParentDir,
    required String name,
    required String branch,
    String baseRef = '',
    String? authUrl,
    String? headRef,
    bool pristine = false,
  });

  /// Destroys a previously provisioned worktree. For the rift backend this
  /// trashes + gc's the copy; for the worktree backend it removes the worktree
  /// and deletes [branch] from the source.
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  });
}
