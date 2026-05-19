import 'package:cc_domain/features/analytics/domain/entities/achievement.dart';

/// Achievement repository.
///
/// Every method takes a required `workspaceId` (first positional). Reads are
/// scoped to that workspace via a JOIN on Agents; writes validate the agent
/// belongs to `workspaceId` before mutating (throwing
/// `WorkspaceMismatchException` on a cross-workspace attempt). See the
/// workspace-isolation invariant in CLAUDE.md.
abstract class AchievementRepository {
  /// Watches achievements for a specific agent in [workspaceId] as a stream.
  Stream<List<Achievement>> watchByAgent(String workspaceId, String agentId);
  /// Retrieves all achievements for a specific agent in [workspaceId].
  Future<List<Achievement>> getByAgent(String workspaceId, String agentId);
  /// Unlock a badge for an agent in [workspaceId].
  Future<void> unlock(String workspaceId, String agentId, String badgeKey, {String? metadata});
  /// Is unlocked for an agent in [workspaceId].
  Future<bool> isUnlocked(String workspaceId, String agentId, String badgeKey);
}
