import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';

/// Repository interface for persisting pipeline runs and step runs.
abstract class PipelineRunRepository {
  /// Inserts a new pipeline run.
  Future<void> insertRun(PipelineRun run);

  /// Updates an existing pipeline run's LIFECYCLE: status, the timing fields,
  /// the error pair and the run's identity columns.
  ///
  /// [PipelineRun.state], [PipelineRun.totalCostCents] and
  /// [PipelineRun.totalTokens] on the passed object are ignored. Those three
  /// have single-purpose writers ([updateRunState], [incrementCost]) that run
  /// CONCURRENTLY with every transition — a fan-out's agents publish their cost
  /// as the run completes, and a parallel branch merges state while another is
  /// failing. A transition that also wrote them would write the values as they
  /// stood when the caller last read the run, silently reverting whatever
  /// landed in between.
  ///
  /// Write state through [updateRunState] and cost through [incrementCost].
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

  /// Number of runs of [templateId] currently occupying one of the template's
  /// `maxParallelRuns` slots — everything non-terminal except `queued`, which
  /// is by definition what is *waiting* for a slot.
  ///
  /// Rows whose `triggerEventType` is in [excludeTriggerEventTypes] are not
  /// counted. Callers pass the projection markers there: those rows mirror work
  /// the engine does not own, so a slot they held would never be released.
  Future<int> activeRunCountForTemplate({
    required String workspaceId,
    required String templateId,
    Set<String> excludeTriggerEventTypes = const {},
  });

  /// The oldest `queued` run of [templateId] (FIFO by `startedAt`), or null
  /// when nothing is waiting. Used by `PipelineEngine` to admit the next run
  /// as a slot frees.
  Future<PipelineRun?> nextQueuedRunForTemplate({
    required String workspaceId,
    required String templateId,
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
    String? spaceId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  });

  /// Re-opens an existing step run for another attempt, scoped to
  /// [workspaceId]: status back to `running`, [startedAt] re-stamped and the
  /// previous attempt's outcome (`finishedAt`, error message, error stack,
  /// output) cleared.
  ///
  /// The row id is deliberately kept — the step process registry, the agent run
  /// logs and the UI's selection all address it — but its timestamps must move,
  /// or a step re-fired by a crash-resume keeps reporting the FIRST attempt's
  /// start while its agent is minutes into the second one. `updateStepRun`
  /// cannot express this: every one of its parameters is "leave alone when
  /// null", which is exactly the opposite of what clearing needs.
  ///
  /// The row's `spaceId` is NOT touched: the conversation a step already opened
  /// is the one the next attempt reuses (`dispatchConversationStep` reads it
  /// back), so forgetting it here is what mints a duplicate room.
  Future<void> restartStepRun(
    String workspaceId,
    String stepRunId, {
    required DateTime startedAt,
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
