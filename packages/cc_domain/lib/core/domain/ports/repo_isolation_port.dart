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

  /// Creates an isolated worktree of [sourcePath] under [name], checks out
  /// [branch].
  ///
  /// Rift: register → CoW → fetch base into FETCH_HEAD → `checkout -B`. Empty
  /// [baseRef] from `origin/HEAD` then main/master — never source HEAD.
  /// [authUrl] or copy's origin; [headRef] fetches that ref as [branch].
  /// Rift failures throw (no worktree rescue on CoW). [pristine] → clean -ffdx.
  /// [cancel] → [CancelledException]; disk leftover is caller's to reap.
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
  /// and deletes [branch] plus every name in [branches] from the source.
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
    List<String> branches = const [],
  });
}
