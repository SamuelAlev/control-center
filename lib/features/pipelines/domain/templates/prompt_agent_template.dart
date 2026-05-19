import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/ports/ticket_workflow_port.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/step_process_registry.dart';
import 'package:control_center/features/pipelines/domain/services/template_renderer.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:uuid/uuid.dart';
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
/// 4. Creates a ticket tied to `(pipelineRunId, stepId)`, assigned to the
///    agent, with the rendered prompt + coordination footer as its description.
/// 5. Suspends the step.
///
/// It does **not** open a channel, start, or dispatch the agent: the
/// `TicketDispatcher` owns that single path (readiness → channel → start →
/// dispatch) off the `TicketAssigned` event the ticket creation publishes, and
/// the `TicketResumeListener` resumes this step once the ticket is terminal.
///
/// The engine merges any ticket `outputJson` into pipeline state under
/// `config.outputKey` so downstream nodes can read the result.
void registerPromptAgentBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required AgentRepository agentRepository,
  required TicketWorkflowPort ticketWorkflow,
  required StepProcessRegistry stepProcessRegistry,
  required AgentDispatchPort agentDispatchPort,
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
    final workspaceId = ctx.workspaceId;
    final agentId = stepConfig.agentId;
    if (agentId == null || agentId.isEmpty) {
      return StepResult.failed(
        'promptAgent: step "${ctx.stepId}" missing agentId',
      );
    }

    final agent = await agentRepository.getById(agentId);
    if (agent == null) {
      return StepResult.failed(
        'promptAgent: agent "$agentId" not found',
      );
    }

    final renderResult = _renderer.render(
      stepConfig.prompt!,
      state: ctx.renderState,
      trigger: ctx.triggerPayload,
    );
    if (!renderResult.isComplete) {
      // An unresolved `{{key}}` would silently send a truncated prompt to the
      // agent — fail the step so the misconfiguration surfaces. Nodes with
      // genuinely-optional placeholders opt out via
      // `extras['allowUnresolvedPlaceholders'] == true`.
      final allowUnresolved =
          stepConfig.extras['allowUnresolvedPlaceholders'] == true;
      if (!allowUnresolved) {
        return StepResult.failed(
          'promptAgent: step "${ctx.stepId}" prompt has unresolved '
          'placeholders: ${renderResult.unresolved.join(', ')}',
        );
      }
      AppLog.w(
        'promptAgent',
        'Step "${ctx.stepId}" prompt has unresolved placeholders: '
        '${renderResult.unresolved.join(', ')} — rendering empty '
        '(allowUnresolvedPlaceholders is set).',
      );
    }
    final rendered = renderResult.text;

    // Dry run: don't create a ticket; echo what would have happened.
    if (ctx.dryRun) {
      final outputKey = stepConfig.outputKey;
      return StepResult.ok(mutatedState: {
        if (outputKey != null && outputKey.isNotEmpty)
          outputKey: '[dry-run] agent "${agent.name}" dispatch skipped',
      });
    }

    final ticketId = const Uuid().v4();
    final outputSchema = stepConfig.outputSchema;
    // When the node declares an output schema, the contract block (rendered by
    // the dispatcher from `expectedOutputSchema`) tells the agent the exact
    // payload shape — so we must NOT also suggest a `{ "result": ... }` wrapper,
    // which contradicts the schema.
    final payloadHint = outputSchema != null
        ? 'and your findings in the `output` payload matching the output '
            'contract shown above'
        : 'and your findings in the `output` payload '
            '(`{ "result": "<markdown body>" }`)';
    final description = '$rendered\n\n'
        '── Pipeline coordination ─────────────────────────────\n'
        'When you finish, call the `complete_ticket` MCP tool with '
        'ticket_id="$ticketId" $payloadHint. If the task cannot be completed, '
        'call `fail_ticket` with ticket_id="$ticketId" instead. The pipeline '
        'resumes automatically once the ticket reaches a terminal state.';

    await ticketWorkflow.createTicket(
      id: ticketId,
      pipelineRunId: ctx.pipelineRunId,
      pipelineStepId: ctx.stepId,
      workspaceId: workspaceId,
      title: stepConfig.label ?? ctx.stepId,
      description: description,
      assignedAgentId: agent.id,
      mode: _resolveConversationMode(stepConfig),
      expectedOutputSchema: outputSchema,
      channelId: _extraString(stepConfig, 'channelId'),
      parentTicketId: _extraString(stepConfig, 'parentTicketId'),
      projectId: _extraString(stepConfig, 'projectId'),
    );

    // Expose a kill hook so the UI Stop button can cancel only this agent's
    // dispatches without affecting other agents' concurrent pipeline steps.
    stepProcessRegistry.register(ctx.stepRunId, () async {
      try {
        await ticketWorkflow.cancelTicket(ticketId, workspaceId: workspaceId);
      } on Object catch (e, st) {
        AppLog.e('promptAgent', 'cancelTicket failed', e, st);
      }
      try {
        await agentDispatchPort.stopAllForAgent(agent.id);
      } on Object catch (e, st) {
        AppLog.e('promptAgent', 'stopAllForAgent failed', e, st);
      }
    });

    return StepResult.suspendUntilTasksComplete([ticketId]);
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

/// Reads a non-empty string from a node's `extras` bag, or null.
String? _extraString(PipelineNodeConfig config, String key) {
  final v = config.extras[key];
  return (v is String && v.isNotEmpty) ? v : null;
}

ConversationMode _resolveConversationMode(PipelineNodeConfig config) {
  final raw = config.extras['conversationMode'];
  if (raw is String) {
    return ConversationMode.values.where((m) => m.name == raw).firstOrNull ??
        ConversationMode.review;
  }
  return ConversationMode.review;
}
