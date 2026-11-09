import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/sub_pipeline_launcher.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// How deep `flow.callPipeline` may nest: a run plus this many ancestors. A
/// cycle across templates (A calls B calls A) is refused outright; this bounds
/// a legitimate but runaway chain of distinct templates.
const int kMaxSubPipelineDepth = 8;

/// The dedup key a `flow.callPipeline` step starts its child with. One active
/// child per calling step: a crash-resume or retry that re-fires the step
/// re-attaches to the child already running instead of starting a second one.
String callFlowDedupKey(String parentRunId, String parentStepId) =>
    'callFlow:$parentRunId:$parentStepId';

/// Registers the `flow.callPipeline` body — runs another pipeline template as a
/// nested sub-step and merges its final state back under `outputKey`.
///
/// Config: `extras.templateId` names the child template; `inputKeys` are copied
/// from this run's state into the child's trigger payload. The step suspends
/// until the child reaches a terminal state, at which point the
/// `SubPipelineResumeListener` calls back into the engine to merge the child's
/// final state and continue.
///
/// The config is the pinned step's (`PipelineContext.step`). A call whose
/// target already runs somewhere up this run's ancestry is a cycle and fails,
/// as does nesting deeper than [kMaxSubPipelineDepth].
void registerCallFlowBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required PipelineRunReader runRepository,
  required SubPipelineLauncher launcher,
}) {
  registry.registerBody(BuiltInBodyKeys.callFlow, (ctx) async {
    final workspaceId = ctx.workspaceId;
    final config = await ctx.pinnedStepConfig(templateRepository);
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

    // Walk the ancestry: the target must not already be running above us.
    var depth = 1;
    String? ancestorId = (await runRepository.getRun(
      ctx.pipelineRunId,
    ))?.parentPipelineRunId;
    while (ancestorId != null) {
      final ancestor = await runRepository.getRun(ancestorId);
      if (ancestor == null || ancestor.workspaceId != workspaceId) {
        break;
      }
      if (ancestor.templateId == targetTemplateId) {
        return StepResult.failed(
          'callFlow: "$targetTemplateId" is already running above this step '
          '(${ctx.templateId} is its descendant) — a sub-pipeline cycle',
        );
      }
      depth++;
      if (depth >= kMaxSubPipelineDepth) {
        return StepResult.failed(
          'callFlow: sub-pipelines nest more than $kMaxSubPipelineDepth deep',
        );
      }
      ancestorId = ancestor.parentPipelineRunId;
    }

    final dedupKey = callFlowDedupKey(ctx.pipelineRunId, ctx.stepId);
    final existing = await runRepository.activeForDedupKey(
      templateId: targetTemplateId,
      workspaceId: workspaceId,
      dedupKey: dedupKey,
    );
    if (existing != null) {
      // Re-fired (resume / retry) while the child is still going: wait on it.
      return StepResult.suspendUntilEvent('childFlow:${existing.id}');
    }

    // Build the child trigger payload from declared input keys.
    final childPayload = <String, dynamic>{};
    for (final key in config.inputKeys) {
      final v = ctx.state[key] ?? ctx.triggerPayload?[key];
      if (v != null) {
        childPayload[key] = v;
      }
    }

    final child = await launcher.startChild(
      targetTemplateId,
      workspaceId: workspaceId,
      triggerPayload: childPayload,
      parentPipelineRunId: ctx.pipelineRunId,
      parentStepId: ctx.stepId,
      dedupKey: dedupKey,
      dryRun: ctx.dryRun,
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
