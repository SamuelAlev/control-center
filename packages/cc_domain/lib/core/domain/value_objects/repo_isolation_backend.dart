/// Which mechanism produced an isolated repo copy.
enum RepoIsolationBackend {
  /// Copy-on-write clone via the bundled rift library (APFS clonefile /
  /// reflink). Fully isolated — the source repo is never mutated.
  rift,

  /// Plain `git worktree add` on the source repo. This DOES write worktree
  /// metadata and the new branch ref into the source `.git`, so it is only ever
  /// provisioned on a platform with no CoW backend at all (Windows). Elsewhere
  /// a CoW failure fails the provision instead of degrading to this — but the
  /// value still appears on persisted rows minted before that rule, whose
  /// teardown is what removes that state from the checkout.
  gitWorktree;

  /// Parses a persisted name back to the enum, defaulting to [rift].
  static RepoIsolationBackend fromName(String? name) {
    return RepoIsolationBackend.values.firstWhere(
      (b) => b.name == name,
      orElse: () => RepoIsolationBackend.rift,
    );
  }
}
