/// Why one node of an executing plan left its declared scope.
final class PlanDivergence {
  /// Creates the marker of [nodeKey]. Throws [ArgumentError] on an empty key.
  PlanDivergence({
    required this.nodeKey,
    required List<String> reasons,
    required this.at,
    required this.held,
  }) : reasons = List.unmodifiable(reasons) {
    if (nodeKey.isEmpty) {
      throw ArgumentError.value(nodeKey, 'nodeKey', 'must not be empty');
    }
  }

  /// The plan node.
  final String nodeKey;

  /// What diverged (cost above the estimate, files outside the declared
  /// references).
  final List<String> reasons;

  /// When it was found.
  final DateTime at;

  /// Whether the node's step is held until someone continues it.
  final bool held;

  /// The wire form of one marker (`orchestration.divergence`).
  Map<String, dynamic> toWire() => {
    'reasons': reasons,
    'at': at.toIso8601String(),
    'held': held,
  };

  @override
  bool operator ==(Object other) =>
      other is PlanDivergence &&
      other.nodeKey == nodeKey &&
      other.at == at &&
      other.held == held &&
      other.reasons.length == reasons.length &&
      Iterable<int>.generate(
        reasons.length,
      ).every((i) => other.reasons[i] == reasons[i]);

  @override
  int get hashCode => Object.hash(nodeKey, at, held, Object.hashAll(reasons));
}

/// Divergence markers of executing plans, per orchestration.
///
/// A held node shows why it is held for as long as it is: state, never a cache
/// row. Markers go with their orchestration.
abstract interface class PlanDivergenceRepository {
  /// Every marker of [orchestrationId], by node key.
  Future<Map<String, PlanDivergence>> forOrchestration(
    String workspaceId,
    String orchestrationId,
  );

  /// Records [divergence] for its node, replacing an earlier marker.
  Future<void> record(
    String workspaceId,
    String orchestrationId,
    PlanDivergence divergence,
  );

  /// Clears the held flag of [nodeKey]'s marker. A no-op when it has none.
  Future<void> markResumed(
    String workspaceId,
    String orchestrationId,
    String nodeKey,
  );
}
