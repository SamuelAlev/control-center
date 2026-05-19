import 'package:control_center/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_engine.dart' show PipelineEngine;
import 'package:control_center/features/pipelines/domain/services/sub_pipeline_launcher.dart' show SubPipelineLauncher;

/// Port that decouples [SubPipelineLauncher] from the concrete [PipelineEngine]
/// implementation, breaking the circular dependency between the engine and the
/// body registry.
abstract interface class PipelineEnginePort {
  /// Starts a pipeline run for the given [templateId].
  Future<PipelineRun?> start(
    String templateId, {
    required String workspaceId,
    Map<String, dynamic>? triggerPayload,
    String? parentPipelineRunId,
    String? parentStepId,
    bool dryRun = false,
  });
}
