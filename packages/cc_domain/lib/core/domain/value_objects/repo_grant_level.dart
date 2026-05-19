/// Per-repo access level a workspace member holds on one linked repo.
///
/// Workspace membership alone must never out-privilege the forge: the server
/// holds full checkouts, so code-bearing surfaces (files, diffs, PR review,
/// code search, code graph) check the member's grant on that repo, not just
/// membership. Owners and admins implicitly hold [write] on every linked
/// repo; everyone else defaults to [none] until granted.
enum RepoGrantLevel {
  /// No code visibility at all — the repo is invisible to this member.
  none(0),

  /// May read files, diffs, and search results.
  read(1),

  /// [read] plus participating in PR review surfaces.
  review(2),

  /// [review] plus driving agent runs that write to the repo.
  write(3);

  const RepoGrantLevel(this.rank);

  /// Privilege order: higher includes lower.
  final int rank;

  /// Whether this grant includes at least [other].
  bool atLeast(RepoGrantLevel other) => rank >= other.rank;

  /// Whether any code from the repo may be shown.
  bool get allowsRead => atLeast(RepoGrantLevel.read);

  /// The value persisted in the database and sent over the wire.
  String get wireName => name;

  /// Parses a stored/wire value; returns null for unknown values so callers
  /// decide whether to deny or default.
  static RepoGrantLevel? fromWire(String? value) {
    for (final level in RepoGrantLevel.values) {
      if (level.name == value) {
        return level;
      }
    }
    return null;
  }
}
