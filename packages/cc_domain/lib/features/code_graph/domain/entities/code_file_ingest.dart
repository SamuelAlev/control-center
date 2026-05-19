import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:collection/collection.dart';

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeFileIngest &&
          runtimeType == other.runtimeType &&
          workspaceId == other.workspaceId &&
          repoId == other.repoId &&
          checkoutId == other.checkoutId &&
          filePath == other.filePath &&
          contentHash == other.contentHash &&
          language == other.language &&
          const ListEquality<CodeSymbol>().equals(symbols, other.symbols) &&
          const ListEquality<CodeEdge>().equals(edges, other.edges);

  @override
  int get hashCode => Object.hash(
    workspaceId,
    repoId,
    checkoutId,
    filePath,
    contentHash,
    language,
    const ListEquality<CodeSymbol>().hash(symbols),
    const ListEquality<CodeEdge>().hash(edges),
  );
}
