/// A harmonized belief emitted by cross-agent SHMR (Semantic Harmonic Memory
/// Resonance), ported from oh-my-pi mnemopi `core/shmr.ts` `harmonic_beliefs`.
///
/// When several agents in a workspace independently assert semantically-similar
/// facts, SHMR clusters them and emits a single corroborated [MemoryBelief] with
/// a confidence reflecting the agreement, so the team acts on one shared
/// conclusion instead of N near-duplicates.
class MemoryBelief {
  /// Creates a [MemoryBelief].
  MemoryBelief({
    required this.id,
    required this.workspaceId,
    required this.topic,
    required this.content,
    this.confidence = 0.5,
    this.harmonyScore = 0.0,
    this.provenanceFactIds = const [],
    this.provenanceAgentIds = const [],
    required this.clusterId,
    this.action = 'create',
    required this.createdAt,
    required this.updatedAt,
  }) : assert(workspaceId.isNotEmpty, 'MemoryBelief workspaceId must not be empty');

  /// Unique identifier.
  final String id;
  /// Workspace this belief belongs to.
  final String workspaceId;
  /// Topic the belief is about.
  final String topic;
  /// The harmonized statement.
  final String content;
  /// Corroborated confidence in `[0,1]`.
  final double confidence;
  /// How well the belief resonates with its cluster centroid in `[0,1]`.
  final double harmonyScore;
  /// Source fact ids that corroborate this belief.
  final List<String> provenanceFactIds;
  /// Agent ids that contributed to this belief.
  final List<String> provenanceAgentIds;
  /// The cluster this belief came from.
  final String clusterId;
  /// What harmonization did: `create`, `update`, or `dampen`.
  final String action;
  /// When created.
  final DateTime createdAt;
  /// When last updated.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryBelief &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          topic == other.topic &&
          content == other.content &&
          confidence == other.confidence &&
          clusterId == other.clusterId &&
          action == other.action;

  @override
  int get hashCode =>
      Object.hash(id, workspaceId, topic, content, confidence, clusterId, action);
}