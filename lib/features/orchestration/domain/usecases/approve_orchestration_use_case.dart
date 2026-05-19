import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/orchestration_events.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/agents/domain/usecases/hire_agent_use_case.dart';
import 'package:control_center/features/orchestration/domain/entities/orchestration.dart';
import 'package:control_center/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:control_center/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:control_center/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:control_center/features/orchestration/domain/services/orchestration_materializer.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_validator.dart';
import 'package:control_center/features/teams/domain/entities/team.dart';
import 'package:control_center/features/teams/domain/entities/team_member.dart';
import 'package:control_center/features/teams/domain/repositories/team_repository.dart';
import 'package:control_center/features/ticketing/domain/services/project_service.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:uuid/uuid.dart';

/// Deterministically materializes an approved [Orchestration]: ensures hires,
/// creates the team + project, generates the pipeline template, and starts the
/// run. Every phase is idempotent (guarded by ids already stored on the row) so
/// a crash mid-approval resumes without duplicates. NO LLM anywhere.
class ApproveOrchestrationUseCase {
  /// Creates an [ApproveOrchestrationUseCase].
  ApproveOrchestrationUseCase({
    required OrchestrationRepository orchestrations,
    required HireAgentUseCase hireAgent,
    required TeamRepository teams,
    required ProjectService projects,
    required TicketWorkflowService ticketWorkflow,
    required PipelineTemplateRepository templates,
    required PipelineEngine engine,
    required DomainEventBus eventBus,
    OrchestrationMaterializer materializer = const OrchestrationMaterializer(),
  })  : _orchestrations = orchestrations,
        _hireAgent = hireAgent,
        _teams = teams,
        _projects = projects,
        _ticketWorkflow = ticketWorkflow,
        _templates = templates,
        _engine = engine,
        _eventBus = eventBus,
        _materializer = materializer;

  final OrchestrationRepository _orchestrations;
  final HireAgentUseCase _hireAgent;
  final TeamRepository _teams;
  final ProjectService _projects;
  final TicketWorkflowService _ticketWorkflow;
  final PipelineTemplateRepository _templates;
  final PipelineEngine _engine;
  final DomainEventBus _eventBus;
  final OrchestrationMaterializer _materializer;

  static const _uuid = Uuid();

  /// Approves and materializes [orchestrationId] in [workspaceId].
  Future<void> approve({
    required String workspaceId,
    required String orchestrationId,
  }) async {
    final loaded = await _orchestrations.getById(workspaceId, orchestrationId);
    if (loaded == null) {
      throw StateError('Orchestration $orchestrationId not found');
    }
    var o = loaded;
    // Guard: only a proposed orchestration can be approved (idempotent on
    // re-entry — an already-approved/executing row resumes below).
    if (o.status == OrchestrationStatus.proposed) {
      o = o.copyWith(
        status: OrchestrationStatus.approved,
        approvedRevision: o.revision,
        updatedAt: DateTime.now(),
      );
      await _orchestrations.update(o);
      _eventBus.publish(OrchestrationApproved(
        orchestrationId: o.id,
        workspaceId: workspaceId,
        occurredAt: DateTime.now(),
      ));
    } else if (o.status != OrchestrationStatus.approved) {
      // Already executing / terminal — nothing to do.
      return;
    }

    try {
      o = await _materialize(workspaceId, o);
    } on Object catch (e, st) {
      AppLog.e('ApproveOrchestration', 'materialization failed', e, st);
      await _fail(workspaceId, o, 'Materialization failed: $e');
      rethrow;
    }
  }

