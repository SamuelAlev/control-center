import 'package:cc_domain/features/evals/domain/entities/evals_entities.dart';
import 'package:cc_domain/features/evals/domain/repositories/evals_repository.dart';
import 'package:cc_persistence/database/daos/evals_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/evals_mapper.dart';

/// Drift-backed [EvalsRepository] (PRD 21).
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).evalsDao` per call: recordings, goldens, suites, runs
/// and config versions live in their workspace's own database file, so the
/// workspace id picks the file before any SQL runs. Rows↔entities are mapped
/// with [EvalsMapper]. Writes take the workspace from the entity, which carries
/// it, so the file and the stored `workspace_id` can never disagree.
class DaoEvalsRepository implements EvalsRepository {
  /// Creates a [DaoEvalsRepository] over the per-workspace databases.
  DaoEvalsRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final EvalsMapper _mapper = const EvalsMapper();

  EvalsDao _dao(String workspaceId) => _dbs.of(workspaceId).evalsDao;

  // ── Session recordings ──

  @override
  Future<void> upsertRecording(SessionRecording recording) => _dao(
    recording.workspaceId,
  ).upsertRecording(_mapper.recordingToCompanion(recording));

  @override
  Future<SessionRecording?> recordingById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).recordingById(workspaceId, id);
    return row == null ? null : _mapper.recordingFromRow(row);
  }

  @override
  Future<SessionRecording?> recordingByRunLog(
    String workspaceId,
    String runLogId,
  ) async {
    final row = await _dao(
      workspaceId,
    ).recordingByRunLog(workspaceId, runLogId);
    return row == null ? null : _mapper.recordingFromRow(row);
  }

  @override
  Future<List<SessionRecording>> recordings(
    String workspaceId, {
    String? agentId,
    int limit = 200,
  }) async => (await _dao(workspaceId).recordings(
    workspaceId,
    agentId: agentId,
    limit: limit,
  )).map(_mapper.recordingFromRow).toList();

  @override
  Stream<List<SessionRecording>> watchRecordings(String workspaceId) =>
      _dao(workspaceId)
          .watchRecordings(workspaceId)
          .map((rows) => rows.map(_mapper.recordingFromRow).toList());

  @override
  Future<int> pruneRecordings(String workspaceId, DateTime cutoff) =>
      _dao(workspaceId).pruneRecordings(workspaceId, cutoff);

  // ── Golden sessions ──

  @override
  Future<void> upsertGolden(GoldenSession golden) =>
      _dao(golden.workspaceId).upsertGolden(_mapper.goldenToCompanion(golden));

  @override
  Future<GoldenSession?> goldenById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).goldenById(workspaceId, id);
    return row == null ? null : _mapper.goldenFromRow(row);
  }

  @override
  Future<List<GoldenSession>> goldensForAgent(
    String workspaceId,
    String agentId,
  ) async => (await _dao(
    workspaceId,
  ).goldensForAgent(workspaceId, agentId)).map(_mapper.goldenFromRow).toList();

  @override
  Future<List<GoldenSession>> goldens(String workspaceId) async => (await _dao(
    workspaceId,
  ).goldens(workspaceId)).map(_mapper.goldenFromRow).toList();

  @override
  Stream<List<GoldenSession>> watchGoldens(String workspaceId) =>
      _dao(workspaceId)
          .watchGoldens(workspaceId)
          .map((rows) => rows.map(_mapper.goldenFromRow).toList());

  @override
  Future<void> updateGoldenResult(
    String workspaceId,
    String id,
    String status,
    String? scorecardJson,
  ) => _dao(
    workspaceId,
  ).updateGoldenResult(workspaceId, id, status, scorecardJson);

  @override
  Future<void> deleteGolden(String workspaceId, String id) =>
      _dao(workspaceId).deleteGolden(workspaceId, id);

  // ── Eval suites ──

  @override
  Future<void> upsertSuite(EvalSuite suite) =>
      _dao(suite.workspaceId).upsertSuite(_mapper.suiteToCompanion(suite));

  @override
  Future<EvalSuite?> suiteById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).suiteById(workspaceId, id);
    return row == null ? null : _mapper.suiteFromRow(row);
  }

  @override
  Future<EvalSuite?> suiteByName(String workspaceId, String name) async {
    final row = await _dao(workspaceId).suiteByName(workspaceId, name);
    return row == null ? null : _mapper.suiteFromRow(row);
  }

  @override
  Future<List<EvalSuite>> suites(String workspaceId) async => (await _dao(
    workspaceId,
  ).suites(workspaceId)).map(_mapper.suiteFromRow).toList();

  @override
  Stream<List<EvalSuite>> watchSuites(String workspaceId) => _dao(workspaceId)
      .watchSuites(workspaceId)
      .map((rows) => rows.map(_mapper.suiteFromRow).toList());

  @override
  Future<void> deleteSuite(String workspaceId, String id) =>
      _dao(workspaceId).deleteSuite(workspaceId, id);

  // ── Eval runs ──

  @override
  Future<void> upsertRun(EvalRun run) =>
      _dao(run.workspaceId).upsertRun(_mapper.runToCompanion(run));

  @override
  Future<EvalRun?> runById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).runById(workspaceId, id);
    return row == null ? null : _mapper.runFromRow(row);
  }

  @override
  Future<List<EvalRun>> runsForSuite(
    String workspaceId,
    String suiteId, {
    int limit = 100,
  }) async => (await _dao(workspaceId).runsForSuite(
    workspaceId,
    suiteId,
    limit: limit,
  )).map(_mapper.runFromRow).toList();

  @override
  Stream<List<EvalRun>> watchRunsForSuite(String workspaceId, String suiteId) =>
      _dao(workspaceId)
          .watchRunsForSuite(workspaceId, suiteId)
          .map((rows) => rows.map(_mapper.runFromRow).toList());

  @override
  Future<void> updateRunResult(
    String workspaceId,
    String id, {
    required String status,
    String? scorecardJson,
    double? passRate,
    int? costCents,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) => _dao(workspaceId).updateRunResult(
    workspaceId,
    id,
    status: status,
    scorecardJson: scorecardJson,
    passRate: passRate,
    costCents: costCents,
    startedAt: startedAt,
    finishedAt: finishedAt,
  );

  // ── Agent config versions ──

  @override
  Future<void> upsertConfigVersion(AgentConfigVersion version) => _dao(
    version.workspaceId,
  ).upsertConfigVersion(_mapper.configVersionToCompanion(version));

  @override
  Future<AgentConfigVersion?> liveConfigVersion(
    String workspaceId,
    String agentId,
  ) async {
    final row = await _dao(workspaceId).liveConfigVersion(workspaceId, agentId);
    return row == null ? null : _mapper.configVersionFromRow(row);
  }

  @override
  Future<AgentConfigVersion?> configVersionByHash(
    String workspaceId,
    String agentId,
    String configHash,
  ) async {
    final row = await _dao(
      workspaceId,
    ).configVersionByHash(workspaceId, agentId, configHash);
    return row == null ? null : _mapper.configVersionFromRow(row);
  }

  @override
  Future<List<AgentConfigVersion>> configVersionsForAgent(
    String workspaceId,
    String agentId,
  ) async => (await _dao(workspaceId).configVersionsForAgent(
    workspaceId,
    agentId,
  )).map(_mapper.configVersionFromRow).toList();

  @override
  Future<void> setConfigVersionStatus(
    String workspaceId,
    String id, {
    required String status,
    String? promotedBy,
    DateTime? promotedAt,
    String? scorecardJson,
  }) => _dao(workspaceId).setConfigVersionStatus(
    workspaceId,
    id,
    status: status,
    promotedBy: promotedBy,
    promotedAt: promotedAt,
    scorecardJson: scorecardJson,
  );
}
