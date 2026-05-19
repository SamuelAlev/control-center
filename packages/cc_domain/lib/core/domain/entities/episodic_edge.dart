/// A typed, weighted semantic edge between two memory facts in a workspace.
///
/// Unlike `CodeEdgesTable` (AST-structural), these edges capture *semantic*
/// relatedness — discovered by lexical/entity/temporal overlap on ingest — so
/// recall can traverse from one fact to topically-connected ones (the graph
/// voice). Ported from oh-my-pi mnemopi `core/episodic-graph.ts` `graph_edges`.
class EpisodicEdge {
  /// Creates an [EpisodicEdge].
  EpisodicEdge({
    required this.id,
    required this.workspaceId,
    required this.sourceFactId,
    required this.targetFactId,
    required this.edgeType,
    this.weight = 1.0,
    required this.createdAt,
  }) : assert(workspaceId.isNotEmpty, 'EpisodicEdge workspaceId must not be empty');

  /// Unique identifier.
  final String id;
  /// Workspace this edge belongs to.
  final String workspaceId;
  /// Source fact id.
  final String sourceFactId;
  /// Target fact id.
  final String targetFactId;
  /// Edge type (see [EpisodicEdgeTypes]).
  final String edgeType;
  /// Edge weight in `[0,1]` (relatedness strength).
  final double weight;
  /// When the edge was created.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodicEdge &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          sourceFactId == other.sourceFactId &&
          targetFactId == other.targetFactId &&
          edgeType == other.edgeType &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(
        id,
        workspaceId,
        sourceFactId,
        targetFactId,
        edgeType,
        weight,
      );
}

/// Canonical edge-type slugs for [EpisodicEdge.edgeType].
class EpisodicEdgeTypes {
  const EpisodicEdgeTypes._();

  /// General topical/semantic relatedness (the default linking edge).
  static const String relatedTo = 'related_to';

  /// One fact references an entity/artifact named in another.
  static const String references = 'references';

  /// Shared situational/temporal context.
  static const String contextual = 'contextual';
}