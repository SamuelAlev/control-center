import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/features/analytics/domain/entities/streak.dart';
import 'package:cc_domain/features/analytics/domain/repositories/streak_repository.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/database/daos/streak_dao.dart';
import 'package:cc_persistence/mappers/analytics_mappers.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Streak repository impl.
///
/// Workspace-scoped: reads go through the DAO's Agents JOIN; [updateStreak] and
/// [getCurrentStreak] validate the target agent belongs to the supplied
/// `workspaceId` (via [AgentDao]) before touching its streak, throwing
/// [WorkspaceMismatchException] on a cross-workspace attempt.
class StreakRepositoryImpl implements StreakRepository {
  /// Creates a new [Streak repository impl].
  StreakRepositoryImpl(this._dao, this._agentDao);

  final StreakDao _dao;
  final AgentDao _agentDao;
  final _mappers = AnalyticsMappers();

  /// Loads [agentId] and asserts it belongs to [workspaceId], else throws
  /// [WorkspaceMismatchException]. Used as the single mutation chokepoint.
  Future<void> _assertAgentInWorkspace(
    String workspaceId,
    String agentId,
  ) async {
    final agent = await _agentDao.getById(agentId);
    if (agent == null || agent.workspaceId != workspaceId) {
      throw WorkspaceMismatchException(
        'Agent $agentId does not belong to workspace $workspaceId.',
      );
    }
  }

  @override
  Stream<List<Streak>> watchByAgent(String workspaceId, String agentId) =>
      _dao.watchByAgent(workspaceId, agentId).map(_mappers.streaksToDomain);

  @override
  Future<List<Streak>> getByAgent(String workspaceId, String agentId) async {
    final rows = await _dao.getByAgent(workspaceId, agentId);
    return _mappers.streaksToDomain(rows);
  }

  @override
  Future<void> updateStreak(
    String workspaceId,
    String agentId,
    String streakType, {
    required bool increment,
  }) async {
    await _assertAgentInWorkspace(workspaceId, agentId);

    final existing = await _dao.getByAgentAndType(agentId, streakType);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (existing == null) {
      const uuid = Uuid();
      await _dao.upsert(
        StreaksTableCompanion.insert(
          id: uuid.v4(),
          agentId: agentId,
          streakType: streakType,
          currentCount: drift.Value(increment ? 1 : 0),
          bestCount: drift.Value(increment ? 1 : 0),
          lastDate: drift.Value(today),
        ),
      );
      return;
    }

    final lastDate = existing.lastDate;
    final newCount = increment
        ? (lastDate != null && lastDate == today ? existing.currentCount : existing.currentCount + 1)
        : existing.currentCount;

    await _dao.upsert(
      StreaksTableCompanion.insert(
        id: existing.id,
        agentId: agentId,
        streakType: streakType,
        currentCount: drift.Value(newCount),
        bestCount: drift.Value(newCount > existing.bestCount ? newCount : existing.bestCount),
        lastDate: drift.Value(today),
        updatedAt: drift.Value(now),
      ),
    );
  }

  @override
  Future<int> getCurrentStreak(
    String workspaceId,
    String agentId,
    String streakType,
  ) async {
    await _assertAgentInWorkspace(workspaceId, agentId);
    final row = await _dao.getByAgentAndType(agentId, streakType);
    return row?.currentCount ?? 0;
  }
}
