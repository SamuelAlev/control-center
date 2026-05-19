import 'package:control_center/features/analytics/domain/entities/streak.dart';

/// Streak repository.
abstract class StreakRepository {
  /// Watches streaks for a specific agent as a stream.
  Stream<List<Streak>> watchByAgent(String agentId);
  /// Retrieves all streaks for a specific agent.
  Future<List<Streak>> getByAgent(String agentId);
  /// Update streak.
  Future<void> updateStreak(String agentId, String streakType, {required bool increment});
  /// Get current streak.
  Future<int> getCurrentStreak(String agentId, String streakType);
}
