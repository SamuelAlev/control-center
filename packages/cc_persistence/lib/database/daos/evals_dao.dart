import 'package:cc_persistence/database/tables/evals_tables.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'evals_dao.g.dart';

/// Data access for agent evals, replay & regression (PRD 21): session
/// recordings, golden sessions, eval suites/runs and agent config versions.
/// Every read filters by `workspaceId` (workspace isolation invariant).
@DriftAccessor(
  tables: [
    SessionRecordingsTable,
    GoldenSessionsTable,
    EvalSuitesTable,
    EvalRunsTable,
    AgentConfigVersionsTable,
  ],
)
class EvalsDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$EvalsDaoMixin {
  /// Creates an [EvalsDao].
  EvalsDao(super.db);

  // ── Session recordings ──

  /// Inserts or replaces a recording (deterministic id → PK upsert).
  Future<void> upsertRecording(SessionRecordingsTableCompanion entry) =>
      into(sessionRecordingsTable).insertOnConflictUpdate(entry);

  /// One recording by id within [workspaceId], or null.
  Future<SessionRecordingsTableData?> recordingById(
    String workspaceId,
    String id,
  ) =>
      (select(sessionRecordingsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// The recording for a given run log within [workspaceId], or null.
  Future<SessionRecordingsTableData?> recordingByRunLog(
    String workspaceId,
    String runLogId,
  ) =>
      (select(sessionRecordingsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) & t.runLogId.equals(runLogId),
          ))
          .getSingleOrNull();

  /// Recordings in [workspaceId], newest first (optionally filtered by agent).
  Future<List<SessionRecordingsTableData>> recordings(
    String workspaceId, {
    String? agentId,
    int limit = 200,
  }) {
    final q = select(sessionRecordingsTable)
      ..where((t) {
        final base = t.workspaceId.equals(workspaceId);
        return agentId == null ? base : base & t.agentId.equals(agentId);
      })
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return q.get();
  }

  /// Live recordings in [workspaceId], newest first.
  Stream<List<SessionRecordingsTableData>> watchRecordings(
    String workspaceId, {
    int limit = 200,
  }) =>
      (select(sessionRecordingsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  /// Deletes recordings older than [cutoff] within [workspaceId] (retention).
  Future<int> pruneRecordings(String workspaceId, DateTime cutoff) =>
      (delete(sessionRecordingsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.createdAt.isSmallerThanValue(cutoff),
          ))
          .go();

  // ── Golden sessions ──

  /// Inserts or replaces a golden (deterministic id → PK upsert).
  Future<void> upsertGolden(GoldenSessionsTableCompanion entry) =>
      into(goldenSessionsTable).insertOnConflictUpdate(entry);

  /// One golden by id within [workspaceId], or null.
  Future<GoldenSessionsTableData?> goldenById(String workspaceId, String id) =>
      (select(goldenSessionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Enabled goldens for [agentId] within [workspaceId].
  Future<List<GoldenSessionsTableData>> goldensForAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(goldenSessionsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.agentId.equals(agentId) &
                t.enabled.equals(true),
          ))
          .get();

  /// All goldens in [workspaceId], newest first.
  Future<List<GoldenSessionsTableData>> goldens(String workspaceId) =>
      (select(goldenSessionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.blessedAt)]))
          .get();

  /// Live goldens in [workspaceId].
  Stream<List<GoldenSessionsTableData>> watchGoldens(String workspaceId) =>
      (select(goldenSessionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.blessedAt)]))
          .watch();

