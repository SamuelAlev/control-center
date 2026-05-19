/// Creates a fresh git worktree for a forked conversation to explore an
/// alternative approach in isolation. Implemented by the worktree/rift
/// infrastructure; the fork service only needs the resulting directory.
abstract interface class WorktreeForkPort {
  /// Creates a new worktree derived from [sourceRepoPath] for a fork named
  /// [forkName], returning the absolute path of the new working directory.
  Future<String> createForkWorktree({
    required String sourceRepoPath,
    required String forkName,
  });
}
