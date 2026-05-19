/// Captures and restores the working-tree state of a git worktree, so a
/// conversation revert can roll back filesystem changes — not just the
/// transcript. Refs are opaque to the domain (the adapter decides whether they
/// are tree hashes, commits, or stashes).
abstract interface class GitSnapshotPort {
  /// Captures the current working-tree state of [worktreePath] and returns an
  /// opaque ref, or null when the path is not a git worktree or capture failed.
  Future<String?> capture(String worktreePath);

  /// Restores [worktreePath]'s working tree to a previously [capture]d [ref].
  /// Throws on failure (caller decides whether to surface or swallow).
  Future<void> restore(String worktreePath, String ref);
}
