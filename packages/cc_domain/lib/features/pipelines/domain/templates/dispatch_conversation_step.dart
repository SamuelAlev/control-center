import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/output_contract_prompt.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_step_resume_listener.dart'
    show PipelineStepResumeListener;
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';

/// Shared execution primitive for the "message step" bodies (promptAgent,
/// teamDispatch, forEach, human.gate). Conversation-first: instead of creating
/// an agent-assigned ticket, it posts the rendered prompt (+ the output-contract
/// footer) into a conversation, dispatches each agent into it (stamping the
/// contract onto the created run), and suspends the step until those runs
/// finish. The [PipelineStepResumeListener] advances the step once every run is
/// terminal; the engine harvests each run's `outputJson`.
///
/// **Which conversation.** [channelId] — a step config's `extras['channelId']`,
/// which every node a generated orchestration/plan pipeline emits carries — runs
/// the step in THAT existing room. This is what makes approving a plan continue
/// the conversation it was authored in: the seed prompt, the agent's streaming
/// turn, and the operator's Stop button all land in the room they are already
/// watching. Without it (built-in reviewers, ad-hoc nodes) the step spins up its
/// own **hidden** conversation as before — invisible by design, since no operator
/// authored it.
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
  Mode mode = Mode.review,
  Map<String, dynamic>? mutatedState,
  String? channelId,
}) async {
  if (agentIds.isEmpty) {
    return StepResult.failed('dispatchConversationStep: no agents to dispatch');
  }

  final workspaceId = ctx.workspaceId;

  // Dry run: don't create a conversation; echo what would have happened.
  if (ctx.dryRun) {
    return StepResult.ok(mutatedState: mutatedState);
  }

  // 1. Resolve the conversation this step works in: the configured room when the
  //    node names one that still exists, else a fresh hidden conversation owned
  //    by this pipeline run (one per step, even for a single agent).
  //
  //    `channelExists` guards a stale id (the operator deleted the room after the
  //    plan was authored): a missing channel falls back to a hidden conversation
  //    rather than failing the step or writing against a missing row.
  final configured = channelId?.trim() ?? '';
  final reuseConfigured =
      configured.isNotEmpty &&
      await messagingPort.channelExists(workspaceId, configured);
  final String targetChannelId;
  if (reuseConfigured) {
    targetChannelId = configured;
    // The dispatched agents must be in the room's roster — they are working in
    // it, and the channel sidebar is where the operator looks to see who. It is
    // idempotent, so the plan's authoring agent (already a participant) is
    // untouched, and `renameForGroup: false` keeps a worker joining from
    // renaming the operator's conversation after its members. The channel's own
    // mode is left alone too: it belongs to the operator, not to this step.
    for (final agentId in agentIds) {
      try {
        await messagingPort.addAgentToChannel(
          workspaceId,
          targetChannelId,
          agentId,
          renameForGroup: false,
        );
      } on Object catch (e, st) {
        CcDomainLog.warning(
          'dispatchConversationStep: Failed to add agent $agentId to channel $targetChannelId: $e\n$st',
        );
      }
    }
  } else {
    final channel = await messagingPort.createChannel(
      workspaceId,
      label ?? ctx.stepId,
      agentIds,
      mode: mode,
      pipelineRunId: ctx.pipelineRunId,
    );
    targetChannelId = channel.id;
  }

  // Link the conversation onto the step run so the step-detail UI can open it.
  try {
    await runRepository.updateStepRun(
      ctx.workspaceId,
      ctx.stepRunId,
      channelId: targetChannelId,
    );
  } on Object catch (e, st) {
    CcDomainLog.warning(
      'dispatchConversationStep: Failed to link channel $targetChannelId to step run ${ctx.stepRunId}: $e\n$st',
    );
  }

  // 2. Post the rendered prompt + the output-contract footer as the seed
  //    message the agents read.
  final footer = outputSchema != null
      ? renderOutputContract(outputSchema, mode: outputContractMode)
      : '';
  final seed = footer.isEmpty ? prompt : '$prompt\n$footer';
  await messagingPort.sendUserMessage(workspaceId, targetChannelId, seed);

  // 3. Dispatch each agent into the conversation, stamping the contract onto
  //    its run. Collect the run ids — they are the new "tasks" the step waits on.
  final runIds = <String>[];
  for (final agentId in agentIds) {
    final runId = await messagingPort.dispatchAgent(
      channelId: targetChannelId,
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
        CcDomainLog.error(
          'dispatchConversationStep: stopAllForAgent failed',
          e,
          st,
        );
      }
    }
  });

  // 5. Suspend until every dispatched run finishes.
  return StepResult.suspendUntilTasksComplete(
    runIds,
    mutatedState: mutatedState,
  );
}
