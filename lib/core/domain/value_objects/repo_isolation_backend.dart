/// Which mechanism produced an isolated repo copy.
enum RepoIsolationBackend {
  /// Copy-on-write clone via the bundled rift library (APFS clonefile /
  /// reflink). Fully isolated — the source repo is never mutated.
  rift,

  /// Plain `git worktree add` on the source repo. Fallback when CoW is
  /// unavailable; this DOES write worktree metadata + the new branch ref into
  /// the source `.git`, so it is used only when rift cannot be.
  gitWorktree;

  /// Parses a persisted name back to the enum, defaulting to [rift].
  static RepoIsolationBackend fromName(String? name) {
    return RepoIsolationBackend.values.firstWhere(
      (b) => b.name == name,
      orElse: () => RepoIsolationBackend.rift,
    );
  }
}
