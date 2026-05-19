/// An achievement earned by an agent for reaching a milestone.
class Achievement {
  /// Creates a new [Achievement].
  const Achievement({
    required this.id,
    required this.agentId,
    required this.badgeKey,
    required this.unlockedAt,
    this.metadata,
  });

  /// Unique identifier of the achievement record.
  final String id;
  /// Identifier of the agent who earned the achievement.
  final String agentId;
  /// Key identifying the badge type (e.g., 'first_merge').
  final String badgeKey;
  /// When the achievement was unlocked.
  final DateTime unlockedAt;
  /// Optional metadata associated with the achievement.
  final String? metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          agentId == other.agentId &&
          badgeKey == other.badgeKey &&
          unlockedAt == other.unlockedAt &&
          metadata == other.metadata;

  @override
  int get hashCode => Object.hash(id, agentId, badgeKey, unlockedAt, metadata);
}
