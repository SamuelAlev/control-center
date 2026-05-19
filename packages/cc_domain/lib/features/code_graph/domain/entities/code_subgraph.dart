import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:collection/collection.dart';

/// Result of an impact-radius traversal: the reachable symbols (including the
/// [root] at depth 0), the edges among them, and each symbol's BFS depth.
class CodeSubgraph {
  /// Creates a [CodeSubgraph].
  const CodeSubgraph({
    required this.root,
    required this.nodes,
    required this.edges,
    required this.depthById,
  });

  /// Empty subgraph (root symbol not found / no reachable nodes).
  const CodeSubgraph.empty()
    : root = null,
      nodes = const [],
      edges = const [],
      depthById = const {};

  /// The symbol the traversal started from (depth 0), or null if not found.
  final CodeSymbol? root;

  /// All reachable symbols, including [root].
  final List<CodeSymbol> nodes;

  /// Edges whose endpoints are both within [nodes].
  final List<CodeEdge> edges;

  /// Map of symbol id → shortest BFS depth from [root] (root = 0).
  final Map<String, int> depthById;

  /// Whether the subgraph contains no nodes.
  bool get isEmpty => nodes.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeSubgraph &&
          runtimeType == other.runtimeType &&
          root == other.root &&
          const ListEquality<CodeSymbol>().equals(nodes, other.nodes) &&
          const ListEquality<CodeEdge>().equals(edges, other.edges) &&
          const MapEquality<String, int>().equals(depthById, other.depthById);

  @override
  int get hashCode => Object.hash(
    root,
    Object.hashAll(nodes),
    Object.hashAll(edges),
    Object.hashAllUnordered(depthById.keys),
  );
}
