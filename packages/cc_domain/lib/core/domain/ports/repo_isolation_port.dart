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
  /// fetch [baseRef] from [authUrl] (when non-null; token passed transiently,
  /// never written to git config) → `git checkout -b [branch]` off the fetched
  /// base. When [baseRef] is empty the source's default branch is auto-detected
  /// read-only.
  ///
  /// When [headRef] is non-null (e.g. `refs/pull/42/head`), that ref is fetched
  /// from [authUrl] and checked out as [branch] instead — landing the worktree
  /// on those exact commits rather than a fresh branch off the base. Used by
  /// the "open PR in editor" flow; [authUrl] is then required.
  ///
  /// On `cow_unavailable` (or the native lib being absent) it falls back to
  /// `git worktree add` on the source. On `unsafe_git` it rethrows (the source
  /// is mid-operation; a worktree would fail too).
  Future<RepoIsolationResult> provision({
    required String sourcePath,
    required String destParentDir,
    required String name,
    required String branch,
    String baseRef = '',
    String? authUrl,
    String? headRef,
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
