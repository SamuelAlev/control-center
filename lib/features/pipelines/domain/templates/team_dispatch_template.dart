import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/ports/ticket_workflow_port.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/template_renderer.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:control_center/features/teams/domain/entities/team_member.dart';
import 'package:control_center/features/teams/domain/repositories/team_repository.dart';
import 'package:uuid/uuid.dart';
/// Registers the `team.dispatch` body — the execution primitive that makes
/// "Flow + Team" real. Instead of one `agentId`, the node names a `teamId`
/// and a `dispatchMode`:
///
/// - **allParallel** (default): create one ticket per team member and suspend
///   until every ticket completes. The engine harvests the members' outputs
///   into a list under `outputKey` (use `reducer: 'append'` to aggregate).
/// - **manager**: create a single ticket for the team leader, instructing it to
///   break the goal down and `delegate_ticket` to members. Suspends on it.
///
/// Tickets are created assigned + suspended; the `TicketDispatcher` owns the
/// readiness → channel → start → dispatch path (one shared channel per run),
/// and the `TicketResumeListener` resumes this step when the tickets finish.
void registerTeamDispatchBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required AgentRepository agentRepository,
  required TeamRepository teamRepository,
  required TicketWorkflowPort ticketWorkflow,
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
      final ticketId = const Uuid().v4();
      final description = '$rendered\n\n'
          'You are the team lead. Break this down and delegate sub-tickets to '
          'your team via the `delegate_ticket` MCP tool, then consolidate the '
          'results.\n\n'
          '── Pipeline coordination ─────────────────────────────\n'
          'When done, call `complete_ticket` with ticket_id="$ticketId".';
      await ticketWorkflow.createTicket(
        id: ticketId,
        pipelineRunId: ctx.pipelineRunId,
        pipelineStepId: ctx.stepId,
        workspaceId: workspaceId,
        title: config.label ?? ctx.stepId,
        description: description,
        assignedAgentId: agent.id,
        mode: ConversationMode.review,
        expectedOutputSchema: config.outputSchema,
      );
      return StepResult.suspendUntilTasksComplete([ticketId]);
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

    final ticketIds = <String>[];
    for (final agent in resolved) {
      final ticketId = const Uuid().v4();
      final description = '$rendered\n\n'
          '── Pipeline coordination ─────────────────────────────\n'
          'When you finish, call the `complete_ticket` MCP tool with '
          'ticket_id="$ticketId" and your findings in the `output` payload '
          '(`{ "result": "<markdown body>" }`).';
      await ticketWorkflow.createTicket(
        id: ticketId,
        pipelineRunId: ctx.pipelineRunId,
        pipelineStepId: ctx.stepId,
        workspaceId: workspaceId,
        title: '${config.label ?? ctx.stepId} — ${agent.name}',
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
