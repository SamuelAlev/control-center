import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pipelines/domain/templates/dispatch_conversation_step.dart';

/// Registers the `flow.forEach` body — map/fan-out over a state collection.
///
/// Reads `extras.iterableKey` from state (a list), and for each item dispatches
/// the agent into its own hidden conversation with the item bound to
/// `extras.itemKey` (default `item`) in the prompt. Suspends until all per-item
/// runs finish; the engine harvests the outputs into a list under `outputKey`.
void registerForEachBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required AgentRepository agentRepository,
  required MessagingPort messagingPort,
  required AgentDispatchPort agentDispatchPort,
  required StepProcessRegistry stepProcessRegistry,
  required PipelineRunRepository runRepository,
}) {
  const renderer = TemplateRenderer();

  registry.registerBody(BuiltInBodyKeys.forEach, (ctx) async {
    final workspaceId = ctx.workspaceId;
    final def = await templateRepository.getById(workspaceId, ctx.templateId);
    final config = def?.step(ctx.stepId)?.config;
    if (config == null) {
      return StepResult.failed('forEach: step "${ctx.stepId}" missing config');
    }
    final agentId = config.agentId;
    if (agentId == null || agentId.isEmpty) {
      return StepResult.failed('forEach: step "${ctx.stepId}" missing agentId');
    }
    if (config.prompt == null || config.prompt!.isEmpty) {
      return StepResult.failed('forEach: step "${ctx.stepId}" missing prompt');
    }
    final iterableKey = config.extras['iterableKey'] as String?;
    if (iterableKey == null || iterableKey.isEmpty) {
      return StepResult.failed('forEach: step "${ctx.stepId}" missing extras.iterableKey');
    }
    final itemKey = config.extras['itemKey'] as String? ?? 'item';

    final raw = ctx.state[iterableKey] ?? ctx.triggerPayload?[iterableKey];
    final items = raw is List ? raw : (raw == null ? const [] : [raw]);
    if (items.isEmpty) {
      // Nothing to iterate — complete immediately with an empty list.
      return StepResult.ok(mutatedState: {
        if (config.outputKey != null) config.outputKey!: <dynamic>[],
      });
    }

    final agent = await agentRepository.getById(agentId);
    if (agent == null) {
      return StepResult.failed('forEach: agent "$agentId" not found');
    }

    final renderedPrompts = <String>[];
    for (var i = 0; i < items.length; i++) {
      final perItemState = <String, dynamic>{
        ...ctx.renderState,
        itemKey: items[i],
      };
      final rendered = renderer
          .render(config.prompt!, state: perItemState, trigger: ctx.triggerPayload)
          .text;
      renderedPrompts.add(rendered);
    }

    final result = await dispatchConversationStep(
      ctx: ctx,
      messagingPort: messagingPort,
      agentDispatchPort: agentDispatchPort,
      stepProcessRegistry: stepProcessRegistry,
      runRepository: runRepository,
      agentIds: [agent.id],
      prompt: renderedPrompts.join('\n\n---\n\n'),
      label: config.label ?? ctx.stepId,
      outputSchema: config.outputSchema,
      mode: ConversationMode.review,
    );
    return result;
  });
}
