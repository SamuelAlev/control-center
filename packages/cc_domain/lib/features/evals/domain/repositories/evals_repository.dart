import 'package:cc_domain/features/evals/domain/entities/evals_entities.dart';

/// Persistence contract for agent evals, replay & regression (PRD 21).
///
/// Every method is workspace-scoped (workspace isolation invariant): reads
/// filter by `workspaceId` and writes carry it.
abstract interface class EvalsRepository {
  // ── Session recordings ──

  /// Inserts or replaces a recording.
  Future<void> upsertRecording(SessionRecording recording);

  /// One recording by id within [workspaceId], or null.
  Future<SessionRecording?> recordingById(String workspaceId, String id);

  /// The recording for a run log within [workspaceId], or null.
  Future<SessionRecording?> recordingByRunLog(
    String workspaceId,
    String runLogId,
  );

  /// Recordings in [workspaceId], newest first.
  Future<List<SessionRecording>> recordings(
    String workspaceId, {
    String? agentId,
    int limit,
  });

  /// Live recordings in [workspaceId].
  Stream<List<SessionRecording>> watchRecordings(String workspaceId);

  /// Prunes recordings older than [cutoff] within [workspaceId] (retention).
  Future<int> pruneRecordings(String workspaceId, DateTime cutoff);

  // ── Golden sessions ──

  /// Inserts or replaces a golden.
  Future<void> upsertGolden(GoldenSession golden);

  /// One golden by id within [workspaceId], or null.
  Future<GoldenSession?> goldenById(String workspaceId, String id);

  /// Enabled goldens for [agentId] within [workspaceId].
  Future<List<GoldenSession>> goldensForAgent(
    String workspaceId,
    String agentId,
  );

  /// All goldens in [workspaceId].
  Future<List<GoldenSession>> goldens(String workspaceId);

  /// Live goldens in [workspaceId].
  Stream<List<GoldenSession>> watchGoldens(String workspaceId);

  /// Records the last golden run result within [workspaceId].
  Future<void> updateGoldenResult(
    String workspaceId,
    String id,
    String status,
    String? scorecardJson,
  );

  /// Deletes a golden within [workspaceId].
  Future<void> deleteGolden(String workspaceId, String id);

  // ── Eval suites ──

  /// Inserts or replaces a suite.
  Future<void> upsertSuite(EvalSuite suite);

  /// One suite by id within [workspaceId], or null.
  Future<EvalSuite?> suiteById(String workspaceId, String id);

  /// One suite by name within [workspaceId], or null.
  Future<EvalSuite?> suiteByName(String workspaceId, String name);

  /// Suites in [workspaceId].
  Future<List<EvalSuite>> suites(String workspaceId);

  /// Live suites in [workspaceId].
  Stream<List<EvalSuite>> watchSuites(String workspaceId);

  /// Deletes a suite within [workspaceId].
  Future<void> deleteSuite(String workspaceId, String id);

  // ── Eval runs ──

  /// Inserts or replaces an eval run.
  Future<void> upsertRun(EvalRun run);

  /// One run by id within [workspaceId], or null.
  Future<EvalRun?> runById(String workspaceId, String id);

  /// Runs for [suiteId] within [workspaceId], newest first.
  Future<List<EvalRun>> runsForSuite(
    String workspaceId,
    String suiteId, {
    int limit,
  });

  /// Live runs for [suiteId] within [workspaceId].
  Stream<List<EvalRun>> watchRunsForSuite(String workspaceId, String suiteId);

  /// Marks a run's result within [workspaceId].
  Future<void> updateRunResult(
    String workspaceId,
    String id, {
    required String status,
    String? scorecardJson,
    double? passRate,
    int? costCents,
    DateTime? startedAt,
    DateTime? finishedAt,
  });

  // ── Agent config versions ──

  /// Inserts or replaces a config version.
  Future<void> upsertConfigVersion(AgentConfigVersion version);

  /// The live config version for [agentId] within [workspaceId], or null.
  Future<AgentConfigVersion?> liveConfigVersion(
    String workspaceId,
    String agentId,
  );

  /// A config version by (agent, hash) within [workspaceId], or null.
  Future<AgentConfigVersion?> configVersionByHash(
    String workspaceId,
    String agentId,
    String configHash,
  );

  /// All config versions for [agentId] within [workspaceId], newest first.
  Future<List<AgentConfigVersion>> configVersionsForAgent(
    String workspaceId,
    String agentId,
  );

  /// Sets a config version's status within [workspaceId] (promote/retire).
  Future<void> setConfigVersionStatus(
    String workspaceId,
    String id, {
    required String status,
    String? promotedBy,
    DateTime? promotedAt,
    String? scorecardJson,
  });
}
