import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/ports/ticket_workflow_port.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/template_renderer.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:uuid/uuid.dart';

/// Registers the `human.gate` body — a first-class approval gate built on the
/// existing ticket suspend/resume primitive.
///
/// It creates an approval ticket assigned to `config.agentId` (a human-proxy /
/// CEO / lead agent) with a `{decision, reason}` output contract and suspends.
/// The approver completes the ticket via the `approve_step` / `reject_step`
/// MCP tools; the engine resumes and merges `{decision, reason}` under
/// `outputKey` so a downstream router can branch on `decision`
/// (`approved` / `rejected`). The `TicketDispatcher` owns the channel + dispatch.
void registerHumanGateBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required AgentRepository agentRepository,
  required TicketWorkflowPort ticketWorkflow,
}) {
  const renderer = TemplateRenderer();

  registry.registerBody(BuiltInBodyKeys.humanGate, (ctx) async {
    final workspaceId = ctx.workspaceId;
    final def = await templateRepository.getById(workspaceId, ctx.templateId);
    final config = def?.step(ctx.stepId)?.config;
    if (config == null) {
      return StepResult.failed('humanGate: step "${ctx.stepId}" missing config');
    }
    final approverId = config.agentId;
    if (approverId == null || approverId.isEmpty) {
      return StepResult.failed(
        'humanGate: step "${ctx.stepId}" missing agentId (the approver)',
      );
    }
    final approver = await agentRepository.getById(approverId);
    if (approver == null) {
      return StepResult.failed('humanGate: approver "$approverId" not found');
    }

    final prompt = renderer
        .render(
          config.prompt ?? 'Approve or reject this pipeline step.',
          state: ctx.state,
          trigger: ctx.triggerPayload,
        )
        .text;

    // No object schema here: the approve_step / reject_step tools write a
    // clean `{result: 'approved'|'rejected'}` which the engine harvests into a
    // plain string under outputKey, so a downstream router can switch on it.
    final ticketId = const Uuid().v4();
    final description = '$prompt\n\n'
        '── Approval required ─────────────────────────────\n'
        'Call `approve_step` or `reject_step` with ticket_id="$ticketId".';
    await ticketWorkflow.createTicket(
      id: ticketId,
      pipelineRunId: ctx.pipelineRunId,
      pipelineStepId: ctx.stepId,
      workspaceId: workspaceId,
      title: config.label ?? 'Approval gate',
      description: description,
      assignedAgentId: approver.id,
      mode: ConversationMode.review,
    );

    return StepResult.suspendUntilTasksComplete([ticketId]);
  });
}
