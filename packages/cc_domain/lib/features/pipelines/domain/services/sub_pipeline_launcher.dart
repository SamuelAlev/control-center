import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart';

/// Late-bound bridge that lets the `flow.callPipeline` body start a child run
/// without the body registry depending on the engine (the engine depends on
/// the registry, so the cycle is broken by setting [engine] after the engine
/// is constructed).
class SubPipelineLauncher {
  /// The engine port, wired in by the composition root after construction.
  PipelineEnginePort? engine;

  /// Starts a child run parented to [parentPipelineRunId]/[parentStepId].
  Future<PipelineRun?> startChild(
    String templateId, {
    required String workspaceId,
    Map<String, dynamic>? triggerPayload,
    required String parentPipelineRunId,
    required String parentStepId,
    bool dryRun = false,
  }) {
    final e = engine;
    if (e == null) {
      throw StateError('SubPipelineLauncher used before the engine was wired');
    }
    return e.start(
      templateId,
      workspaceId: workspaceId,
      triggerPayload: triggerPayload,
      parentPipelineRunId: parentPipelineRunId,
      parentStepId: parentStepId,
      dryRun: dryRun,
    );
  }
}
