import 'package:cc_infra/src/code_graph/code_extractor.dart';
import 'package:cc_natives/cc_natives.dart';

/// Sendable parameters for [extractFileInIsolate] (all primitives, so this can
/// cross an isolate boundary).
class ExtractionRequest {
  /// Parameters for isolate extraction.
  const ExtractionRequest({
    required this.workspaceId,
    required this.repoId,
    this.checkoutId,
    required this.filePath,
    required this.source,
    required this.languageId,
    required this.querySource,
    required this.runtimePath,
    required this.grammarPath,
  });

  /// Owning workspace identifier.
  final String workspaceId;

  /// Owning repository identifier.
  final String repoId;

  /// Checkout partition (null = linked checkout, otherwise an
  /// `isolated_repos` row id).
  final String? checkoutId;

  /// Source file path.
  final String filePath;

  /// Source file contents.
  final String source;

  /// Language identifier (e.g. "dart", "python").
  final String languageId;

  /// Tree-sitter query source for the language.
  final String querySource;

  /// Path to the tree-sitter runtime library.
  final String runtimePath;

  /// Path to the tree-sitter grammar library.
  final String grammarPath;
}

/// Isolate entry point: builds a tree-sitter loader/parser from the supplied
/// library paths (FFI handles can't cross isolates, so they're created here)
/// and extracts one file. Runs via `Isolate.run`, keeping CPU-bound parsing
/// off the UI isolate. Throws `TreeSitterUnavailable` (propagated across the
/// isolate boundary) if the natives can't load — the indexer fails the run
/// rather than silently extracting nothing.
ExtractionResult extractFileInIsolate(ExtractionRequest req) {
  final loader = TreeSitterLoader(
    runtimePath: req.runtimePath,
    grammarPaths: {req.languageId: req.grammarPath},
  );
  final parser = TreeSitterParser(loader);
  try {
    return const CodeExtractor().extract(
      workspaceId: req.workspaceId,
      repoId: req.repoId,
      checkoutId: req.checkoutId,
      filePath: req.filePath,
      source: req.source,
      languageId: req.languageId,
      querySource: req.querySource,
      parser: parser,
    );
  } finally {
    parser.dispose();
  }
}
