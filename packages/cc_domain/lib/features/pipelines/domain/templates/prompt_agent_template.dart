import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pipelines/domain/templates/dispatch_conversation_step.dart';

/// Registers the generic `pipeline.promptAgent` body.
///
/// Every "prompt-style" node (built-in reviewers, consolidation, and any
/// custom user-authored node) routes through this body. The body:
///
/// 1. Resolves the step's [PipelineNodeConfig] from the template repository.
/// 2. Substitutes `{{key}}` placeholders in `config.prompt` against
///    pipeline state + trigger payload.
/// 3. Fetches the agent referenced by `config.agentId` directly — no role
///    or skill matching.
/// 4. Dispatches into a hidden conversation via [dispatchConversationStep]
///    (the prompt + output-contract footer are posted; the agent is dispatched
///    with the output contract stamped onto its run).
/// 5. Suspends the step until the dispatched run finishes.
///
/// The engine harvests the run's `submit_output` payload into pipeline state
/// under `config.outputKey` so downstream nodes can read the result.
void registerPromptAgentBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required AgentRepository agentRepository,
  required MessagingPort messagingPort,
  required AgentDispatchPort agentDispatchPort,
  required StepProcessRegistry stepProcessRegistry,
  required PipelineRunRepository runRepository,
}) {
  registry.registerBody(BuiltInBodyKeys.promptAgent, (ctx) async {
    final stepConfig = await _resolveStepConfig(
      templateRepository,
      ctx.templateId,
      ctx.stepId,
      ctx.workspaceId,
    );
    if (stepConfig == null) {
      return StepResult.failed(
        'promptAgent: step "${ctx.stepId}" missing config',
      );
    }
    if (stepConfig.prompt == null || stepConfig.prompt!.isEmpty) {
      return StepResult.failed(
        'promptAgent: step "${ctx.stepId}" missing prompt template',
      );
    }
    final agentId = stepConfig.agentId;
    if (agentId == null || agentId.isEmpty) {
      return StepResult.failed(
        'promptAgent: step "${ctx.stepId}" missing agentId',
      );
    }

    final agent = await agentRepository.getById(agentId);
    if (agent == null) {
      return StepResult.failed('promptAgent: agent "$agentId" not found');
    }

    final renderResult = _renderer.render(
      stepConfig.prompt!,
      state: ctx.renderState,
      trigger: ctx.triggerPayload,
    );
    if (!renderResult.isComplete) {
      final allowUnresolved =
          stepConfig.extras['allowUnresolvedPlaceholders'] == true;
      if (!allowUnresolved) {
        return StepResult.failed(
          'promptAgent: step "${ctx.stepId}" prompt has unresolved '
          'placeholders: ${renderResult.unresolved.join(', ')}',
        );
      }
      CcDomainLog.warning('promptAgent: Step "${ctx.stepId}" prompt has unresolved placeholders: '
        '${renderResult.unresolved.join(', ')} — rendering empty '
        '(allowUnresolvedPlaceholders is set).',
      );
    }
    final rendered = renderResult.text;

    return dispatchConversationStep(
      ctx: ctx,
      messagingPort: messagingPort,
      agentDispatchPort: agentDispatchPort,
      stepProcessRegistry: stepProcessRegistry,
      runRepository: runRepository,
      agentIds: [agent.id],
      prompt: rendered,
      label: stepConfig.label,
      outputSchema: stepConfig.outputSchema,
      mode: _resolveConversationMode(stepConfig),
    );
  });
}

/// Walks the template to find a step's config so the body can read its
/// prompt/role/I/O even though `PipelineContext` only carries IDs.
Future<PipelineNodeConfig?> _resolveStepConfig(
  PipelineTemplateRepository repo,
  String templateId,
  String stepId,
  String workspaceId,
) async {
  final def = await repo.getById(workspaceId, templateId);
  return def?.step(stepId)?.config;
}

const TemplateRenderer _renderer = TemplateRenderer();

ConversationMode _resolveConversationMode(PipelineNodeConfig config) {
  final raw = config.extras['mode'] as String?;
  return switch (raw) {
    'review' => ConversationMode.review,
    'plan' => ConversationMode.plan,
    _ => ConversationMode.review,
  };
}
