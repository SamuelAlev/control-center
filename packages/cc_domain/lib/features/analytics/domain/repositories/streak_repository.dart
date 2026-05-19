import 'package:cc_domain/features/analytics/domain/entities/streak.dart';

/// Streak repository.
///
/// Every method takes a required `workspaceId` (first positional). Reads are
/// scoped to that workspace via a JOIN on Agents; `updateStreak` validates the
/// agent belongs to `workspaceId` before mutating (throwing
/// `WorkspaceMismatchException` on a cross-workspace attempt). See the
/// workspace-isolation invariant in CLAUDE.md.
abstract class StreakRepository {
  /// Watches streaks for a specific agent in [workspaceId] as a stream.
  Stream<List<Streak>> watchByAgent(String workspaceId, String agentId);
  /// Retrieves all streaks for a specific agent in [workspaceId].
  Future<List<Streak>> getByAgent(String workspaceId, String agentId);
  /// Update streak for an agent in [workspaceId].
  Future<void> updateStreak(String workspaceId, String agentId, String streakType, {required bool increment});
  /// Get current streak for an agent in [workspaceId].
  Future<int> getCurrentStreak(String workspaceId, String agentId, String streakType);
}
