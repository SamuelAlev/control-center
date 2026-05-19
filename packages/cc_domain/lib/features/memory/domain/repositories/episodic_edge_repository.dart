import 'package:cc_domain/core/domain/entities/episodic_edge.dart';

/// Repository for [EpisodicEdge] persistence + traversal (workspace-scoped).
abstract class EpisodicEdgeRepository {
  /// Inserts or updates an edge (keyed on the workspace/source/target/type
  /// uniqueness).
  Future<void> upsert(EpisodicEdge edge);

  /// All edges in a workspace.
  Future<List<EpisodicEdge>> getByWorkspace(String workspaceId);

  /// Multi-hop BFS from [seedFactId] up to [depth] hops, returning reached fact
  /// ids in traversal order (nearest, heaviest edge first), each once.
  Future<List<String>> findRelated(
    String workspaceId,
    String seedFactId, {
    int depth = 2,
    String? edgeType,
    double minWeight = 0.0,
  });
}