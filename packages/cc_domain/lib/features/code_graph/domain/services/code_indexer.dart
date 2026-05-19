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
  /// Walks [repoPath], detects each file's language by extension, extracts
  /// symbols/edges for changed files (per language), ingests them into the
  /// code graph, prunes deleted files, and resolves cross-file references.
  /// Degrades gracefully (returns a skipped result) when no language's
  /// tree-sitter natives are installed.
  ///
  /// The resulting graph is scoped to [workspaceId]: the same [repoId] indexed
  /// in two workspaces (distinct worktrees) yields two isolated graphs.
  ///
  /// [checkoutId] selects the checkout partition within the workspace's graph:
  /// null (the default, what `index_code` uses) writes the linked checkout's
  /// partition; an `isolated_repos` row id writes that conversation/PR
  /// worktree's own partition, so reviewing a PR never clobbers the linked
  /// checkout's symbols.
  ///
  /// [force] bypasses the checkpoint short-circuit: a caller that KNOWS a file
  /// changed (a watcher event) must not let a fingerprint collision skip the
  /// run. The boot/arm path leaves it false — that is exactly the path the
  /// checkpoint exists to make cheap.
  Future<CodeIndexResult> indexRepo({
    required String workspaceId,
    required String repoId,
    required String repoPath,
    String? checkoutId,
    bool force = false,
    void Function(CodeIndexProgress progress)? onProgress,
    bool Function()? isCancelled,
  });
}
