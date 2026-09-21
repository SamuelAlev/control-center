/// Live progress emitted during [CodeIndexer.indexRepo].
class CodeIndexProgress {
  /// Creates a [CodeIndexProgress].
  const CodeIndexProgress({
    required this.filesIndexed,
    required this.filesToIndex,
    required this.totalFiles,
    required this.symbols,
    required this.edges,
  });

  /// Files indexed so far.
  final int filesIndexed;

  /// Files this run will extract: the candidates whose content hash differs
  /// from what the partition already stored (plus, for a worktree, whatever it
  /// does not inherit from the linked checkout).
  ///
  /// The denominator a progress bar wants. [totalFiles] is the size of the
  /// CHECKOUT, so an incremental run that rewrote 13 files out of 4565 reads as
  /// 0.3% complete against it for the whole run and then jumps to done.
  final int filesToIndex;

  /// Total candidate files.
  final int totalFiles;

  /// Symbols extracted so far.
  final int symbols;

  /// Edges extracted so far.
  final int edges;

  /// JSON view for the pipeline step's live output snapshot.
  Map<String, dynamic> toJson() => {
    'filesIndexed': filesIndexed,
    'filesToIndex': filesToIndex,
    'totalFiles': totalFiles,
    'symbols': symbols,
    'edges': edges,
  };
}

/// Outcome of an indexing run.
class CodeIndexResult {
  /// Creates a [CodeIndexResult].
  const CodeIndexResult({
    required this.filesIndexed,
    required this.filesSkipped,
    required this.symbols,
    required this.edges,
    required this.removedFiles,
    required this.resolvedReferences,
    required this.nativeAvailable,
    this.checkpointSkipped = false,
    this.skippedReason,
  });

  /// Indexing did not run because the tree-sitter natives are absent.
  const CodeIndexResult.skipped(this.skippedReason)
    : filesIndexed = 0,
      filesSkipped = 0,
      symbols = 0,
      edges = 0,
      removedFiles = 0,
      resolvedReferences = 0,
      checkpointSkipped = false,
      nativeAvailable = false;

  /// The run was short-circuited by a matching index checkpoint: the repo's
  /// fingerprint (git HEAD + status + dirty stats) is identical to the one
  /// recorded at the last successful run, so nothing was walked, hashed,
  /// pruned, or resolved. NOT [CodeIndexResult.skipped] — that means "broken
  /// install"; this means "everything is already current".
  const CodeIndexResult.unchanged()
    : filesIndexed = 0,
      filesSkipped = 0,
      symbols = 0,
      edges = 0,
      removedFiles = 0,
      resolvedReferences = 0,
      checkpointSkipped = true,
      nativeAvailable = true,
      skippedReason = null;

  /// Files (re)indexed this run.
  final int filesIndexed;

  /// Files skipped because their content hash was unchanged.
  final int filesSkipped;

  /// Total symbols ingested.
  final int symbols;

  /// Total edges ingested.
  final int edges;

  /// Files pruned because they no longer exist on disk.
  final int removedFiles;

  /// Cross-file references bound during the resolution pass.
  final int resolvedReferences;

  /// Whether the tree-sitter natives were available (false → nothing indexed).
  final bool nativeAvailable;

  /// Whether the run was short-circuited by a matching index checkpoint.
  final bool checkpointSkipped;

  /// Why indexing was skipped, when [nativeAvailable] is false.
  final String? skippedReason;

  /// JSON view for pipeline state / logs.
  Map<String, dynamic> toJson() => {
    'filesIndexed': filesIndexed,
    'filesSkipped': filesSkipped,
    'symbols': symbols,
    'edges': edges,
    'removedFiles': removedFiles,
    'resolvedReferences': resolvedReferences,
    'nativeAvailable': nativeAvailable,
    'checkpointSkipped': checkpointSkipped,
    if (skippedReason != null) 'skippedReason': skippedReason,
  };
}

/// Background code indexer for a repository. Domain abstraction so callers
/// (e.g. the `index_code` pipeline body) depend on the interface, not the
/// data-layer implementation. Implemented by `DefaultCodeIndexer`.
abstract class CodeIndexer {
  /// Walks [repoPath], extracts symbols/edges for changed files, ingests into
  /// the code graph, prunes deleted files, and resolves cross-file references.
  /// Returns skipped when no language's tree-sitter natives are installed.
  /// Graph is scoped to [workspaceId] (same [repoId] in two workspaces → two
  /// graphs).
  /// [checkoutId] null → linked checkout partition (`index_code` default);
  /// an `isolated_repos` id → that worktree's partition (PR review must not
  /// clobber the linked checkout).
  /// [force] bypasses the checkpoint short-circuit (watcher events that know
  /// a file changed); boot/arm leaves it false.
  /// [changedPaths] non-null → targeted pass (stat/hash/prune only those
  /// repo-relative paths). Must be complete since last run or omitted paths
  /// stay stale; null or empty → full pass.
  Future<CodeIndexResult> indexRepo({
    required String workspaceId,
    required String repoId,
    required String repoPath,
    String? checkoutId,
    bool force = false,
    List<String>? changedPaths,
    void Function(CodeIndexProgress progress)? onProgress,
    bool Function()? isCancelled,
  });
}
