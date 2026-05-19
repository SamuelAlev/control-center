import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/output_contract_prompt.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_step_resume_listener.dart' show PipelineStepResumeListener;
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';

/// Shared execution primitive for the "message step" bodies (promptAgent,
/// teamDispatch, forEach, human.gate). Conversation-first: instead of creating
/// an agent-assigned ticket, it spins up a **hidden** conversation, posts the
/// rendered prompt (+ the output-contract footer), dispatches each agent into
/// it (stamping the contract onto the created run), and suspends the step until
/// those runs finish. The [PipelineStepResumeListener] advances the step once
/// every run is terminal; the engine harvests each run's `outputJson`.
///
/// Returns a [StepResult.suspendUntilTasksComplete] carrying the dispatched
/// run ids (the new "tasks"), or [StepResult.failed] on a misconfiguration.
Future<StepResult> dispatchConversationStep({
  required PipelineContext ctx,
  required MessagingPort messagingPort,
  required AgentDispatchPort agentDispatchPort,
  required StepProcessRegistry stepProcessRegistry,
  required PipelineRunRepository runRepository,
  required List<String> agentIds,
  required String prompt,
  String? label,
  Map<String, dynamic>? outputSchema,
  OutputContractMode outputContractMode = OutputContractMode.strict,
  ConversationMode mode = ConversationMode.review,
  Map<String, dynamic>? mutatedState,
}) async {
  if (agentIds.isEmpty) {
    return StepResult.failed('dispatchConversationStep: no agents to dispatch');
  }

  final workspaceId = ctx.workspaceId;

  // Dry run: don't create a conversation; echo what would have happened.
  if (ctx.dryRun) {
    return StepResult.ok(mutatedState: mutatedState);
  }

  // 1. Create a hidden conversation owned by this pipeline run. A fresh group
  //    even for one agent — never reuse the user's DM.
  final channel = await messagingPort.createGroup(
    label ?? ctx.stepId,
    agentIds,
    mode: mode,
    workspaceId: workspaceId,
    pipelineRunId: ctx.pipelineRunId,
  );
  final channelId = channel.id;

  // Link the conversation onto the step run so the step-detail UI can open it.
  try {
    await runRepository.updateStepRun(ctx.stepRunId, channelId: channelId);
  } on Object catch (e, st) {
    CcDomainLog.warning('dispatchConversationStep: Failed to link channel $channelId to step run ${ctx.stepRunId}: $e\n$st',
    );
  }

  // 2. Post the rendered prompt + the output-contract footer as the seed
  //    message the agents read.
  final footer = outputSchema != null
      ? renderOutputContract(outputSchema, mode: outputContractMode)
      : '';
  final seed = footer.isEmpty ? prompt : '$prompt\n$footer';
  await messagingPort.sendUserMessage(channelId, seed);

  // 3. Dispatch each agent into the conversation, stamping the contract onto
  //    its run. Collect the run ids — they are the new "tasks" the step waits on.
  final runIds = <String>[];
  for (final agentId in agentIds) {
    final runId = await messagingPort.dispatchAgent(
      channelId: channelId,
      agentId: agentId,
      prompt: seed,
      workspaceId: workspaceId,
      pipelineRunId: ctx.pipelineRunId,
      pipelineStepId: ctx.stepId,
      expectedOutputSchema: outputSchema,
      outputContractMode: outputContractMode,
    );
    if (runId != null) {
      runIds.add(runId);
    }
  }

  if (runIds.isEmpty) {
    return StepResult.failed(
      'dispatchConversationStep: no agent runs were dispatched',
    );
  }

  // 4. Kill hook: stop the dispatches + archive the conversation when the step
  //    is cancelled or retried.
  stepProcessRegistry.register(ctx.stepRunId, () async {
    for (final agentId in agentIds) {
      try {
        await agentDispatchPort.stopAllForAgent(agentId);
      } on Object catch (e, st) {
        CcDomainLog.error('dispatchConversationStep: stopAllForAgent failed', e, st);
      }
    }
  });

  // 5. Suspend until every dispatched run finishes.
  return StepResult.suspendUntilTasksComplete(runIds, mutatedState: mutatedState);
}
