import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/sub_pipeline_launcher.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// Registers the `flow.callPipeline` body — runs another pipeline template as a
/// nested sub-step and merges its final state back under `outputKey`.
///
/// Config: `extras.templateId` names the child template; `inputKeys` are copied
/// from this run's state into the child's trigger payload. The step suspends
/// until the child reaches a terminal state, at which point the
/// `SubPipelineResumeListener` calls back into the engine to merge the child's
/// final state and continue.
void registerCallFlowBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required SubPipelineLauncher launcher,
}) {
  registry.registerBody(BuiltInBodyKeys.callFlow, (ctx) async {
    final workspaceId = ctx.workspaceId;
    final def = await templateRepository.getById(workspaceId, ctx.templateId);
    final config = def?.step(ctx.stepId)?.config;
    if (config == null) {
      return StepResult.failed('callFlow: step "${ctx.stepId}" missing config');
    }
    final targetTemplateId = config.extras['templateId'] as String?;
    if (targetTemplateId == null || targetTemplateId.isEmpty) {
      return StepResult.failed(
        'callFlow: step "${ctx.stepId}" missing extras.templateId',
      );
    }
    if (targetTemplateId == ctx.templateId) {
      return StepResult.failed('callFlow: a pipeline cannot call itself');
    }

    // Build the child trigger payload from declared input keys.
    final childPayload = <String, dynamic>{};
    for (final key in config.inputKeys) {
      final v = ctx.state[key] ?? ctx.triggerPayload?[key];
      if (v != null) childPayload[key] = v;
    }

    final child = await launcher.startChild(
      targetTemplateId,
      workspaceId: workspaceId,
      triggerPayload: childPayload,
      parentPipelineRunId: ctx.pipelineRunId,
      parentStepId: ctx.stepId,
    );
    if (child == null) {
      return StepResult.failed(
        'callFlow: child template "$targetTemplateId" could not start '
        '(disabled or deduplicated)',
      );
    }

    // Suspend; SubPipelineResumeListener resumes via engine.resumeChildFlow
    // when the child run reaches a terminal state.
    return StepResult.suspendUntilEvent('childFlow:${child.id}');
  });
}
