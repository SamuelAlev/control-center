import 'package:control_center/features/analytics/domain/entities/achievement.dart';

/// Achievement repository.
abstract class AchievementRepository {
  /// Watches achievements for a specific agent as a stream.
  Stream<List<Achievement>> watchByAgent(String agentId);
  /// Retrieves all achievements for a specific agent.
  Future<List<Achievement>> getByAgent(String agentId);
  /// Unlock.
  Future<void> unlock(String agentId, String badgeKey, {String? metadata});
  /// Is unlocked.
  Future<bool> isUnlocked(String agentId, String badgeKey);
}
