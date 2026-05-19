import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';

/// Lazily materializes a pull request's branch into a local copy-on-write
/// worktree (rift, falling back to a plain `git worktree`) so it can be opened
/// in an external editor — and tears it down when the PR is merged or closed.
///
/// Worktrees are created on demand (on click), never pre-cloned, to keep disk
/// usage flat. Each lives under `<workspace>/<workspaceId>/pr_worktrees/`.
abstract interface class PrWorktreePort {
  /// Ensures a worktree of [repo] checked out at PR #[prNumber]'s head exists,
  /// returning its absolute path. Idempotent: an existing, on-disk worktree for
  /// the same PR is reused rather than re-created.
  ///
  /// The worktree is checked out onto a branch named [prHeadRef] (the PR's own
  /// head branch) pointing at the PR's head commits — so it reads as the PR's
  /// branch, not a synthetic one. Falls back to `pr-<number>` when [prHeadRef]
  /// is empty.
  ///
  /// Throws [PrWorktreeException] when the repo has no GitHub remote/token or
  /// the fetch/checkout fails.
  Future<String> ensureWorktree({
    required String workspaceId,
    required Repo repo,
    required int prNumber,
    required String prHeadRef,
  });

  /// Removes the worktree for the PR identified by [repoFullName] (`owner/repo`)
  /// and [prNumber], across all workspaces, and forgets it. No-op when none
  /// exists. Invoked by the GC listener on PR merge/close.
  Future<void> release({
    required String repoFullName,
    required int prNumber,
  });
}
