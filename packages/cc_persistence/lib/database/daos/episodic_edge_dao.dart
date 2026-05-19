import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/episodic_edges.dart';
import 'package:drift/drift.dart';

part 'episodic_edge_dao.g.dart';

/// A fact reached by graph traversal, with the hop depth and edge weight that
/// led to it.
class RelatedFactHop {
  /// Creates a [RelatedFactHop].
  const RelatedFactHop({
    required this.factId,
    required this.depth,
    required this.weight,
    required this.edgeType,
  });

  /// The reached fact id.
  final String factId;
  /// Hop distance from the seed (1 = direct neighbor).
  final int depth;
  /// Weight of the edge traversed to reach it.
  final double weight;
  /// Type of the edge traversed.
  final String edgeType;
}

@DriftAccessor(tables: [EpisodicEdgesTable])
/// Data access for episodic edges (workspace-scoped semantic graph).
class EpisodicEdgeDao extends DatabaseAccessor<AppDatabase>
    with _$EpisodicEdgeDaoMixin {
  /// Creates an [EpisodicEdgeDao].
  EpisodicEdgeDao(super.attachedDatabase);

  /// Inserts or updates an edge (keyed on the `(workspace, source, target,
  /// type)` unique index).
  Future<void> upsert(EpisodicEdgesTableCompanion entry) =>
      into(episodicEdgesTable).insertOnConflictUpdate(entry);

  /// All edges in a workspace.
  Future<List<EpisodicEdgesTableData>> getByWorkspace(String workspaceId) =>
      (select(episodicEdgesTable)
            ..where((t) => t.workspaceId.equals(workspaceId)))
          .get();

  /// Direct neighbors of [factId] (edges in either direction) at/above
  /// [minWeight], optionally filtered to [edgeType], heaviest first.
  Future<List<EpisodicEdgesTableData>> neighbors(
    String workspaceId,
    String factId, {
    String? edgeType,
    double minWeight = 0.0,
  }) {
    final query = select(episodicEdgesTable)
      ..where(
        (t) =>
            t.workspaceId.equals(workspaceId) &
            (t.sourceFactId.equals(factId) | t.targetFactId.equals(factId)) &
            t.weight.isBiggerOrEqualValue(minWeight) &
            (edgeType == null
                ? const Constant(true)
                : t.edgeType.equals(edgeType)),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.weight)]);
    return query.get();
  }

  /// Multi-hop BFS from [seedFactId] up to [depth] hops, returning each reached
  /// fact once (at its shortest depth). Mirrors mnemopi `findRelatedMemories`.
  Future<List<RelatedFactHop>> findRelated(
    String workspaceId,
    String seedFactId, {
    int depth = 2,
    String? edgeType,
    double minWeight = 0.0,
  }) async {
    final seen = <String>{seedFactId};
    final hops = <RelatedFactHop>[];
    var frontier = <String>{seedFactId};
    for (var d = 1; d <= depth && frontier.isNotEmpty; d++) {
      final next = <String>{};
      for (final node in frontier) {
        final edges = await neighbors(
          workspaceId,
          node,
          edgeType: edgeType,
          minWeight: minWeight,
        );
        for (final edge in edges) {
          final other =
              edge.sourceFactId == node ? edge.targetFactId : edge.sourceFactId;
          if (seen.add(other)) {
            next.add(other);
            hops.add(
              RelatedFactHop(
                factId: other,
                depth: d,
                weight: edge.weight,
                edgeType: edge.edgeType,
              ),
            );
          }
        }
      }
      frontier = next;
    }
    return hops;
  }
}