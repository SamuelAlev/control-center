import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/pipeline_runs_table.dart';
import 'package:cc_persistence/database/tables/pipeline_step_runs_table.dart';
import 'package:drift/drift.dart';

part 'pipeline_dao.g.dart';

/// DAO for [PipelineRunsTable] and [PipelineStepRunsTable].
@DriftAccessor(tables: [PipelineRunsTable, PipelineStepRunsTable])
class PipelineDao extends DatabaseAccessor<AppDatabase>
    with _$PipelineDaoMixin {
  /// Creates a [PipelineDao].
  PipelineDao(super.db);

  // ── Pipeline runs ─────────────────────────────────────────────────

  /// Inserts a new pipeline run.
  Future<void> insertRun(PipelineRunsTableCompanion run) =>
      into(pipelineRunsTable).insert(run);

  /// Updates a pipeline run row.
  Future<void> updateRun(PipelineRunsTableCompanion run) =>
      update(pipelineRunsTable).replace(run);

  /// Gets a pipeline run by ID.
  Future<PipelineRunsTableData?> getRun(String id) =>
      (select(pipelineRunsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Watches a single pipeline run by ID.
  Stream<PipelineRunsTableData?> watchRun(String id) =>
      (select(pipelineRunsTable)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  /// Returns all non-terminal runs (pending, running, suspended).
  Future<List<PipelineRunsTableData>> nonTerminalRuns() =>
      (select(pipelineRunsTable)
            ..where((t) =>
                t.status.equals('pending') |
                t.status.equals('running') |
                t.status.equals('suspended')))
          .get();

  /// Returns the active (non-terminal) run matching `(templateId, workspaceId,
  /// dedupKey)`, or null. Used for trigger idempotency.
  Future<PipelineRunsTableData?> findActiveByDedupKey(
    String templateId,
    String workspaceId,
    String dedupKey,
  ) =>
      (select(pipelineRunsTable)
            ..where((t) =>
                t.templateId.equals(templateId) &
                t.workspaceId.equals(workspaceId) &
                t.dedupKey.equals(dedupKey) &
                (t.status.equals('pending') |
                    t.status.equals('running') |
                    t.status.equals('suspended'))))
          .getSingleOrNull();

  /// Watches **all pipeline runs across every workspace**, most recent first.
  ///
  /// CROSS-WORKSPACE BY DESIGN — for global/system surfaces only. Workspace
  /// surfaces must use [watchForWorkspace] with the active `workspaceId`.
  Stream<List<PipelineRunsTableData>> watchAll() =>
      (select(pipelineRunsTable)
            ..orderBy([
              (t) => OrderingTerm.desc(t.startedAt),
            ]))
          .watch();

  /// Watches runs for a specific workspace.
  Stream<List<PipelineRunsTableData>> watchForWorkspace(
          String workspaceId) =>
      (select(pipelineRunsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.startedAt),
            ]))
          .watch();

  /// Updates just the state JSON for a run.
  Future<void> updateRunState(String runId, String stateJson) async {
    await (update(pipelineRunsTable)..where((t) => t.id.equals(runId))).write(
      PipelineRunsTableCompanion(
        stateJson: Value(stateJson),
      ),
    );
  }

  /// Writes the run's aggregated cost columns only (so concurrent state merges
  /// aren't clobbered).
  Future<void> updateRunCost(
    String runId,
    int totalCostCents,
    int totalTokens,
  ) async {
    await (update(pipelineRunsTable)..where((t) => t.id.equals(runId))).write(
      PipelineRunsTableCompanion(
        totalCostCents: Value(totalCostCents),
        totalTokens: Value(totalTokens),
      ),
    );
  }

  /// Deletes a pipeline run, scoped to [workspaceId]. Its step runs are removed
  /// via the `ON DELETE CASCADE` on [PipelineStepRunsTable.pipelineRunId].
  /// Scoping by `workspaceId` means a run from another workspace is simply not
  /// matched (no cross-workspace delete). Returns the number of rows deleted.
  Future<int> deleteRun(String workspaceId, String runId) =>
      (delete(pipelineRunsTable)
            ..where((t) =>
                t.id.equals(runId) & t.workspaceId.equals(workspaceId)))
          .go();

  // ── Step runs ──────────────────────────────────────────────────────

  /// Inserts a new step run.
  Future<void> insertStepRun(PipelineStepRunsTableCompanion stepRun) =>
      into(pipelineStepRunsTable).insert(stepRun);

  /// Updates a step run's fields.
  Future<void> updateStepRun({
    required String id,
    String? status,
    String? inputJson,
    String? outputJson,
    String? channelId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async {
    await (update(pipelineStepRunsTable)..where((t) => t.id.equals(id)))
        .write(
      PipelineStepRunsTableCompanion(
        status: status != null ? Value(status) : const Value.absent(),
        inputJson:
            inputJson != null ? Value(inputJson) : const Value.absent(),
        outputJson:
            outputJson != null ? Value(outputJson) : const Value.absent(),
        channelId:
            channelId != null ? Value(channelId) : const Value.absent(),
        errorMessage:
            errorMessage != null ? Value(errorMessage) : const Value.absent(),
        errorStackTrace: errorStackTrace != null
            ? Value(errorStackTrace)
            : const Value.absent(),
        finishedAt:
            finishedAt != null ? Value(finishedAt) : const Value.absent(),
      ),
    );
  }

  /// Deletes a single step run row.
  Future<int> deleteStepRun(String stepRunId) =>
      (delete(pipelineStepRunsTable)..where((t) => t.id.equals(stepRunId)))
          .go();

  /// Returns all step runs for a pipeline run.
  Future<List<PipelineStepRunsTableData>> stepRunsForPipeline(
          String pipelineRunId) =>
      (select(pipelineStepRunsTable)
            ..where((t) => t.pipelineRunId.equals(pipelineRunId)))
          .get();

  /// Returns a single step run by ID, or null.
  Future<PipelineStepRunsTableData?> getStepRunById(String stepRunId) =>
      (select(pipelineStepRunsTable)
            ..where((t) => t.id.equals(stepRunId)))
          .getSingleOrNull();

  /// Watches all step runs for a pipeline run.
  Stream<List<PipelineStepRunsTableData>> watchStepRunsForPipeline(
          String pipelineRunId) =>
      (select(pipelineStepRunsTable)
            ..where((t) => t.pipelineRunId.equals(pipelineRunId)))
          .watch();
}
