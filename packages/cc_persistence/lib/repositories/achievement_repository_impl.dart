import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/events/analytics_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/analytics/domain/entities/achievement.dart';
import 'package:cc_domain/features/analytics/domain/repositories/achievement_repository.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/achievement_dao.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/mappers/analytics_mappers.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Concrete implementation of [AchievementRepository] backed by Drift DAO
/// and publishing domain events on unlock.
///
/// Workspace-scoped: reads go through the DAO's Agents JOIN; writes validate
/// the target agent belongs to the supplied `workspaceId` (via [AgentDao])
/// before mutating, throwing [WorkspaceMismatchException] on a cross-workspace
/// attempt.
class AchievementRepositoryImpl implements AchievementRepository {
/// Creates the repository with a required [AchievementDao], an [AgentDao] used
/// to validate agent-in-workspace on writes, and an optional [DomainEventBus]
/// for firing [AchievementUnlocked] events.
  AchievementRepositoryImpl(
    this._dao,
    this._agentDao, {
    DomainEventBus? eventBus,
  }) : _eventBus = eventBus;

  final AchievementDao _dao;
  final AgentDao _agentDao;
  final DomainEventBus? _eventBus;
  final _mappers = AnalyticsMappers();

  /// Loads [agentId] and asserts it belongs to [workspaceId], else throws
  /// [WorkspaceMismatchException]. Used as the single write chokepoint.
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
  Stream<List<Achievement>> watchByAgent(String workspaceId, String agentId) =>
      _dao.watchByAgent(workspaceId, agentId).map(_mappers.achievementsToDomain);

  @override
  Future<List<Achievement>> getByAgent(String workspaceId, String agentId) async {
    final rows = await _dao.getByAgent(workspaceId, agentId);
    return _mappers.achievementsToDomain(rows);
  }

  @override
  Future<void> unlock(
    String workspaceId,
    String agentId,
    String badgeKey, {
    String? metadata,
  }) async {
    await _assertAgentInWorkspace(workspaceId, agentId);

    final existing = await _dao.getByAgentAndBadge(agentId, badgeKey);
    if (existing != null) {
      return;
    }

    const uuid = Uuid();
    await _dao.insert(
      AchievementsTableCompanion.insert(
        id: uuid.v4(),
        agentId: agentId,
        badgeKey: badgeKey,
        metadata: drift.Value(metadata),
      ),
    );

    _eventBus?.publish(
      AchievementUnlocked(
        agentId: agentId,
        badgeKey: badgeKey,
        occurredAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> isUnlocked(
    String workspaceId,
    String agentId,
    String badgeKey,
  ) async {
    await _assertAgentInWorkspace(workspaceId, agentId);
    final row = await _dao.getByAgentAndBadge(agentId, badgeKey);
    return row != null;
  }
}
