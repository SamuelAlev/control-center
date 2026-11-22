import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/ports/goal_pursuit_port.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart'
    show kPipelineRequestedByKey;
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart'
    show PinnedPipelineGraph;
import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart'
    show kPipelineSpaceStateKey;
import 'package:cc_domain/features/pipelines/domain/templates/dispatch_conversation_step.dart'
    show priorStepRunSpaceId, resolveConfiguredSpaceId;
import 'package:cc_domain/features/pipelines/domain/templates/goal_pursue_config.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart'
    show GoalAlreadyActiveException;

/// Registers the `goal.pursue` body ([kGoalPursueBodyKey]).
///
/// It starts a durable goal for the node's agent in the step's own
/// conversation, with the pipeline run's requester, and suspends the step
/// until the goal settles; the server's `GoalSettled` listener completes or
/// fails the step through the engine. The goal's id is recorded in the
/// run's state under [goalPursueStateKey], so a re-fire after a restart
/// re-attaches to it instead of starting a second goal: a goal still going
/// keeps the step waiting, and one that completed while the server was down
/// completes the step at once. A known goal that ended badly (failed,
/// cancelled, out of budget) is treated as absent: the re-fire is a retry
/// of the step, and starts a new goal linked to the same run and step,
/// whose id replaces the old one in the run's state.
/// The ends of a known goal a re-fire starts over from.
const Set<AgentGoalStatus> _endedBadly = {
  AgentGoalStatus.failed,
  AgentGoalStatus.cancelled,
  AgentGoalStatus.budgetExhausted,
};

void registerGoalPursueBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required AgentRepository agentRepository,
  required MessagingPort messagingPort,
  required PipelineRunRepository runRepository,
  required GoalPursuitPort goals,
}) {
  const renderer = TemplateRenderer();

  registry.registerBody(kGoalPursueBodyKey, (ctx) async {
    final workspaceId = ctx.workspaceId;
    final def = await ctx.pinnedDefinition(templateRepository);
    final node = def?.step(ctx.stepId)?.config;
    if (node == null) {
      return StepResult.failed(
        'goal.pursue: step "${ctx.stepId}" missing config',
      );
    }
    final GoalPursueConfig config;
    try {
      config = GoalPursueConfig.parse(node);
    } on FormatException catch (e) {
      return StepResult.failed(e.message);
    }

    // A re-fire on the row this step already owns: re-attach.
    final known = ctx.state[goalPursueStateKey(ctx.stepId)];
    if (known is String && known.isNotEmpty) {
      final goal = await goals.attach(
        workspaceId: workspaceId,
        goalId: known,
        pipelineRunId: ctx.pipelineRunId,
        stepId: ctx.stepId,
      );
      if (goal == null || goal.agentId != config.agentId) {
        return StepResult.failed(
          'goal.pursue: the goal this step started is gone',
        );
      }
      if (!_endedBadly.contains(goal.status)) {
        return goalPursueOutcome(
          goal,
          stepId: ctx.stepId,
          outputKey: config.outputKey,
        );
      }
    }
    if (ctx.dryRun) {
      return StepResult.ok();
    }

    final agent = await agentRepository.getById(workspaceId, config.agentId);
    if (agent == null) {
      return StepResult.failed(
        'goal.pursue: agent "${config.agentId}" not found',
      );
    }

    // The room, in the conversation steps' order: the prior attempt's room,
    // the node's room, the run's room.
    final nodeRoom = resolveConfiguredSpaceId(node.spaceId, ctx);
    final prior = await priorStepRunSpaceId(runRepository, ctx);
    final runRoomValue = ctx.state[kPipelineSpaceStateKey];
    final runRoom = runRoomValue is String ? runRoomValue.trim() : '';
    String? spaceId;
    for (final candidate in [prior ?? '', nodeRoom, runRoom]) {
      if (candidate.isNotEmpty &&
          await messagingPort.spaceExists(workspaceId, candidate)) {
        spaceId = candidate;
        break;
      }
    }
    if (spaceId == null) {
      return StepResult.failed(
        'goal.pursue: step "${ctx.stepId}" has no conversation to work in. '
        'Open the run with a `messaging.createSpace` node or point the node '
        "at an existing room with extras['spaceId'].",
      );
    }
    await messagingPort.addAgentToSpace(
      workspaceId,
      spaceId,
      agent.id,
      renameForGroup: false,
    );
    final title = (node.conversationTitle?.trim().isNotEmpty ?? false)
        ? node.conversationTitle!.trim()
        : (node.label ?? ctx.stepId);
    final conversationId = await messagingPort.createConversation(
      workspaceId: workspaceId,
      spaceId: spaceId,
      title: title,
      createdByPrincipalId: agent.id,
      reuseExisting: true,
    );
    if (conversationId == null) {
      return StepResult.failed(
        'goal.pursue: could not open the conversation "$title"',
      );
    }
    await runRepository.updateStepRun(
      workspaceId,
      ctx.stepRunId,
      spaceId: spaceId,
    );

    final objective = renderer
        .render(
          config.objective,
          state: ctx.renderState,
          trigger: ctx.triggerPayload,
        )
        .text
        .trim();
    if (objective.isEmpty) {
      return StepResult.failed('goal.pursue: the objective rendered empty');
    }
    final requester = ctx.triggerPayload?[kPipelineRequestedByKey];
    final hours = config.deadlineHours;
    try {
      final goal = await goals.startPursuit(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agent.id,
        objective: objective,
        contract: config.contract,
        costCapMicros: config.budgetMicros,
        maxRuns: config.maxRuns,
        deadlineAt: hours == null
            ? null
            : DateTime.now().add(Duration(hours: hours)),
        requestedByUserId: requester is String && requester.isNotEmpty
            ? requester
            : null,
        pipelineRunId: ctx.pipelineRunId,
        stepId: ctx.stepId,
      );
      return goalPursueOutcome(
        goal,
        stepId: ctx.stepId,
        outputKey: config.outputKey,
      );
    } on GoalAlreadyActiveException {
      return StepResult.failed(
        'goal.pursue: agent "${agent.id}" already pursues a goal',
      );
    }
  });
}
