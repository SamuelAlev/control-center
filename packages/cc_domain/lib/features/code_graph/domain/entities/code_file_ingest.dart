import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';

/// One parsed file queued for batched ingestion into the code graph.
///
/// The indexer accumulates these and flushes a batch through
/// `CodeGraphRepository.ingestFiles`, which embeds every symbol in one
/// round-trip and writes the whole batch in ONE transaction — instead of the
/// former four auto-committed statements per file.
class CodeFileIngest {
  /// Creates a [CodeFileIngest].
  const CodeFileIngest({
    required this.workspaceId,
    required this.repoId,
    required this.checkoutId,
    required this.filePath,
    required this.contentHash,
    required this.symbols,
    required this.edges,
    this.language = 'dart',
  });

  /// Owning workspace.
  final String workspaceId;

  /// Owning repository.
  final String repoId;

  /// The checkout partition (null = linked checkout).
  final String? checkoutId;

  /// Repo-relative file path.
  final String filePath;

  /// SHA-256 of the file content this parse saw.
  final String contentHash;

  /// Symbols extracted from the file.
  final List<CodeSymbol> symbols;

  /// Edges extracted from the file.
  final List<CodeEdge> edges;

  /// Source language id.
  final String language;
}