  /// Records the last golden run result within [workspaceId].
  Future<void> updateGoldenResult(
    String workspaceId,
    String id,
    String status,
    String? scorecardJson,
  ) =>
      (update(goldenSessionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .write(
            GoldenSessionsTableCompanion(
              lastStatus: Value(status),
              lastScorecardJson: Value(scorecardJson),
            ),
          );

  /// Deletes a golden within [workspaceId].
  Future<void> deleteGolden(String workspaceId, String id) => (delete(
    goldenSessionsTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();

  // ── Eval suites ──

  /// Inserts or replaces a suite (deterministic id → PK upsert).
  Future<void> upsertSuite(EvalSuitesTableCompanion entry) =>
      into(evalSuitesTable).insertOnConflictUpdate(entry);

  /// One suite by id within [workspaceId], or null.
  Future<EvalSuitesTableData?> suiteById(String workspaceId, String id) =>
      (select(evalSuitesTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// One suite by name within [workspaceId], or null.
  Future<EvalSuitesTableData?> suiteByName(String workspaceId, String name) =>
      (select(evalSuitesTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.name.equals(name),
          ))
          .getSingleOrNull();

  /// Suites in [workspaceId], by name.
  Future<List<EvalSuitesTableData>> suites(String workspaceId) =>
      (select(evalSuitesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  /// Live suites in [workspaceId].
  Stream<List<EvalSuitesTableData>> watchSuites(String workspaceId) =>
      (select(evalSuitesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  /// Deletes a suite within [workspaceId].
  Future<void> deleteSuite(String workspaceId, String id) => (delete(
    evalSuitesTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();

  // ── Eval runs ──

  /// Inserts or replaces an eval run (deterministic id → PK upsert).
  Future<void> upsertRun(EvalRunsTableCompanion entry) =>
      into(evalRunsTable).insertOnConflictUpdate(entry);

  /// One run by id within [workspaceId], or null.
  Future<EvalRunsTableData?> runById(String workspaceId, String id) =>
      (select(evalRunsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Runs for [suiteId] within [workspaceId], newest first.
  Future<List<EvalRunsTableData>> runsForSuite(
    String workspaceId,
    String suiteId, {
    int limit = 100,
  }) =>
      (select(evalRunsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.suiteId.equals(suiteId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  /// Live runs for [suiteId] within [workspaceId], newest first.
  Stream<List<EvalRunsTableData>> watchRunsForSuite(
    String workspaceId,
    String suiteId, {
    int limit = 100,
  }) =>
      (select(evalRunsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.suiteId.equals(suiteId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  /// Marks a run terminal within [workspaceId].
  Future<void> updateRunResult(
    String workspaceId,
    String id, {
    required String status,
    String? scorecardJson,
    double? passRate,
    int? costCents,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) =>
      (update(evalRunsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .write(
            EvalRunsTableCompanion(
              status: Value(status),
              scorecardJson: scorecardJson == null
                  ? const Value.absent()
                  : Value(scorecardJson),
              passRate: passRate == null
                  ? const Value.absent()
                  : Value(passRate),
              costCents: costCents == null
                  ? const Value.absent()
                  : Value(costCents),
              startedAt: startedAt == null
                  ? const Value.absent()
                  : Value(startedAt),
              finishedAt: finishedAt == null
                  ? const Value.absent()
                  : Value(finishedAt),
            ),
          );

  // ── Agent config versions ──

  /// Inserts or replaces a config version (deterministic id → PK upsert).
  Future<void> upsertConfigVersion(AgentConfigVersionsTableCompanion entry) =>
      into(agentConfigVersionsTable).insertOnConflictUpdate(entry);

  /// The live config version for [agentId] within [workspaceId], or null.
  Future<AgentConfigVersionsTableData?> liveConfigVersion(
    String workspaceId,
    String agentId,
  ) =>
      (select(agentConfigVersionsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.agentId.equals(agentId) &
                  t.status.equals('live'),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  /// A config version by (agent, hash) within [workspaceId], or null.
  Future<AgentConfigVersionsTableData?> configVersionByHash(
    String workspaceId,
    String agentId,
    String configHash,
  ) =>
      (select(agentConfigVersionsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.agentId.equals(agentId) &
                t.configHash.equals(configHash),
          ))
          .getSingleOrNull();

  /// All config versions for [agentId] within [workspaceId], newest first.
  Future<List<AgentConfigVersionsTableData>> configVersionsForAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(agentConfigVersionsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.agentId.equals(agentId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Sets a config version's status within [workspaceId] (promote/retire).
  Future<void> setConfigVersionStatus(
    String workspaceId,
    String id, {
    required String status,
    String? promotedBy,
    DateTime? promotedAt,
    String? scorecardJson,
  }) =>
      (update(agentConfigVersionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .write(
            AgentConfigVersionsTableCompanion(
              status: Value(status),
              promotedBy: promotedBy == null
                  ? const Value.absent()
                  : Value(promotedBy),
              promotedAt: promotedAt == null
                  ? const Value.absent()
                  : Value(promotedAt),
              scorecardJson: scorecardJson == null
                  ? const Value.absent()
                  : Value(scorecardJson),
            ),
          );
}
