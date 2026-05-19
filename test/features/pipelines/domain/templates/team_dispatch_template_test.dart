import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/ports/ticket_workflow_port.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_context.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:control_center/features/pipelines/domain/templates/team_dispatch_template.dart';
import 'package:control_center/features/teams/domain/entities/team.dart';
import 'package:control_center/features/teams/domain/entities/team_member.dart';
import 'package:control_center/features/teams/domain/repositories/team_repository.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lightweight fakes for the repositories/ports the team-dispatch body uses.

class _FakePipelineTemplateRepository implements PipelineTemplateRepository {
  final Map<String, PipelineDefinition> _defs = {};

  void add(PipelineDefinition def) {
    _defs[def.templateId] = def;
  }

  @override
  Future<PipelineDefinition?> getById(String workspaceId, String templateId) async {
    final def = _defs[templateId];
    if (def == null || def.workspaceId != workspaceId) {
      return null;
    }
    return def;
  }

  @override
  Future<List<PipelineDefinition>> forWorkspace(String workspaceId) async {
    return _defs.values.where((d) => d.workspaceId == workspaceId).toList();
  }

  @override
  Stream<List<PipelineDefinition>> watchForWorkspace(String workspaceId) {
    throw UnimplementedError();
  }

  @override
  Future<void> upsert(PipelineDefinition definition) async {
    _defs[definition.templateId] = definition;
  }
  @override
  Future<int> deleteById(String workspaceId, String templateId) async {
    throw UnimplementedError();
  }
}
class _FakeAgentRepository implements AgentRepository {
  final Map<String, Agent> _agents = {};

  void add(Agent agent) {
    _agents[agent.id] = agent;
  }

  @override
  Future<Agent?> getById(String agentId) async {
    return _agents[agentId];
  }

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) =>
      throw UnimplementedError();

  @override
  Stream<List<Agent>> watchAll() => throw UnimplementedError();

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      throw UnimplementedError();

  @override
  Future<void> upsert(Agent agent) => throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();
}


class _FakeTeamRepository implements TeamRepository {
  final Map<String, List<TeamMember>> _members = {};

  void setMembers(String teamId, List<TeamMember> members) {
    _members[teamId] = members;
  }

  @override
  Future<List<TeamMember>> membersOf(String teamId) async {
    return _members[teamId] ?? [];
  }

  @override
  Future<void> insertTeam(Team team) => throw UnimplementedError();

  @override
  Future<void> updateTeam(Team team) => throw UnimplementedError();

  @override
  Future<void> deleteTeam(String id) => throw UnimplementedError();

  @override
  Future<Team?> getTeam(String id) => throw UnimplementedError();

  @override
  Future<List<Team>> teamsForWorkspace(String workspaceId) =>
      throw UnimplementedError();

  @override
  Stream<List<Team>> watchTeamsForWorkspace(String workspaceId) =>
      throw UnimplementedError();

  @override
  Future<void> addMember(TeamMember member) => throw UnimplementedError();

  @override
  Future<void> removeMember(String teamId, String agentId) =>
      throw UnimplementedError();

  @override
  Stream<List<TeamMember>> watchMembersOf(String teamId) =>
      throw UnimplementedError();
}

class _FakeTicketWorkflowPort implements TicketWorkflowPort {
  final List<_CreatedTicket> createdTickets = [];

