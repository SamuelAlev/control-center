import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/streak_dao.dart';
import 'package:control_center/features/analytics/data/mappers/analytics_mappers.dart';
import 'package:control_center/features/analytics/domain/entities/streak.dart';
import 'package:control_center/features/analytics/domain/repositories/streak_repository.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Streak repository impl.
class StreakRepositoryImpl implements StreakRepository {
  /// Creates a new [Streak repository impl].
  StreakRepositoryImpl(this._dao);

  final StreakDao _dao;
  final _mappers = AnalyticsMappers();

  @override
  Stream<List<Streak>> watchByAgent(String agentId) =>
      _dao.watchByAgent(agentId).map(_mappers.streaksToDomain);

  @override
  Future<List<Streak>> getByAgent(String agentId) async {
    final rows = await _dao.getByAgent(agentId);
    return _mappers.streaksToDomain(rows);
  }

  @override
  Future<void> updateStreak(String agentId, String streakType, {required bool increment}) async {
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
  Future<int> getCurrentStreak(String agentId, String streakType) async {
    final row = await _dao.getByAgentAndType(agentId, streakType);
    return row?.currentCount ?? 0;
  }
}

