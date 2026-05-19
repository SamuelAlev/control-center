import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/streaks_table.dart';
import 'package:drift/drift.dart';

part 'streak_dao.g.dart';

@DriftAccessor(tables: [StreaksTable, AgentsTable])
/// Streak dao.
///
/// All agent-keyed reads JOIN [AgentsTable] and filter by the agent's
/// `workspaceId`. The `Streaks` table has no `workspaceId` column and scopes
/// through the `agentId` FK → `Agents.workspaceId`.
class StreakDao extends DatabaseAccessor<AppDatabase> with _$StreakDaoMixin {
  /// Creates a new [Streak dao].
  StreakDao(super.attachedDatabase);

  /// Upsert.
  Future<void> upsert(StreaksTableCompanion entry) =>
      into(streaksTable).insertOnConflictUpdate(entry);

  /// Get by agent and type. Keyed by `agentId` only — the repository validates
  /// the agent belongs to the caller's workspace before reaching this on the
  /// write path.
  Future<StreaksTableData?> getByAgentAndType(
    String agentId,
    String streakType,
  ) =>
      (select(streaksTable)
            ..where((t) =>
                t.agentId.equals(agentId) & t.streakType.equals(streakType)))
          .getSingleOrNull();

  /// Watches streak rows for the given agent within [workspaceId]. Scoped via a
  /// JOIN on Agents.
  Stream<List<StreaksTableData>> watchByAgent(
    String workspaceId,
    String agentId,
  ) {
    final query = select(streaksTable).join([
      innerJoin(agentsTable, agentsTable.id.equalsExp(streaksTable.agentId)),
    ])
      ..where(
        agentsTable.workspaceId.equals(workspaceId) &
            streaksTable.agentId.equals(agentId),
      );
    return query.watch().map(
      (rows) =>
          rows.map((r) => r.readTable(streaksTable)).toList(growable: false),
    );
  }

  /// Gets streak rows for the given agent within [workspaceId]. Scoped via a
  /// JOIN on Agents.
  Future<List<StreaksTableData>> getByAgent(
    String workspaceId,
    String agentId,
  ) {
    final query = select(streaksTable).join([
      innerJoin(agentsTable, agentsTable.id.equalsExp(streaksTable.agentId)),
    ])
      ..where(
        agentsTable.workspaceId.equals(workspaceId) &
            streaksTable.agentId.equals(agentId),
      );
    return query.get().then(
      (rows) =>
          rows.map((r) => r.readTable(streaksTable)).toList(growable: false),
    );
  }

  /// Delete by agent.
  Future<int> deleteByAgent(String agentId) =>
      (delete(streaksTable)..where((t) => t.agentId.equals(agentId))).go();
}
