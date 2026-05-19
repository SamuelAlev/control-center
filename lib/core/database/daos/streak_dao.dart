import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/streaks_table.dart';
import 'package:drift/drift.dart';

part 'streak_dao.g.dart';

@DriftAccessor(tables: [StreaksTable])
/// Streak dao.
class StreakDao extends DatabaseAccessor<AppDatabase> with _$StreakDaoMixin {
  /// Creates a new [Streak dao].
  StreakDao(super.attachedDatabase);

  /// Upsert.
  Future<void> upsert(StreaksTableCompanion entry) =>
      into(streaksTable).insertOnConflictUpdate(entry);

  /// Get by agent and type.
  Future<StreaksTableData?> getByAgentAndType(
    String agentId,
    String streakType,
  ) =>
      (select(streaksTable)
            ..where((t) =>
                t.agentId.equals(agentId) & t.streakType.equals(streakType)))
          .getSingleOrNull();

  /// Watches streak rows for the given agent.
  Stream<List<StreaksTableData>> watchByAgent(String agentId) =>
      (select(streaksTable)
            ..where((t) => t.agentId.equals(agentId)))
          .watch();

  /// Gets streak rows for the given agent.
  Future<List<StreaksTableData>> getByAgent(String agentId) =>
      (select(streaksTable)..where((t) => t.agentId.equals(agentId))).get();

  /// Delete by agent.
  Future<int> deleteByAgent(String agentId) =>
      (delete(streaksTable)..where((t) => t.agentId.equals(agentId))).go();
}
