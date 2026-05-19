import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';

/// Port that decouples `SubPipelineLauncher` from the concrete `PipelineEngine`
/// implementation, breaking the circular dependency between the engine and the
/// body registry.
abstract interface class PipelineEnginePort {
  /// Starts a pipeline run for the given [templateId].
  Future<PipelineRun?> start(
    String templateId, {
    required String workspaceId,
    String? triggerEventType,
    Map<String, dynamic>? triggerPayload,
    String? dedupKey,
    String? parentPipelineRunId,
    String? parentStepId,
    bool dryRun = false,
  });

  /// Resumes every interrupted run (called on startup).
  Future<void> resumeAll();

  /// Cancels an in-flight pipeline run.
  Future<void> cancel(String pipelineRunId);

  /// Kills a single in-flight step's live work.
  Future<void> killStep(String stepRunId);

  /// Retries a failed pipeline run from its failed step.
  Future<void> retry(String pipelineRunId);
}
