import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_harness/cancellation.dart';

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
/// first, then `git fetch` + branch happen INSIDE the copy. Where CoW is
/// unavailable the provision FAILS rather than degrading — `git worktree add`
/// writes the branch, the worktree registration and FETCH_HEAD into the user's
/// own checkout, so it is a backend only on the one platform that ships no CoW
/// at all (Windows), never a rescue for a CoW failure elsewhere.
abstract interface class RepoIsolationPort {
  /// True when the native CoW backend is loadable. False means [provision]
  /// throws, except on a platform with no CoW backend at all.
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
  /// `cow_unavailable`, `unsafe_git`, a missing native and every other rift
  /// failure THROW. There is no `git worktree` rescue on a platform that ships
  /// CoW: that backend mutates the source repo, and a provision that quietly
  /// pollutes the operator's checkout is worse than one that fails.
  ///
  /// When [pristine] is true, the working tree is scrubbed to exactly the
  /// checked-out ref after checkout (`git clean -ffdx`) — the CoW copy inherits
  /// every inode of the source working dir (untracked/ignored/dirty files) and
  /// `git checkout` only resets *tracked* files, so without this a PR-review
  /// worktree would carry the source checkout's local cruft (`.bak`, private
  /// config, stale build output). Reserved for review surfaces that must show the
  /// ref's tree verbatim; agent/ticket worktrees keep [pristine] false so their
  /// dependencies and untracked scratch survive.
  ///
  /// [cancel] aborts the provision: the in-flight git command is killed and a
  /// [CancelledException] is thrown, rather than a fetch running to completion
  /// for a caller that already stopped. Whatever landed on disk before the
  /// abort is the caller's to reap.
  Future<RepoIsolationResult> provision({
    required String sourcePath,
    required String destParentDir,
    required String name,
    required String branch,
    String baseRef = '',
    String? authUrl,
    String? headRef,
    bool pristine = false,
    CancellationToken? cancel,
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
