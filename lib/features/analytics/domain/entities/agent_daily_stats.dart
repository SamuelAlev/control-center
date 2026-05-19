/// Daily performance statistics for a single agent.
class AgentDailyStats {
  /// Creates a new [AgentDailyStats].
  const AgentDailyStats({
    required this.id,
    required this.agentId,
    required this.date,
    required this.runsCompleted,
    required this.runsErrored,
    required this.totalRunDurationMs,
    required this.prsCreated,
    required this.prsMerged,
    required this.reviewsCompleted,
    required this.blockingComments,
    required this.linesAdded,
    required this.linesDeleted,
    required this.xpEarned,
    required this.createdAt,
  });

  /// Unique identifier of the stats record.
  final String id;
  /// Identifier of the agent.
  final String agentId;
  /// The date these stats cover.
  final DateTime date;
  /// Number of runs completed on this day.
  final int runsCompleted;
  /// Number of runs that errored on this day.
  final int runsErrored;
  /// Total duration of all runs in milliseconds.
  final int totalRunDurationMs;
  /// Number of PRs created on this day.
  final int prsCreated;
  /// Number of PRs merged on this day.
  final int prsMerged;
  /// Number of reviews completed on this day.
  final int reviewsCompleted;
  /// Number of blocking comments left on this day.
  final int blockingComments;
  /// Lines of code added on this day.
  final int linesAdded;
  /// Lines of code deleted on this day.
  final int linesDeleted;
  /// Experience points earned on this day.
  final int xpEarned;
  /// When this stats record was created.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentDailyStats &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          agentId == other.agentId &&
          date == other.date &&
          runsCompleted == other.runsCompleted &&
          runsErrored == other.runsErrored &&
          totalRunDurationMs == other.totalRunDurationMs &&
          prsCreated == other.prsCreated &&
          prsMerged == other.prsMerged &&
          reviewsCompleted == other.reviewsCompleted &&
          blockingComments == other.blockingComments &&
          linesAdded == other.linesAdded &&
          linesDeleted == other.linesDeleted &&
          xpEarned == other.xpEarned &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    agentId,
    date,
    runsCompleted,
    runsErrored,
    totalRunDurationMs,
    prsCreated,
    prsMerged,
    reviewsCompleted,
    blockingComments,
    linesAdded,
    linesDeleted,
    xpEarned,
    createdAt,
  );
}
