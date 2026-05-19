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
  Future<PipelineRun?> getRun(String id);

  /// Watches a single pipeline run by ID, emitting on every change.
  Stream<PipelineRun?> watchRun(String id);

  /// Updates the state JSON for a pipeline run.
  Future<void> updateRunState(String runId, Map<String, dynamic> state);

  /// Adds [cents] and [tokens] to the run's aggregated cost totals.
  Future<void> incrementCost(String runId, int cents, int tokens);

  /// Returns all non-terminal runs (for resume on startup).
  Future<List<PipelineRun>> nonTerminalRuns();

  /// Watches all pipeline runs ordered by most recent first.
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

  /// Inserts a new step run.
  Future<void> insertStepRun(PipelineStepRun stepRun);

  /// Updates a step run's status and optional fields.
  Future<void> updateStepRun(
    String stepRunId, {
    PipelineStepStatus? status,
    String? inputJson,
    String? outputJson,
    String? channelId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  });

  /// Deletes a single step run row.
  Future<void> deleteStepRun(String stepRunId);

  /// Returns all step runs for a pipeline run.
  Future<List<PipelineStepRun>> stepRunsForPipeline(String pipelineRunId);

  /// Returns a single step run by its ID, or null.
  Future<PipelineStepRun?> getStepRunById(String stepRunId);

  /// Watches all step runs for a pipeline run.
  Stream<List<PipelineStepRun>> watchStepRunsForPipeline(String pipelineRunId);
}
