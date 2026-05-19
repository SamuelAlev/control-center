import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/achievement_dao.dart';
import 'package:control_center/core/domain/events/analytics_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/features/analytics/data/mappers/analytics_mappers.dart';
import 'package:control_center/features/analytics/domain/entities/achievement.dart';
import 'package:control_center/features/analytics/domain/repositories/achievement_repository.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Concrete implementation of [AchievementRepository] backed by Drift DAO
/// and publishing domain events on unlock.
class AchievementRepositoryImpl implements AchievementRepository {
/// Creates the repository with a required [AchievementDao] and an optional
/// [DomainEventBus] for firing [AchievementUnlocked] events.
  AchievementRepositoryImpl(this._dao, {DomainEventBus? eventBus})
      : _eventBus = eventBus;

  final AchievementDao _dao;
  final DomainEventBus? _eventBus;
  final _mappers = AnalyticsMappers();

  @override
  Stream<List<Achievement>> watchByAgent(String agentId) =>
      _dao.watchByAgent(agentId).map(_mappers.achievementsToDomain);

  @override
  Future<List<Achievement>> getByAgent(String agentId) async {
    final rows = await _dao.getByAgent(agentId);
    return _mappers.achievementsToDomain(rows);
  }

  @override
  Future<void> unlock(String agentId, String badgeKey, {String? metadata}) async {
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
  Future<bool> isUnlocked(String agentId, String badgeKey) async {
    final row = await _dao.getByAgentAndBadge(agentId, badgeKey);
    return row != null;
  }
}

