/// The repo-state fingerprint recorded for one checkout partition at its last
/// successful index run — the code indexer's boot-time short-circuit.
///
/// A run starts by probing the checkout (git HEAD + porcelain status + a stat
/// fold of dirty paths) and comparing against this record; a full match means
/// nothing observable changed, so the entire run (file-state read, walk,
/// hashing, prune, reference resolution) is skipped.
class CodeIndexCheckpoint {
  /// Creates a [CodeIndexCheckpoint].
  const CodeIndexCheckpoint({
    required this.workspaceId,
    required this.repoId,
    required this.checkoutId,
    required this.headSha,
    required this.worktreeDigest,
    required this.indexerFingerprint,
    required this.generation,
    required this.baseGeneration,
    required this.indexedAt,
  });

  /// Owning workspace.
  final String workspaceId;

  /// Owning repository.
  final String repoId;

  /// The checkout partition: null = the linked checkout, otherwise an
  /// `isolated_repos` row id.
  final String? checkoutId;

  /// `git rev-parse HEAD` at the last successful run ('' = unborn branch).
  final String headSha;

  /// The repo-state digest (HEAD + porcelain status + dirty-path stat fold).
  final String worktreeDigest;

  /// Fingerprint of the extractor itself (version + queries + grammars), so
  /// an extractor change invalidates every checkpoint automatically.
  final String indexerFingerprint;

  /// Bumped on every run that changed rows (indexed or pruned files).
  final int generation;

  /// For a worktree: the base partition's [generation] this delta was
  /// measured against; 0 for linked checkouts. A base re-index therefore
  /// invalidates the worktrees that indexed against the older base.
  final int baseGeneration;

  /// When the checkpoint was written.
  final DateTime indexedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeIndexCheckpoint &&
          other.workspaceId == workspaceId &&
          other.repoId == repoId &&
          other.checkoutId == checkoutId &&
          other.headSha == headSha &&
          other.worktreeDigest == worktreeDigest &&
          other.indexerFingerprint == indexerFingerprint &&
          other.generation == generation &&
          other.baseGeneration == baseGeneration &&
          other.indexedAt == indexedAt;

  @override
  int get hashCode => Object.hash(
    workspaceId,
    repoId,
    checkoutId,
    headSha,
    worktreeDigest,
    indexerFingerprint,
    generation,
    baseGeneration,
    indexedAt,
  );
}

/// A partition's own checkpoint plus the base partition's current generation,
/// read together in one query so the worktree staleness test costs nothing
/// extra.
class CodeIndexCheckpointView {
  /// Creates a [CodeIndexCheckpointView].
  const CodeIndexCheckpointView({
    required this.own,
    required this.baseGeneration,
  });

  /// The partition's own checkpoint; null when it has never completed a run.
  final CodeIndexCheckpoint? own;

  /// The base (linked-checkout) partition's current generation; 0 when the
  /// base has no checkpoint. For a linked-checkout read this is its own
  /// generation.
  final int baseGeneration;
}
