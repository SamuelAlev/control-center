/// A streak tracking consecutive activity for an agent.
class Streak {
  /// Creates a new [Streak].
  const Streak({
    required this.id,
    required this.agentId,
    required this.streakType,
    required this.currentCount,
    required this.bestCount,
    this.lastDate,
    required this.updatedAt,
  });

  /// Unique identifier of the streak record.
  final String id;
  /// Identifier of the agent.
  final String agentId;
  /// Type of streak being tracked (e.g., 'pr_merged').
  final String streakType;
  /// Current consecutive count.
  final int currentCount;
  /// Best consecutive count achieved.
  final int bestCount;
  /// Date of the most recent activity that extended the streak.
  final DateTime? lastDate;
  /// When this streak record was last updated.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Streak &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          agentId == other.agentId &&
          streakType == other.streakType &&
          currentCount == other.currentCount &&
          bestCount == other.bestCount &&
          lastDate == other.lastDate &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    agentId,
    streakType,
    currentCount,
    bestCount,
    lastDate,
    updatedAt,
  );
}