  Future<Orchestration> _materialize(String workspaceId, Orchestration o) async {
    final proposal = o.proposal;

    // 1. Hires (idempotent: skip when hiredAgentIds already covers the hires).
    final roleAgents = <String, String>{};
    final hired = <String>[...o.hiredAgentIds];
    final alreadyHired = o.hiredAgentIds.length;
    var hireIndex = 0;
    for (final role in proposal.roles) {
      if (role.existingAgentId != null && role.existingAgentId!.isNotEmpty) {
        roleAgents[role.roleKey] = role.existingAgentId!;
        continue;
      }
      final spec = role.hireSpec!;
      if (hireIndex < alreadyHired) {
        // Resume: reuse the already-hired agent id for this role slot.
        roleAgents[role.roleKey] = o.hiredAgentIds[hireIndex];
        hireIndex++;
        continue;
      }
      final agent = await _hireAgent.hire(
        workspaceId: workspaceId,
        name: spec.name,
        title: spec.title,
        agentMdContent: _agentMd(spec),
        skills: spec.skills,
        reportsTo: o.orchestratorAgentId,
        persona: spec.persona.isEmpty ? null : spec.persona,
      );
      roleAgents[role.roleKey] = agent.id;
      hired.add(agent.id);
      hireIndex++;
    }
    if (hired.length != o.hiredAgentIds.length) {
      o = o.copyWith(hiredAgentIds: hired, updatedAt: DateTime.now());
      await _orchestrations.update(o);
    }

    // 2. Team (idempotent on teamId).
    var teamId = o.teamId;
    if (teamId == null) {
      teamId = _uuid.v4();
      await _teams.insertTeam(Team(
        id: teamId,
        workspaceId: workspaceId,
        name: 'Team: ${_short(proposal.goal)}',
        description: proposal.goal,
        createdAt: DateTime.now(),
      ));
      for (final role in proposal.roles) {
        final agentId = roleAgents[role.roleKey];
        if (agentId == null) {
          continue;
        }
        await _teams.addMember(TeamMember(
          teamId: teamId,
          agentId: agentId,
          role: role.roleKey == proposal.synthesis.roleKey
              ? TeamMemberRole.leader
              : TeamMemberRole.member,
        ));
      }
      o = o.copyWith(teamId: teamId, updatedAt: DateTime.now());
      await _orchestrations.update(o);
    }

    // 3. Project (idempotent on projectId).
    var projectId = o.projectId;
    if (projectId == null) {
      final project = await _projects.create(
        workspaceId: workspaceId,
        name: _short(proposal.goal),
        description: proposal.goal,
      );
      projectId = project.id;
      final parentTicketId = o.parentTicketId;
      if (parentTicketId != null) {
        await _ticketWorkflow.setProject(
          parentTicketId,
          projectId,
          workspaceId: workspaceId,
        );
      }
      o = o.copyWith(projectId: projectId, updatedAt: DateTime.now());
      await _orchestrations.update(o);
    }

    // 4. Pipeline template (idempotent on pipelineTemplateId).
    final templateId = o.pipelineTemplateId ?? 'orchestration_${o.id}';
    if (o.pipelineTemplateId == null) {
      final definition = _materializer.buildDefinition(
        o,
        roleAgents: roleAgents,
        channelId: o.channelId ?? '',
        parentTicketId: o.parentTicketId ?? '',
        projectId: projectId,
      );
      try {
        await _templates.upsert(definition);
      } on PipelineValidationException catch (e) {
        await _fail(workspaceId, o, 'Generated pipeline is invalid: $e');
        rethrow;
      }
      o = o.copyWith(pipelineTemplateId: templateId, updatedAt: DateTime.now());
      await _orchestrations.update(o);
    }

    // 5. Start the run (idempotent on pipelineRunId; dedupKey prevents stampede).
    if (o.pipelineRunId == null) {
      final run = await _engine.start(
        templateId,
        workspaceId: workspaceId,
        triggerEventType: 'orchestration.approved',
        triggerPayload: {
          'orchestrationId': o.id,
          'parentTicketId': o.parentTicketId,
          'goal': proposal.goal,
        },
        dedupKey: o.id,
      );
      final now = DateTime.now();
      o = o.copyWith(
        pipelineRunId: run?.id,
        status: OrchestrationStatus.executing,
        updatedAt: now,
      );
      await _orchestrations.update(o);
      if (run != null) {
        _eventBus.publish(OrchestrationExecutionStarted(
          orchestrationId: o.id,
          workspaceId: workspaceId,
          pipelineRunId: run.id,
          occurredAt: now,
        ));
      }
    }
    return o;
  }

  Future<void> _fail(
    String workspaceId,
    Orchestration o,
    String message,
  ) async {
    await _orchestrations.update(o.copyWith(
      status: OrchestrationStatus.failed,
      errorMessage: message,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    final parentTicketId = o.parentTicketId;
    if (parentTicketId != null) {
      await _ticketWorkflow.failTicket(
        parentTicketId,
        message,
        workspaceId: workspaceId,
        force: true,
      );
    }
    _eventBus.publish(OrchestrationFailed(
      orchestrationId: o.id,
      workspaceId: workspaceId,
      errorMessage: message,
      occurredAt: DateTime.now(),
    ));
  }

  String _agentMd(ProposedHire spec) {
    final buf = StringBuffer()
      ..writeln('# ${spec.title}')
      ..writeln();
    if (spec.persona.isNotEmpty) {
      buf
        ..writeln(spec.persona)
        ..writeln();
    }
    if (spec.skills.isNotEmpty) {
      buf.writeln('Skills: ${spec.skills.join(', ')}');
    }
    return buf.toString();
  }

  static String _short(String s) =>
      s.length <= 60 ? s : '${s.substring(0, 57)}…';
}
