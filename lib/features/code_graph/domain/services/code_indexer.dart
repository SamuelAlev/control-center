/// Live progress emitted during [CodeIndexer.indexRepo].
class CodeIndexProgress {
  /// Creates a [CodeIndexProgress].
  const CodeIndexProgress({
    required this.filesIndexed,
    required this.totalFiles,
    required this.symbols,
    required this.edges,
  });

  /// Files indexed so far.
  final int filesIndexed;

  /// Total candidate files.
  final int totalFiles;

  /// Symbols extracted so far.
  final int symbols;

  /// Edges extracted so far.
  final int edges;
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
      nativeAvailable = false;

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
  Future<CodeIndexResult> indexRepo({
    required String workspaceId,
    required String repoId,
    required String repoPath,
    void Function(CodeIndexProgress progress)? onProgress,
    bool Function()? isCancelled,
  });
}
