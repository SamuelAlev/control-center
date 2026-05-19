import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/agent_daily_stats_table.dart';
import 'package:drift/drift.dart';

part 'analytics_dao.g.dart';

@DriftAccessor(tables: [AgentDailyStatsTable])
/// Analytics dao.
class AnalyticsDao extends DatabaseAccessor<AppDatabase> with _$AnalyticsDaoMixin {
  /// Creates a new [Analytics dao].
  AnalyticsDao(super.attachedDatabase);

  /// Upsert daily stats.
  Future<void> upsertDailyStats(AgentDailyStatsTableCompanion entry) =>
      into(agentDailyStatsTable).insertOnConflictUpdate(entry);

  /// Watches daily stats for the given agent, ordered by date descending.
  Stream<List<AgentDailyStatsTableData>> watchByAgent(String agentId) =>
      (select(agentDailyStatsTable)
            ..where((t) => t.agentId.equals(agentId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  /// Watches daily stats for the given agent within a date range.
  Stream<List<AgentDailyStatsTableData>> watchByAgentAndDateRange(
    String agentId,
    DateTime start,
    DateTime end,
  ) =>
      (select(agentDailyStatsTable)
            ..where((t) =>
                t.agentId.equals(agentId) &
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerOrEqualValue(end))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .watch();

  /// Watches daily stats across all agents within a date range.
  Stream<List<AgentDailyStatsTableData>> watchAllByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      (select(agentDailyStatsTable)
            ..where((t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerOrEqualValue(end))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  /// Get by agent and date.
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

  /// Gets all daily stats rows.
  Future<List<AgentDailyStatsTableData>> getAll() =>
      select(agentDailyStatsTable).get();

  /// Gets daily stats for the given agent, ordered by date descending.
  Future<List<AgentDailyStatsTableData>> getByAgent(String agentId) =>
      (select(agentDailyStatsTable)
            ..where((t) => t.agentId.equals(agentId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  /// Gets all daily stats within a date range.
  Future<List<AgentDailyStatsTableData>> getAllByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      (select(agentDailyStatsTable)
            ..where((t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerOrEqualValue(end))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();
}