  @override
  Future<Ticket> createTicket({
    required String workspaceId,
    required String title,
    String? id,
    String? description,
    TicketProvider provider = TicketProvider.local,
    TicketPriority priority = TicketPriority.none,
    TicketStatus status = TicketStatus.open,
    List<String> labels = const [],
    String? assignedAgentId,
    String? assignedTeamId,
    String? delegatedByAgentId,
    String? parentTicketId,
    String? projectId,
    String? channelId,
    ConversationMode mode = ConversationMode.chat,
    String? pipelineRunId,
    String? pipelineStepId,
    Map<String, dynamic>? expectedOutputSchema,
    Map<String, String> providerExtras = const {},
  }) async {
    createdTickets.add(_CreatedTicket(
      id: id ?? 'missing-id',
      title: title,
      description: description,
      assignedAgentId: assignedAgentId,
      pipelineRunId: pipelineRunId,
      pipelineStepId: pipelineStepId,
      mode: mode,
      expectedOutputSchema: expectedOutputSchema,
    ));
    // Return a minimal Ticket; the body discards the return value.
    return Ticket(
      id: id ?? 'missing-id',
      workspaceId: workspaceId,
      title: title,
      status: TicketStatus.open,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
  }

  @override
  Future<void> completeTicket(
    String ticketId, {
    required String workspaceId,
    Map<String, dynamic>? output,
    bool force = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelTicket(
    String ticketId, {
    required String workspaceId,
    bool force = false,
  }) async {
    throw UnimplementedError();
  }

  void clear() => createdTickets.clear();
}

class _CreatedTicket {

  _CreatedTicket({
    required this.id,
    required this.title,
    this.description,
    this.assignedAgentId,
    this.pipelineRunId,
    this.pipelineStepId,
    required this.mode,
    this.expectedOutputSchema,
  });
  final String id;
  final String title;
  final String? description;
  final String? assignedAgentId;
  final String? pipelineRunId;
  final String? pipelineStepId;
  final ConversationMode mode;
  final Map<String, dynamic>? expectedOutputSchema;
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

const _workspaceId = 'ws-1';
const _templateId = 'tpl-team-test';
const _stepId = 'dispatch-step';

Agent _testAgent(String id, String name) => Agent(
      id: id,
      name: name,
      title: 'Engineer',
      agentMdPath: '/agents/$id.md',
      workspaceId: _workspaceId,
      skills: AgentSkills([]),
      capabilities: const AgentCapabilities(),
      createdAt: DateTime(2024),
    );

PipelineDefinition _defWithConfig(PipelineNodeConfig config) {
  return PipelineDefinition(
    templateId: _templateId,
    workspaceId: _workspaceId,
    name: 'Test Team Pipeline',
    steps: [
      PipelineStepDefinition(
        id: _stepId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.teamDispatch,
        config: config,
      ),
    ],
  );
}

PipelineContext _ctx({
  Map<String, dynamic> state = const {},
  Map<String, dynamic>? triggerPayload,
}) {
  return PipelineContext(
    pipelineRunId: 'run-1',
    templateId: _templateId,
    stepId: _stepId,
    stepRunId: 'sr-1',
    workspaceId: _workspaceId,
    state: state,
    triggerPayload: triggerPayload,
  );
}

/// Registers the team-dispatch body and returns the registry so tests can look
/// up and invoke the body.
PipelineBodyRegistry _setupRegistry({
  required _FakePipelineTemplateRepository templateRepository,
  required _FakeAgentRepository agentRepository,
  required _FakeTeamRepository teamRepository,
  required _FakeTicketWorkflowPort ticketWorkflow,
}) {
  final registry = PipelineBodyRegistry();
  registerTeamDispatchBody(
    registry,
    templateRepository: templateRepository,
    agentRepository: agentRepository,
    teamRepository: teamRepository,
    ticketWorkflow: ticketWorkflow,
  );
  return registry;
}

void main() {
  group('team.dispatch — allParallel mode', () {
    late _FakePipelineTemplateRepository templateRepo;
    late _FakeAgentRepository agentRepo;
    late _FakeTeamRepository teamRepo;
    late _FakeTicketWorkflowPort ticketWorkflow;
    late PipelineBodyRegistry registry;

    const teamId = 'team-1';
    const agent1Id = 'agent-1';
    const agent2Id = 'agent-2';

    setUp(() {
      templateRepo = _FakePipelineTemplateRepository();
      agentRepo = _FakeAgentRepository();
      teamRepo = _FakeTeamRepository();
      ticketWorkflow = _FakeTicketWorkflowPort();
      registry = _setupRegistry(
        templateRepository: templateRepo,
        agentRepository: agentRepo,
        teamRepository: teamRepo,
        ticketWorkflow: ticketWorkflow,
      );
    });

    test('creates one ticket per member and suspends', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Review this PR: {{prUrl}}',
        label: 'Team Review',
      )));
      agentRepo.add(_testAgent(agent1Id, 'Alice'));
      agentRepo.add(_testAgent(agent2Id, 'Bob'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
        TeamMember(teamId: teamId, agentId: agent2Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx(
        state: {'prUrl': 'https://github.com/foo/bar/pull/42'},
      ));

      expect(result.errorMessage, isNull);
      expect(result.suspendUntilTaskIds, isNotNull);
      expect(result.suspendUntilTaskIds, hasLength(2));
      expect(ticketWorkflow.createdTickets, hasLength(2));
      expect(ticketWorkflow.createdTickets[0].assignedAgentId, agent1Id);
      expect(ticketWorkflow.createdTickets[1].assignedAgentId, agent2Id);
    });

    test('single-member team creates one ticket', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Do the thing',
      )));
      agentRepo.add(_testAgent(agent1Id, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.errorMessage, isNull);
      expect(result.suspendUntilTaskIds, hasLength(1));
      expect(ticketWorkflow.createdTickets, hasLength(1));
      expect(ticketWorkflow.createdTickets[0].assignedAgentId, agent1Id);
    });

    test('missing agent fails with descriptive message', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Do the thing',
      )));
      agentRepo.add(_testAgent(agent1Id, 'Alice'));
      // agent-2 is NOT added
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
        TeamMember(teamId: teamId, agentId: agent2Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing agents'));
      expect(result.errorMessage, contains(agent2Id));
      expect(ticketWorkflow.createdTickets, isEmpty);
    });

    test('all agents missing fails before any ticket created', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Do the thing',
      )));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
        TeamMember(teamId: teamId, agentId: agent2Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('2 team member(s) reference missing agents'));
      expect(ticketWorkflow.createdTickets, isEmpty);
    });

    test('renders prompt template with state and trigger', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Handle {{ticketId}}: {{title}}',
      )));
      agentRepo.add(_testAgent(agent1Id, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx(
        state: {'ticketId': 'TCKT-42'},
        triggerPayload: {'title': 'Fix login bug'},
      ));

      expect(result.errorMessage, isNull);
      final desc = ticketWorkflow.createdTickets.single.description;
      expect(desc, contains('Handle TCKT-42: Fix login bug'));
    });

    test('tickets use conversation mode review', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
      )));
      agentRepo.add(_testAgent(agent1Id, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx());

      for (final t in ticketWorkflow.createdTickets) {
        expect(t.mode, ConversationMode.review);
      }
    });

    test('passes outputSchema to tickets', () async {
      final schema = <String, dynamic>{'type': 'object', 'properties': {}};
      templateRepo.add(_defWithConfig(PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
        outputSchema: schema,
      )));
      agentRepo.add(_testAgent(agent1Id, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx());

      for (final t in ticketWorkflow.createdTickets) {
        expect(t.expectedOutputSchema, equals(schema));
      }
    });

    test('uses label as ticket title prefix', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
        label: 'Custom Label',
      )));
      agentRepo.add(_testAgent(agent1Id, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx());

      expect(ticketWorkflow.createdTickets.single.title, 'Custom Label — Alice');
    });

    test('falls back to stepId when label is null', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
        // label is null
      )));
      agentRepo.add(_testAgent(agent1Id, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx());

      expect(ticketWorkflow.createdTickets.single.title, '$_stepId — Alice');
    });

    test('pipelineRunId and pipelineStepId passed to tickets', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
      )));
      agentRepo.add(_testAgent(agent1Id, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx());

      final t = ticketWorkflow.createdTickets.single;
      expect(t.pipelineRunId, 'run-1');
      expect(t.pipelineStepId, _stepId);
    });
  });

  group('team.dispatch — manager mode', () {
    late _FakePipelineTemplateRepository templateRepo;
    late _FakeAgentRepository agentRepo;
    late _FakeTeamRepository teamRepo;
    late _FakeTicketWorkflowPort ticketWorkflow;
    late PipelineBodyRegistry registry;

    const teamId = 'team-1';
    const leaderAgentId = 'leader-agent';
    const memberAgentId = 'member-agent';

    setUp(() {
      templateRepo = _FakePipelineTemplateRepository();
      agentRepo = _FakeAgentRepository();
      teamRepo = _FakeTeamRepository();
      ticketWorkflow = _FakeTicketWorkflowPort();
      registry = _setupRegistry(
        templateRepository: templateRepo,
        agentRepository: agentRepo,
        teamRepository: teamRepo,
        ticketWorkflow: ticketWorkflow,
      );
    });

    test('creates single ticket for leader and suspends', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Plan the architecture',
        dispatchMode: 'manager',
        label: 'Architecture Plan',
      )));
      agentRepo.add(_testAgent(leaderAgentId, 'Lead'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: leaderAgentId, role: TeamMemberRole.leader),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.errorMessage, isNull);
      expect(result.suspendUntilTaskIds, hasLength(1));
      expect(ticketWorkflow.createdTickets, hasLength(1));
      final t = ticketWorkflow.createdTickets.single;
      expect(t.assignedAgentId, leaderAgentId);
      expect(t.title, contains('Architecture Plan'));
      expect(t.description, contains('delegate_ticket'));
      expect(t.description, contains('complete_ticket'));
      expect(t.mode, ConversationMode.review);
    });

    test('falls back to first member when no leader role', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Plan the architecture',
        dispatchMode: 'manager',
      )));
      agentRepo.add(_testAgent(memberAgentId, 'FirstMember'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: memberAgentId, role: TeamMemberRole.member),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.errorMessage, isNull);
      expect(ticketWorkflow.createdTickets.single.assignedAgentId, memberAgentId);
    });

    test('picks leader over first member when both present', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Plan',
        dispatchMode: 'manager',
      )));
      agentRepo.add(_testAgent(memberAgentId, 'Member'));
      agentRepo.add(_testAgent(leaderAgentId, 'Leader'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: memberAgentId, role: TeamMemberRole.member),
        TeamMember(teamId: teamId, agentId: leaderAgentId, role: TeamMemberRole.leader),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx());

      expect(ticketWorkflow.createdTickets.single.assignedAgentId, leaderAgentId);
    });

    test('fails when leader agent not found', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Plan',
        dispatchMode: 'manager',
      )));
      // leaderAgentId not added to agentRepo
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: leaderAgentId, role: TeamMemberRole.leader),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('leader agent'));
      expect(result.errorMessage, contains(leaderAgentId));
      expect(ticketWorkflow.createdTickets, isEmpty);
    });

    test('renders prompt for manager description', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Analyze {{repo}}',
        dispatchMode: 'manager',
      )));
      agentRepo.add(_testAgent(leaderAgentId, 'Lead'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: leaderAgentId, role: TeamMemberRole.leader),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx(state: {'repo': 'owner/repo'}));

      expect(ticketWorkflow.createdTickets.single.description, contains('Analyze owner/repo'));
    });

    test('passes outputSchema to manager ticket', () async {
      final schema = <String, dynamic>{'type': 'object'};
      templateRepo.add(_defWithConfig(PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Plan',
        dispatchMode: 'manager',
        outputSchema: schema,
      )));
      agentRepo.add(_testAgent(leaderAgentId, 'Lead'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: leaderAgentId, role: TeamMemberRole.leader),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx());

      expect(ticketWorkflow.createdTickets.single.expectedOutputSchema, equals(schema));
    });

    test('falls back to stepId for title when label is null', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Plan',
        dispatchMode: 'manager',
        // label is null
      )));
      agentRepo.add(_testAgent(leaderAgentId, 'Lead'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: leaderAgentId, role: TeamMemberRole.leader),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx());

      expect(ticketWorkflow.createdTickets.single.title, _stepId);
    });
  });

  group('team.dispatch — validation / error cases', () {
    late _FakePipelineTemplateRepository templateRepo;
    late _FakeAgentRepository agentRepo;
    late _FakeTeamRepository teamRepo;
    late _FakeTicketWorkflowPort ticketWorkflow;
    late PipelineBodyRegistry registry;

    const teamId = 'team-1';
    const agentId = 'agent-1';

    setUp(() {
      templateRepo = _FakePipelineTemplateRepository();
      agentRepo = _FakeAgentRepository();
      teamRepo = _FakeTeamRepository();
      ticketWorkflow = _FakeTicketWorkflowPort();
      registry = _setupRegistry(
        templateRepository: templateRepo,
        agentRepository: agentRepo,
        teamRepository: teamRepo,
        ticketWorkflow: ticketWorkflow,
      );
    });

    test('fails when step is missing config (def not found)', () async {
      // No template definition added for the templateId
      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing config'));
    });

    test('fails when teamId is null', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        // teamId is null
        prompt: 'Task',
      )));

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing teamId'));
    });

    test('fails when teamId is empty', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: '',
        prompt: 'Task',
      )));

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing teamId'));
    });

    test('fails when prompt is null', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        // prompt is null
      )));

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing prompt'));
    });

    test('fails when prompt is empty', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: '',
      )));

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing prompt'));
    });

    test('fails when team has no members', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
      )));
      teamRepo.setMembers(teamId, []);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('has no members'));
    });

    test('template not found for templateId returns missing config error', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
      )));
      // Use a context with a different templateId
      const ctx = PipelineContext(
        pipelineRunId: 'run-1',
        templateId: 'unknown-template',
        stepId: _stepId,
        stepRunId: 'sr-1',
        workspaceId: _workspaceId,
        state: {},
      );

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(ctx);

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing config'));
    });

    test('step not found in template returns missing config error', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
      )));
      const ctx = PipelineContext(
        pipelineRunId: 'run-1',
        templateId: _templateId,
        stepId: 'nonexistent-step',
        stepRunId: 'sr-1',
        workspaceId: _workspaceId,
        state: {},
      );

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(ctx);

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing config'));
    });

    test('default dispatch mode is allParallel (no manager path)', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
        // dispatchMode not set — defaults to allParallel
      )));
      agentRepo.add(_testAgent(agentId, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agentId),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.errorMessage, isNull);
      expect(result.suspendUntilTaskIds, hasLength(1));
      // Manager path inserts delegation instructions; allParallel does not
      final desc = ticketWorkflow.createdTickets.single.description;
      expect(desc, isNot(contains('delegate_ticket')));
      expect(desc, contains('complete_ticket'));
    });
  });

  group('team.dispatch — prompt rendering edge cases', () {
    late _FakePipelineTemplateRepository templateRepo;
    late _FakeAgentRepository agentRepo;
    late _FakeTeamRepository teamRepo;
    late _FakeTicketWorkflowPort ticketWorkflow;
    late PipelineBodyRegistry registry;

    const teamId = 'team-1';
    const agentId = 'agent-1';

    setUp(() {
      templateRepo = _FakePipelineTemplateRepository();
      agentRepo = _FakeAgentRepository();
      teamRepo = _FakeTeamRepository();
      ticketWorkflow = _FakeTicketWorkflowPort();
      registry = _setupRegistry(
        templateRepository: templateRepo,
        agentRepository: agentRepo,
        teamRepository: teamRepo,
        ticketWorkflow: ticketWorkflow,
      );
    });

    test('unresolved placeholders render as empty string', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Hello {{missing}} world',
      )));
      agentRepo.add(_testAgent(agentId, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agentId),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx());

      final desc = ticketWorkflow.createdTickets.single.description;
      expect(desc, contains('Hello  world'));
    });

    test('state takes precedence over trigger for bare keys', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Value: {{key}}',
      )));
      agentRepo.add(_testAgent(agentId, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agentId),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx(
        state: {'key': 'from-state'},
        triggerPayload: {'key': 'from-trigger'},
      ));

      final desc = ticketWorkflow.createdTickets.single.description;
      expect(desc, contains('Value: from-state'));
    });

    test('trigger fills in when state is absent', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Value: {{key}}',
      )));
      agentRepo.add(_testAgent(agentId, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agentId),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx(triggerPayload: {'key': 'from-trigger'}));

      final desc = ticketWorkflow.createdTickets.single.description;
      expect(desc, contains('Value: from-trigger'));
    });

    test('no placeholders in prompt — renders literally', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Plain prompt with no vars',
      )));
      agentRepo.add(_testAgent(agentId, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agentId),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx());

      final desc = ticketWorkflow.createdTickets.single.description;
      expect(desc, contains('Plain prompt with no vars'));
    });

    test('ticketIds are unique uuids', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
      )));
      agentRepo.add(_testAgent('a1', 'Alice'));
      agentRepo.add(_testAgent('a2', 'Bob'));
      agentRepo.add(_testAgent('a3', 'Charlie'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: 'a1'),
        TeamMember(teamId: teamId, agentId: 'a2'),
        TeamMember(teamId: teamId, agentId: 'a3'),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      final ids = result.suspendUntilTaskIds!;
      expect(ids.toSet().length, 3); // all unique
      // UUID v4 format: 36 chars, hyphens in standard positions
      for (final id in ids) {
        expect(id.length, 36);
        expect(RegExp(r'^[\da-f]{8}-[\da-f]{4}-4[\da-f]{3}-[89ab][\da-f]{3}-[\da-f]{12}$').hasMatch(id), isTrue);
      }
    });

    test('ticket description includes coordination footer', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
      )));
      agentRepo.add(_testAgent(agentId, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agentId),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      final ticketId = result.suspendUntilTaskIds!.single;
      final desc = ticketWorkflow.createdTickets.single.description!;
      expect(desc, contains('Pipeline coordination'));
      expect(desc, contains('complete_ticket'));
      expect(desc, contains(ticketId));
    });

    test('empty state and null trigger payload still works', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
      )));
      agentRepo.add(_testAgent(agentId, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agentId),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx(state: {}));

      expect(result.errorMessage, isNull);
      expect(result.suspendUntilTaskIds, hasLength(1));
    });

    test('team with many members creates matching number of tickets', () async {
      const memberCount = 20;
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
      )));
      final members = <TeamMember>[];
      for (var i = 0; i < memberCount; i++) {
        final id = 'agent-$i';
        agentRepo.add(_testAgent(id, 'Agent$i'));
        members.add(TeamMember(teamId: teamId, agentId: id));
      }
      teamRepo.setMembers(teamId, members);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.errorMessage, isNull);
      expect(result.suspendUntilTaskIds, hasLength(memberCount));
      expect(ticketWorkflow.createdTickets, hasLength(memberCount));
    });

    test('allParallel dispatching preserves member ordering in tickets', () async {
      templateRepo.add(_defWithConfig(const PipelineNodeConfig(
        teamId: teamId,
        prompt: 'Task',
      )));
      final ids = ['z-alice', 'a-bob', 'm-charlie'];
      final members = <TeamMember>[];
      for (final id in ids) {
        agentRepo.add(_testAgent(id, id));
        members.add(TeamMember(teamId: teamId, agentId: id));
      }
      teamRepo.setMembers(teamId, members);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      await body(_ctx());

      expect(ticketWorkflow.createdTickets.map((t) => t.assignedAgentId).toList(), ids);
    });
  });
}
