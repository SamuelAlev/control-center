import 'package:control_center/core/infrastructure/code_index/tree_sitter_loader.dart';
import 'package:control_center/core/infrastructure/code_index/tree_sitter_parser.dart';
import 'package:control_center/features/code_graph/data/extraction/code_extractor.dart';

/// Sendable parameters for [extractFileInIsolate] (all primitives, so this can
/// cross an isolate boundary).
class ExtractionRequest {
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

  final String workspaceId;
  final String repoId;
  final String filePath;
  final String source;
  final String languageId;
  final String querySource;
  final String runtimePath;
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
