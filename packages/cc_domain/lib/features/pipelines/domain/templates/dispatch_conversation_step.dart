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
import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart'
    show kPipelineSpaceStateKey;

/// Shared execution primitive for the "message step" bodies (promptAgent,
/// teamDispatch, forEach, human.gate). Conversation-first: instead of creating
/// an agent-assigned ticket, it posts the rendered prompt (+ the output-contract
/// footer) into a conversation, dispatches each agent into it (stamping the
/// contract onto the created run) and suspends the step until those runs
/// finish. The [PipelineStepResumeListener] advances the step once every run is
/// terminal; the engine harvests each run's `outputJson`.
///
/// **Which conversation.** [spaceId] — a step config's `extras['spaceId']`,
/// which every node a generated orchestration/plan pipeline emits carries — runs
/// the step in THAT existing room. This is what makes approving a plan continue
/// the conversation it was authored in: the seed prompt, the agent's streaming
/// turn and the operator's Stop button all land in the room they are already
/// watching. It supports `{{key}}` placeholders, so a step can name a room an
/// EARLIER step in the same run created (the PR-review template's reviewers all
/// land in the space its first step ensured). Without it (ad-hoc nodes) the step
/// spins up its own **hidden** conversation as before — invisible by design,
/// since no operator authored it.
///
/// **Which stream.** [conversationTitle] — a step config's
/// `extras['conversationTitle']` — opens a NAMED conversation inside the
/// resolved room instead of writing into its standing stream. A fan-out of
/// reviewers uses this so each one keeps a readable thread while all of them
/// share the space's single checkout: creating a space per reviewer instead
/// would clone every repo once per reviewer and bury each thread in a room
/// nobody is in.
///
/// **Repo scope is not this step's business.** A room's checkout is decided
/// when the room is opened, by `messaging.createSpace` (or by whoever created
/// the operator's room). This step joins a room that already exists, so a
/// fan-out of ten agents shares one checkout rather than provisioning ten.
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
  Map<String, dynamic>? mutatedState,
  String? spaceId,
  String? conversationTitle,
}) async {
  if (agentIds.isEmpty) {
    return StepResult.failed('dispatchConversationStep: no agents to dispatch');
  }

  final workspaceId = ctx.workspaceId;

  // Dry run: don't create a conversation; echo what would have happened.
  if (ctx.dryRun) {
    return StepResult.ok(mutatedState: mutatedState);
  }

  // ── Kill hook, registered BEFORE any work starts ──────────────────────────
  //
  // Registered first so a stop lands wherever the step happens to be: waiting
  // for the room's checkout, or mid-dispatch. Registering it after
  // `dispatchAgent` returns leaves that whole window uncovered, and a stop
  // there finds nothing to kill while the agent starts anyway.
  //
  // It stops AGENTS only. The room belongs to whoever opened it — a
  // `messaging.createSpace` node, or the operator — and each of those cancels
  // its own provisioning. A step ending is no reason to interrupt a checkout
  // its siblings are still working in.
  var stopped = false;
  stepProcessRegistry.register(ctx.stepRunId, () async {
    stopped = true;
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

  // 1. Resolve the conversation this step works in. A room is REQUIRED and is
  //    never created here — the step joins one that already exists, in this
  //    order:
  //
  //      * the room this step run already worked in (a retry or a crash-resume
  //        re-fires the body on the row it owns, and that row carries the id);
  //      * the room the node names (`extras['spaceId']`), literal or
  //        `{{placeholder}}` — how a generated plan step continues the
  //        conversation it was authored in;
  //      * the run's own room, opened by a `messaging.createSpace` node.
  //
  //    Creating one here instead would make the room — and therefore a repo
  //    checkout — a side effect of dispatching an agent. Parallel steps each
  //    reach this point before any of them has published a room, so a fan-out
  //    would open one apiece and check out the workspace once per branch. The
  //    room is a decision the template makes ONCE, in a node an author can see.
  final nodeRoom = resolveConfiguredSpaceId(spaceId, ctx);
  final priorSpaceId = await priorStepRunSpaceId(runRepository, ctx);
  final runRoom = _runRoomOf(ctx);
  // `spaceExists` guards a stale id — the operator deleted the room after the
  // plan was authored — so a vanished room falls through to the next candidate
  // rather than dispatching against a missing row.
  String? resolved;
  for (final candidate in [priorSpaceId ?? '', nodeRoom, runRoom]) {
    if (candidate.isNotEmpty &&
        await messagingPort.spaceExists(workspaceId, candidate)) {
      resolved = candidate;
      break;
    }
  }
  if (resolved == null) {
    return StepResult.failed(
      'dispatchConversationStep: step "${ctx.stepId}" has no conversation to '
      'work in. Open the run with a `messaging.createSpace` node (its id lands '
      'in `$kPipelineSpaceStateKey`), or point the node at an existing room '
      "with extras['spaceId'].",
    );
  }
  final targetSpaceId = resolved;

  // The dispatched agents must be in the room's roster — they are working in it
  // and the space sidebar is where the operator looks to see who. Idempotent,
  // so an agent already present is untouched; `renameForGroup: false` keeps a
  // worker joining from renaming the operator's conversation after its members.
  // The space's own mode is left alone: it belongs to whoever opened it.
  for (final agentId in agentIds) {
    try {
      await messagingPort.addAgentToSpace(
        workspaceId,
        targetSpaceId,
        agentId,
        renameForGroup: false,
      );
    } on Object catch (e, st) {
      CcDomainLog.warning(
        'dispatchConversationStep: Failed to add agent $agentId to space '
        '$targetSpaceId: $e\n$st',
      );
    }
  }

  if (stopped) {
    return StepResult.failed(
      'dispatchConversationStep: the step was stopped before dispatch',
    );
  }

  // Every step opens its OWN named stream inside the shared room, falling back
  // to a name derived from the step when the node declares no title. Steps
  // share one room by design; without separate streams a fan-out interleaves
  // every agent's turns into one unreadable thread.
  //
  // The node's room is the exception: a step pointed at a conversation someone
  // authored writes into that conversation, which is the whole point of naming
  // it. Only a title the node states explicitly opens a stream there.
  final ownsNodeRoom = nodeRoom.isNotEmpty && targetSpaceId == nodeRoom;
  final title = (conversationTitle?.trim().isNotEmpty ?? false)
      ? conversationTitle!.trim()
      : (ownsNodeRoom ? '' : (label ?? ctx.stepId));
  String? targetConversationId;
  if (title.isNotEmpty) {
    try {
      targetConversationId = await messagingPort.createConversation(
        workspaceId: workspaceId,
        spaceId: targetSpaceId,
        title: title,
        // Whose stream this is. A one-agent step owns its conversation, so a
        // human replying in it wakes THAT agent instead of whichever one the
        // space's roster lists first — the roster is space-wide, and a review
        // space holds every reviewer.
        createdByPrincipalId: agentIds.length == 1 ? agentIds.single : null,
        // A step's named stream is identified by its title inside the room: a
        // rerun continues the thread the last attempt wrote in instead of
        // leaving the room holding two "QA review" conversations with no way
        // to tell which one the live agent is in.
        reuseExisting: true,
      );
    } on Object catch (e, st) {
      CcDomainLog.warning(
        'dispatchConversationStep: Failed to open conversation "$title" in '
        'space $targetSpaceId — falling back to its standing stream: $e\n$st',
      );
    }
  }

  // Link the conversation onto the step run so the step-detail UI can open it.
  try {
    await runRepository.updateStepRun(
      ctx.workspaceId,
      ctx.stepRunId,
      spaceId: targetSpaceId,
    );
  } on Object catch (e, st) {
    CcDomainLog.warning(
      'dispatchConversationStep: Failed to link space $targetSpaceId to step run ${ctx.stepRunId}: $e\n$st',
    );
  }

  // 2. Post the rendered prompt + the output-contract footer as the seed
  //    message the agents read.
  final footer = outputSchema != null
      ? renderOutputContract(outputSchema, mode: outputContractMode)
      : '';
  final seed = footer.isEmpty ? prompt : '$prompt\n$footer';
  await messagingPort.sendUserMessage(
    workspaceId,
    targetSpaceId,
    seed,
    conversationId: targetConversationId,
  );

  // 3. Dispatch each agent into the conversation, stamping the contract onto
  //    its run. Collect the run ids — they are the new "tasks" the step waits on.
  final runIds = <String>[];
  for (final agentId in agentIds) {
    // Re-checked per agent: dispatch waits for the space's workspace to be
    // ready, so a stop can land between two agents of the same step.
    if (stopped) {
      break;
    }
    final runId = await messagingPort.dispatchAgent(
      spaceId: targetSpaceId,
      agentId: agentId,
      prompt: seed,
      workspaceId: workspaceId,
      pipelineRunId: ctx.pipelineRunId,
      pipelineStepId: ctx.stepId,
      conversationId: targetConversationId,
      expectedOutputSchema: outputSchema,
      outputContractMode: outputContractMode,
    );
    if (runId != null) {
      runIds.add(runId);
    }
  }

  if (stopped) {
    // Anything that did start before the stop was already killed by the hook;
    // suspending on those runs would wait for turns that will never arrive.
    return StepResult.failed(
      'dispatchConversationStep: the step was stopped during dispatch',
    );
  }

  if (runIds.isEmpty) {
    return StepResult.failed(
      'dispatchConversationStep: no agent runs were dispatched',
    );
  }

  // 4. Suspend until every dispatched run finishes.
  return StepResult.suspendUntilTasksComplete(
    runIds,
    mutatedState: mutatedState,
  );
}

/// The room this RUN is working in, or empty when none is open yet.
///
/// Written by a `messaging.createSpace` entry node, and — for the ad-hoc
/// templates that have no such node — by whichever agent step of the run opened
/// a room first. Reading it is what makes a run cost ONE room rather than one
/// per agent step: a room is a checkout, and a step naming no repo scope checks
/// out the whole workspace.
String _runRoomOf(PipelineContext ctx) {
  final value = ctx.state[kPipelineSpaceStateKey];
  return value is String ? value.trim() : '';
}

/// The room a PREVIOUS invocation of this same step run already worked in, or
/// null when this is the step's first pass (or the row cannot be read).
///
/// The engine re-fires a step body on the row it already owns — a crash-resume
/// re-attaching an interrupted step, or a retry re-opening a failed one — and
/// records the room on that row (see the `updateStepRun(spaceId:)` below). Not
/// reading it back is what made a rerun clone a whole second worktree and
/// dispatch its agents into a room the operator was not watching.
///
/// A failure to read is a fallback to the normal resolution, never a failure
/// of the step: the worst case is the behaviour that shipped before this.
///
/// Public because `messaging.createSpace` needs the same answer: the room it
/// created on a previous attempt is the one its retry must hand downstream,
/// or the run mints a second space and clones the repo again.
Future<String?> priorStepRunSpaceId(
  PipelineRunRepository runRepository,
  PipelineContext ctx,
) async {
  try {
    final stepRun = await runRepository.getStepRunById(
      ctx.workspaceId,
      ctx.stepRunId,
    );
    final prior = stepRun?.spaceId?.trim();
    return (prior == null || prior.isEmpty) ? null : prior;
  } on Object catch (e, st) {
    CcDomainLog.warning(
      'dispatchConversationStep: could not read the prior space of step run '
      '${ctx.stepRunId}: $e\n$st',
    );
    return null;
  }
}

/// Resolves a node's configured room (the node config's `extras['spaceId']`)
/// against the pipeline state and trigger payload.
///
/// A literal id passes through untouched — that is what a generated plan node
/// carries. A `{{key}}` reference names the room an EARLIER step of the same
/// run opened, which is how a fan-out shares one space and therefore one
/// checkout. An entry that does not resolve returns empty rather than
/// addressing a room literally named `{{review_space_id}}`; the caller then tries
/// its remaining candidates and fails the step if none resolves.
String resolveConfiguredSpaceId(String? configured, PipelineContext ctx) {
  final raw = configured?.trim() ?? '';
  if (raw.isEmpty || !raw.contains('{{')) {
    return raw;
  }
  const renderer = TemplateRenderer();
  final result = renderer.render(
    raw,
    state: ctx.renderState,
    trigger: ctx.triggerPayload,
  );
  final value = result.text.trim();
  if (!result.isComplete || value.isEmpty) {
    CcDomainLog.warning(
      'dispatchConversationStep: space reference "$raw" did not resolve — '
      'the step will use the run\'s room, or fail if it has none',
    );
    return '';
  }
  return value;
}
