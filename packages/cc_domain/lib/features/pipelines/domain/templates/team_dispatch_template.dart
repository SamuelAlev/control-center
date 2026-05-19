import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
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
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';

/// Registers the `team.dispatch` body — the execution primitive that makes
/// "Flow + Team" real. Instead of one `agentId`, the node names a `teamId`
/// and a `dispatchMode`:
///
/// - **allParallel** (default): dispatch every member into one hidden group
///   conversation and suspend until every run completes. The engine harvests
///   the members' outputs into a list under `outputKey`.
/// - **manager**: dispatch only the team leader, instructing it to break the
///   goal down and coordinate (it consults its team in the conversation).
void registerTeamDispatchBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required AgentRepository agentRepository,
  required TeamRepository teamRepository,
  required MessagingPort messagingPort,
  required AgentDispatchPort agentDispatchPort,
  required StepProcessRegistry stepProcessRegistry,
  required PipelineRunRepository runRepository,
}) {
  const renderer = TemplateRenderer();

  registry.registerBody(BuiltInBodyKeys.teamDispatch, (ctx) async {
    final workspaceId = ctx.workspaceId;
    final def = await templateRepository.getById(workspaceId, ctx.templateId);
    final config = def?.step(ctx.stepId)?.config;
    if (config == null) {
      return StepResult.failed('teamDispatch: step "${ctx.stepId}" missing config');
    }
    final teamId = config.teamId;
    if (teamId == null || teamId.isEmpty) {
      return StepResult.failed('teamDispatch: step "${ctx.stepId}" missing teamId');
    }
    if (config.prompt == null || config.prompt!.isEmpty) {
      return StepResult.failed('teamDispatch: step "${ctx.stepId}" missing prompt');
    }

    final members = await teamRepository.membersOf(teamId);
    if (members.isEmpty) {
      return StepResult.failed('teamDispatch: team "$teamId" has no members');
    }

    final rendered =
        renderer.render(config.prompt!, state: ctx.renderState, trigger: ctx.triggerPayload).text;
    final mode = config.dispatchMode ?? 'allParallel';

    if (mode == 'manager') {
      final leader = members.firstWhere(
        (m) => m.role == TeamMemberRole.leader,
        orElse: () => members.first,
      );
      final agent = await agentRepository.getById(leader.agentId);
      if (agent == null) {
        return StepResult.failed(
          'teamDispatch: leader agent "${leader.agentId}" not found',
        );
      }
      final managerPrompt = '$rendered\n\n'
          'You are the team lead. Break this down and coordinate your team '
          'to deliver it, then submit your consolidated output.';
      return dispatchConversationStep(
        ctx: ctx,
        messagingPort: messagingPort,
        agentDispatchPort: agentDispatchPort,
        stepProcessRegistry: stepProcessRegistry,
        runRepository: runRepository,
        agentIds: [agent.id],
        prompt: managerPrompt,
        label: config.label ?? ctx.stepId,
        outputSchema: config.outputSchema,
      );
    }

    // allParallel: validate every member resolves to an agent up front so we
    // never silently dispatch fewer agents than the team has members.
    final resolved = <Agent>[];
    final missing = <String>[];
    for (final member in members) {
      final agent = await agentRepository.getById(member.agentId);
      if (agent == null) {
        missing.add(member.agentId);
      } else {
        resolved.add(agent);
      }
    }
    if (missing.isNotEmpty) {
      return StepResult.failed(
        'teamDispatch: ${missing.length} team member(s) reference missing '
        'agents: ${missing.join(', ')}',
      );
    }

    return dispatchConversationStep(
      ctx: ctx,
      messagingPort: messagingPort,
      agentDispatchPort: agentDispatchPort,
      stepProcessRegistry: stepProcessRegistry,
      runRepository: runRepository,
      agentIds: [for (final a in resolved) a.id],
      prompt: rendered,
      label: config.label ?? ctx.stepId,
      outputSchema: config.outputSchema,
    );
  });
}
