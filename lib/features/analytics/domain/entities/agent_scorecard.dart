import 'package:control_center/features/analytics/domain/entities/achievement.dart';
import 'package:control_center/features/analytics/domain/entities/streak.dart';

/// Aggregated lifetime scorecard for an agent.
class AgentScorecard {
  /// Creates a new [AgentScorecard].
  const AgentScorecard({
    required this.agentId,
    required this.agentName,
    required this.totalRuns,
    required this.totalErrored,
    required this.successRate,
    required this.avgRunDurationMs,
    required this.totalPrsCreated,
    required this.totalPrsMerged,
    required this.totalReviews,
    required this.totalBlockingComments,
    required this.totalXp,
    required this.level,
    required this.levelProgress,
    required this.currentStreaks,
    required this.achievements,
  });

  /// Identifier of the agent.
  final String agentId;
  /// Display name of the agent.
  final String agentName;
  /// Total number of runs across all time.
  final int totalRuns;
  /// Total number of errored runs across all time.
  final int totalErrored;
  /// Percentage of runs that succeeded (0.0–1.0).
  final double successRate;
  /// Average run duration in milliseconds.
  final int avgRunDurationMs;
  /// Total PRs created by the agent.
  final int totalPrsCreated;
  /// Total PRs merged by the agent.
  final int totalPrsMerged;
  /// Total reviews completed by the agent.
  final int totalReviews;
  /// Total blocking comments left by the agent.
  final int totalBlockingComments;
  /// Total experience points earned.
  final int totalXp;
  /// Current level derived from XP.
  final int level;
  /// Progress toward the next level (0.0–1.0).
  final double levelProgress;
  /// Active streaks for the agent.
  final List<Streak> currentStreaks;
  /// Achievements unlocked by the agent.
  final List<Achievement> achievements;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentScorecard &&
          runtimeType == other.runtimeType &&
          agentId == other.agentId &&
          agentName == other.agentName &&
          totalRuns == other.totalRuns &&
          totalErrored == other.totalErrored &&
          successRate == other.successRate &&
          avgRunDurationMs == other.avgRunDurationMs &&
          totalPrsCreated == other.totalPrsCreated &&
          totalPrsMerged == other.totalPrsMerged &&
          totalReviews == other.totalReviews &&
          totalBlockingComments == other.totalBlockingComments &&
          totalXp == other.totalXp &&
          level == other.level &&
          levelProgress == other.levelProgress &&
          _listEquals(currentStreaks, other.currentStreaks) &&
          _listEquals(achievements, other.achievements);

  @override
  int get hashCode => Object.hash(
    agentId,
    agentName,
    totalRuns,
    totalErrored,
    successRate,
    avgRunDurationMs,
    totalPrsCreated,
    totalPrsMerged,
    totalReviews,
    totalBlockingComments,
    totalXp,
    level,
    levelProgress,
    Object.hashAll(currentStreaks),
    Object.hashAll(achievements),
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
