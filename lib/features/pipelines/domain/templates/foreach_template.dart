import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/ports/ticket_workflow_port.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/template_renderer.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:uuid/uuid.dart';
/// Registers the `flow.forEach` body — map/fan-out over a state collection.
///
/// Reads `extras.iterableKey` from state (a list), and for each item creates
/// one agent ticket with the item bound to `extras.itemKey` (default `item`) in
/// the prompt. Suspends until all per-item tickets finish; the engine harvests
/// the outputs into a list under `outputKey` (set `reducer: 'append'`). The
/// `TicketDispatcher` owns the channel + dispatch (one shared channel per run).
void registerForEachBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required AgentRepository agentRepository,
  required TicketWorkflowPort ticketWorkflow,
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

    final ticketIds = <String>[];
    for (var i = 0; i < items.length; i++) {
      final perItemState = <String, dynamic>{
        ...ctx.renderState,
        itemKey: items[i],
      };
      final rendered = renderer
          .render(config.prompt!, state: perItemState, trigger: ctx.triggerPayload)
          .text;
      final ticketId = const Uuid().v4();
      final description = '$rendered\n\n'
          '── Pipeline coordination ─────────────────────────────\n'
          'When done, call `complete_ticket` with ticket_id="$ticketId".';
      await ticketWorkflow.createTicket(
        id: ticketId,
        pipelineRunId: ctx.pipelineRunId,
        pipelineStepId: ctx.stepId,
        workspaceId: workspaceId,
        title: '${config.label ?? ctx.stepId} [$i]',
        description: description,
        assignedAgentId: agent.id,
        mode: ConversationMode.review,
        expectedOutputSchema: config.outputSchema,
      );
      ticketIds.add(ticketId);
    }

    return StepResult.suspendUntilTasksComplete(ticketIds);
  });
}
