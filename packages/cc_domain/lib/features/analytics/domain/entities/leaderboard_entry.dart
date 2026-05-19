/// A single entry in the agent leaderboard.
class LeaderboardEntry {
  /// Creates a new [LeaderboardEntry].
  const LeaderboardEntry({
    required this.agentId,
    required this.agentName,
    required this.score,
    required this.rank,
  });

  /// Identifier of the agent.
  final String agentId;
  /// Display name of the agent.
  final String agentName;
  /// Computed score for the current window.
  final int score;
  /// Rank position (1-based).
  final int rank;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry &&
          runtimeType == other.runtimeType &&
          agentId == other.agentId &&
          agentName == other.agentName &&
          score == other.score &&
          rank == other.rank;

  @override
  int get hashCode => Object.hash(agentId, agentName, score, rank);
}
