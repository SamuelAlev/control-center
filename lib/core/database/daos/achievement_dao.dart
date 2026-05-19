import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/achievements_table.dart';
import 'package:drift/drift.dart';

part 'achievement_dao.g.dart';

@DriftAccessor(tables: [AchievementsTable])
/// Achievement dao.
class AchievementDao extends DatabaseAccessor<AppDatabase>
    with _$AchievementDaoMixin {
  /// Creates a new [Achievement dao].
  AchievementDao(super.attachedDatabase);

  /// Insert.
  Future<void> insert(AchievementsTableCompanion entry) =>
      into(achievementsTable).insert(entry);

  /// Get by agent and badge.
  Future<AchievementsTableData?> getByAgentAndBadge(
    String agentId,
    String badgeKey,
  ) =>
      (select(achievementsTable)
            ..where((t) =>
                t.agentId.equals(agentId) & t.badgeKey.equals(badgeKey)))
          .getSingleOrNull();

  /// Watches all achievements for the given agent, ordered by unlock time descending.
  Stream<List<AchievementsTableData>> watchByAgent(String agentId) =>
      (select(achievementsTable)
            ..where((t) => t.agentId.equals(agentId))
            ..orderBy([(t) => OrderingTerm.desc(t.unlockedAt)]))
          .watch();

  /// Gets all achievements for the given agent, ordered by unlock time descending.
  Future<List<AchievementsTableData>> getByAgent(String agentId) =>
      (select(achievementsTable)
            ..where((t) => t.agentId.equals(agentId))
            ..orderBy([(t) => OrderingTerm.desc(t.unlockedAt)]))
          .get();
}
