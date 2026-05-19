import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';

/// Repository interface for persisting pipeline runs and step runs.
abstract class PipelineRunRepository {
  /// Inserts a new pipeline run.
  Future<void> insertRun(PipelineRun run);

  /// Updates an existing pipeline run.
  Future<void> updateRun(PipelineRun run);

  /// Gets a pipeline run by ID.
  ///
  /// The id is enough on purpose: a run is reached from deep links, worker
  /// callbacks and lifecycle events that carry only `pipelineRunId`.
  /// Implementations resolve the owning workspace from the id and must not
  /// search workspaces they were not pointed at. Returns null for an unknown id.
  Future<PipelineRun?> getRun(String id);

  /// Watches a single pipeline run by ID, emitting on every change.
  ///
  /// Resolves the owning workspace from the id, like [getRun].
  Stream<PipelineRun?> watchRun(String id);

  /// Updates the state JSON for a pipeline run.
  Future<void> updateRunState(String runId, Map<String, dynamic> state);

  /// Adds [cents] and [tokens] to the run's aggregated cost totals.
  Future<void> incrementCost(String runId, int cents, int tokens);

  /// Returns all non-terminal runs, across every workspace, for resume on
  /// startup — the reconciler runs before any workspace is chosen.
  Future<List<PipelineRun>> nonTerminalRuns();

  /// Watches all pipeline runs across every workspace, most recent first — the
  /// operator's all-workspace view. Workspace surfaces use [watchForWorkspace].
  Stream<List<PipelineRun>> watchAll();

  /// Watches runs for a specific workspace.
  Stream<List<PipelineRun>> watchForWorkspace(String workspaceId);

  /// Returns the active non-terminal run for `(templateId, workspaceId,
  /// dedupKey)`, or null. Used by `PipelineEngine.start` to enforce trigger
  /// idempotency.
  Future<PipelineRun?> activeForDedupKey({
    required String templateId,
    required String workspaceId,
    required String dedupKey,
  });

  /// Deletes a pipeline run (and its step runs via cascade), scoped to
  /// [workspaceId]. A run belonging to another workspace is not matched.
  Future<void> deleteRun(String workspaceId, String runId);

  /// Inserts a new step run. Its owning workspace is that of
  /// [PipelineStepRun.pipelineRunId].
  Future<void> insertStepRun(PipelineStepRun stepRun);

  /// Updates a step run's status and optional fields, scoped to [workspaceId].
  ///
  /// A step-run id names nothing on its own — unlike a run id it is not
  /// routable to a workspace — so the caller supplies the workspace it belongs
  /// to. A step run owned by another workspace is not matched.
  Future<void> updateStepRun(
    String workspaceId,
    String stepRunId, {
    PipelineStepStatus? status,
    String? inputJson,
    String? outputJson,
    String? channelId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  });

  /// Deletes a single step run row, scoped to [workspaceId].
  Future<void> deleteStepRun(String workspaceId, String stepRunId);

  /// Returns all step runs for a pipeline run, whose workspace is resolved from
  /// [pipelineRunId]. Empty when the run is unknown.
  Future<List<PipelineStepRun>> stepRunsForPipeline(String pipelineRunId);

  /// Returns a single step run by its ID within [workspaceId], or null.
  Future<PipelineStepRun?> getStepRunById(String workspaceId, String stepRunId);

  /// Watches all step runs for a pipeline run, whose workspace is resolved from
  /// [pipelineRunId].
  Stream<List<PipelineStepRun>> watchStepRunsForPipeline(String pipelineRunId);
}
