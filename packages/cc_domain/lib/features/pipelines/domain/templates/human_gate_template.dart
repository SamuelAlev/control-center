import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_step_resume_listener.dart' show PipelineStepResumeListener;
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pipelines/domain/templates/dispatch_conversation_step.dart';

/// The schema a human-gate approver submits via `submit_output`: a clean
/// `{decision, reason}` so a downstream router can branch on `decision`
/// (`approved` / `rejected`).
const Map<String, dynamic> _approvalSchema = {
  'type': 'object',
  'properties': {
    'decision': {
      'type': 'string',
      'enum': ['approved', 'rejected'],
    },
    'reason': {'type': 'string'},
  },
  'required': ['decision'],
};

/// Registers the `human.gate` body — a first-class approval gate.
///
/// Conversation-first: it dispatches the approver agent (`config.agentId`) into
/// a hidden conversation with the gate prompt and a `{decision, reason}` output
/// contract, then suspends. The approver seeks the user's decision in-channel
/// and submits it via `submit_output`; the [PipelineStepResumeListener] resumes
/// the step and the engine harvests `{decision, reason}` under `outputKey` so a
/// downstream router can branch on `decision`.
void registerHumanGateBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required AgentRepository agentRepository,
  required MessagingPort messagingPort,
  required AgentDispatchPort agentDispatchPort,
  required StepProcessRegistry stepProcessRegistry,
  required PipelineRunRepository runRepository,
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
          state: ctx.renderState,
          trigger: ctx.triggerPayload,
        )
        .text;
    final gatePrompt = '$prompt\n\n'
        '── Approval required ─────────────────────────────\n'
        'Seek the user\'s decision, then submit it via `submit_output` with '
        '`{ "decision": "approved" | "rejected", "reason": "..." }`.';

    return dispatchConversationStep(
      ctx: ctx,
      messagingPort: messagingPort,
      agentDispatchPort: agentDispatchPort,
      stepProcessRegistry: stepProcessRegistry,
      runRepository: runRepository,
      agentIds: [approver.id],
      prompt: gatePrompt,
      label: config.label ?? 'Approval gate',
      outputSchema: config.outputSchema ?? _approvalSchema,
      mode: ConversationMode.review,
    );
  });
}
