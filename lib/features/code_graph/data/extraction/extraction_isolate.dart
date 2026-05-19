import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/features/code_graph/data/extraction/code_extractor.dart';

/// Sendable parameters for [extractFileInIsolate] (all primitives, so this can
/// cross an isolate boundary).
class ExtractionRequest {
  /// Parameters for isolate extraction.
  const ExtractionRequest({
    required this.workspaceId,
    required this.repoId,
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
/// off the UI isolate. Returns an empty result if the natives can't load.
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
      filePath: req.filePath,
      source: req.source,
      languageId: req.languageId,
      querySource: req.querySource,
      parser: parser,
    );
  } on TreeSitterUnavailable {
    return const ExtractionResult.empty();
  } finally {
    parser.dispose();
  }
}
