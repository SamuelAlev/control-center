import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/achievements_table.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:drift/drift.dart';

part 'achievement_dao.g.dart';

@DriftAccessor(tables: [AchievementsTable, AgentsTable])
/// Achievement dao.
///
/// All agent-keyed reads JOIN [AgentsTable] and filter by the agent's
/// `workspaceId`. The `Achievements` table has no `workspaceId` column and
/// scopes through the `agentId` FK → `Agents.workspaceId`.
class AchievementDao extends DatabaseAccessor<AppDatabase>
    with _$AchievementDaoMixin {
  /// Creates a new [Achievement dao].
  AchievementDao(super.attachedDatabase);

  /// Insert.
  Future<void> insert(AchievementsTableCompanion entry) =>
      into(achievementsTable).insert(entry);

  /// Get by agent and badge. Keyed by `agentId` only — the repository validates
  /// the agent belongs to the caller's workspace before reaching this on the
  /// write/unlock path.
  Future<AchievementsTableData?> getByAgentAndBadge(
    String agentId,
    String badgeKey,
  ) =>
      (select(achievementsTable)
            ..where((t) =>
                t.agentId.equals(agentId) & t.badgeKey.equals(badgeKey)))
          .getSingleOrNull();

  /// Watches all achievements for the given agent within [workspaceId], ordered
  /// by unlock time descending. Scoped via a JOIN on Agents.
  Stream<List<AchievementsTableData>> watchByAgent(
    String workspaceId,
    String agentId,
  ) {
    final query = select(achievementsTable).join([
      innerJoin(
        agentsTable,
        agentsTable.id.equalsExp(achievementsTable.agentId),
      ),
    ])
      ..where(
        agentsTable.workspaceId.equals(workspaceId) &
            achievementsTable.agentId.equals(agentId),
      )
      ..orderBy([OrderingTerm.desc(achievementsTable.unlockedAt)]);
    return query.watch().map(
      (rows) => rows
          .map((r) => r.readTable(achievementsTable))
          .toList(growable: false),
    );
  }

  /// Gets all achievements for the given agent within [workspaceId], ordered by
  /// unlock time descending. Scoped via a JOIN on Agents.
  Future<List<AchievementsTableData>> getByAgent(
    String workspaceId,
    String agentId,
  ) {
    final query = select(achievementsTable).join([
      innerJoin(
        agentsTable,
        agentsTable.id.equalsExp(achievementsTable.agentId),
      ),
    ])
      ..where(
        agentsTable.workspaceId.equals(workspaceId) &
            achievementsTable.agentId.equals(agentId),
      )
      ..orderBy([OrderingTerm.desc(achievementsTable.unlockedAt)]);
    return query.get().then(
      (rows) => rows
          .map((r) => r.readTable(achievementsTable))
          .toList(growable: false),
    );
  }
}
