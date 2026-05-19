import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/agent_daily_stats_table.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:drift/drift.dart';

part 'analytics_dao.g.dart';

@DriftAccessor(tables: [AgentDailyStatsTable, AgentsTable])
/// Analytics dao.
///
/// All agent-keyed reads JOIN [AgentsTable] and filter by the agent's
/// `workspaceId` so a foreign workspace's stats can never surface — the
/// `AgentDailyStats` table has no `workspaceId` column of its own and scopes
/// through the `agentId` FK → `Agents.workspaceId`.
class AnalyticsDao extends DatabaseAccessor<AppDatabase> with _$AnalyticsDaoMixin {
  /// Creates a new [Analytics dao].
  AnalyticsDao(super.attachedDatabase);

  /// Upsert daily stats.
  Future<void> upsertDailyStats(AgentDailyStatsTableCompanion entry) =>
      into(agentDailyStatsTable).insertOnConflictUpdate(entry);

  /// Watches daily stats for the given agent within [workspaceId], ordered by
  /// date descending. Scoped via a JOIN on Agents — a foreign agent yields no
  /// rows.
  Stream<List<AgentDailyStatsTableData>> watchByAgent(
    String workspaceId,
    String agentId,
  ) {
    final query = select(agentDailyStatsTable).join([
      innerJoin(
        agentsTable,
        agentsTable.id.equalsExp(agentDailyStatsTable.agentId),
      ),
    ])
      ..where(
        agentsTable.workspaceId.equals(workspaceId) &
            agentDailyStatsTable.agentId.equals(agentId),
      )
      ..orderBy([OrderingTerm.desc(agentDailyStatsTable.date)]);
    return query.watch().map(
      (rows) => rows
          .map((r) => r.readTable(agentDailyStatsTable))
          .toList(growable: false),
    );
  }

  /// Watches daily stats for the given agent within a date range, scoped to
  /// [workspaceId] via a JOIN on Agents.
  Stream<List<AgentDailyStatsTableData>> watchByAgentAndDateRange(
    String workspaceId,
    String agentId,
    DateTime start,
    DateTime end,
  ) {
    final query = select(agentDailyStatsTable).join([
      innerJoin(
        agentsTable,
        agentsTable.id.equalsExp(agentDailyStatsTable.agentId),
      ),
    ])
      ..where(
        agentsTable.workspaceId.equals(workspaceId) &
            agentDailyStatsTable.agentId.equals(agentId) &
            agentDailyStatsTable.date.isBiggerOrEqualValue(start) &
            agentDailyStatsTable.date.isSmallerOrEqualValue(end),
      )
      ..orderBy([OrderingTerm.asc(agentDailyStatsTable.date)]);
    return query.watch().map(
      (rows) => rows
          .map((r) => r.readTable(agentDailyStatsTable))
          .toList(growable: false),
    );
  }

  /// Watches daily stats for every agent in [workspaceId] within a date range,
  /// ordered by date descending. Scoped via a JOIN on Agents.
  Stream<List<AgentDailyStatsTableData>> watchAllByDateRange(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) {
    final query = select(agentDailyStatsTable).join([
      innerJoin(
        agentsTable,
        agentsTable.id.equalsExp(agentDailyStatsTable.agentId),
      ),
    ])
      ..where(
        agentsTable.workspaceId.equals(workspaceId) &
            agentDailyStatsTable.date.isBiggerOrEqualValue(start) &
            agentDailyStatsTable.date.isSmallerOrEqualValue(end),
      )
      ..orderBy([OrderingTerm.desc(agentDailyStatsTable.date)]);
    return query.watch().map(
      (rows) => rows
          .map((r) => r.readTable(agentDailyStatsTable))
          .toList(growable: false),
    );
  }

  /// Get by agent and date. Used by the rebuild/backfill reconcilers, which
  /// already hold the agent (and therefore its workspace), so this stays keyed
  /// by `agentId` only — see the CROSS-WORKSPACE doc on [getAllByDateRange].
  Future<AgentDailyStatsTableData?> getByAgentAndDate(
    String agentId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(agentDailyStatsTable)
          ..where((t) =>
              t.agentId.equals(agentId) &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Gets daily stats for the given agent within [workspaceId], ordered by date
  /// descending. Scoped via a JOIN on Agents.
  Future<List<AgentDailyStatsTableData>> getByAgent(
    String workspaceId,
    String agentId,
  ) {
    final query = select(agentDailyStatsTable).join([
      innerJoin(
        agentsTable,
        agentsTable.id.equalsExp(agentDailyStatsTable.agentId),
      ),
    ])
      ..where(
        agentsTable.workspaceId.equals(workspaceId) &
            agentDailyStatsTable.agentId.equals(agentId),
      )
      ..orderBy([OrderingTerm.desc(agentDailyStatsTable.date)]);
    return query.get().then(
      (rows) => rows
          .map((r) => r.readTable(agentDailyStatsTable))
          .toList(growable: false),
    );
  }

  /// Gets all daily stats for every agent in [workspaceId] within a date range,
  /// ordered by date descending. Scoped via a JOIN on Agents.
  Future<List<AgentDailyStatsTableData>> getAllByDateRange(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) {
    final query = select(agentDailyStatsTable).join([
      innerJoin(
        agentsTable,
        agentsTable.id.equalsExp(agentDailyStatsTable.agentId),
      ),
    ])
      ..where(
        agentsTable.workspaceId.equals(workspaceId) &
            agentDailyStatsTable.date.isBiggerOrEqualValue(start) &
            agentDailyStatsTable.date.isSmallerOrEqualValue(end),
      )
      ..orderBy([OrderingTerm.desc(agentDailyStatsTable.date)]);
    return query.get().then(
      (rows) => rows
          .map((r) => r.readTable(agentDailyStatsTable))
          .toList(growable: false),
    );
  }
}
