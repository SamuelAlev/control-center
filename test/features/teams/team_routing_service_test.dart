import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/teams/domain/ports/team_leader_dispatch_port.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_activity_repository.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_domain/features/teams/domain/services/team_routing_service.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _DispatchSpy implements TeamLeaderDispatchPort {
  final List<({String agentId, String prompt, String? ticketId})> calls = [];
  @override
  Future<void> dispatchLeader({
    required String workspaceId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? channelId,
  }) async {
    calls.add((agentId: agentId, prompt: prompt, ticketId: ticketId));
  }
}

class _FakeTeams implements TeamRepository {
  _FakeTeams(this.team, this.members);
  final Team team;
  final List<TeamMember> members;
  @override
  Future<Team?> getTeam(String workspaceId, String id) async =>
      id == team.id ? team : null;
  @override
  Future<List<TeamMember>> membersOf(String workspaceId, String teamId) async =>
      members;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAgents implements AgentRepository {
  _FakeAgents(this.agents);
  final List<Agent> agents;
  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(agents);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTickets implements TicketRepository {
  _FakeTickets(this.ticket);
  final Ticket ticket;
  @override
  Future<Ticket?> getById(String workspaceId, String id) async =>
      id == ticket.id ? ticket : null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRunLogs implements AgentRunLogRepository {
  _FakeRunLogs(this.byId);
  final Map<String, AgentRunLog> byId;
  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async => byId[id];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeActivity implements TeamActivityRepository {
  bool noActionExists = false;
  @override
  Future<bool> hasNoActionEvaluationForTicket(
    String workspaceId,
    String teamId,
    String ticketId,
  ) async => noActionExists;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Agent _agent(String id, String name, {List<String> skills = const []}) => Agent(
  id: id,
  name: name,
  title: '$name title',
  agentMdPath: '/a/$id.md',
  workspaceId: 'ws1',
  skills: AgentSkills(skills),
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  late DomainEventBus bus;
  late _DispatchSpy dispatch;
  late _FakeActivity activity;
  late TeamRoutingService service;

  final ticket = Ticket(
    id: 'TIX-1',
    workspaceId: 'ws1',
    title: 'Fix the header',
    status: TicketStatus.open,
    assignedTeamId: 'team1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
  final team = Team(
    id: 'team1',
    workspaceId: 'ws1',
    name: 'Frontend',
    leaderId: 'lead',
    createdAt: DateTime.utc(2026, 1, 1),
  );
  final members = [
    TeamMember(teamId: 'team1', agentId: 'lead', role: TeamMemberRole.leader),
    TeamMember(teamId: 'team1', agentId: 'alice'),
  ];
  final agents = [
    _agent('lead', 'Lina'),
    _agent('alice', 'Alice', skills: ['flutter']),
  ];

  setUp(() {
    bus = DomainEventBus();
    dispatch = _DispatchSpy();
    activity = _FakeActivity();
    service = TeamRoutingService(
      eventBus: bus,
      teamRepository: _FakeTeams(team, members),
      agentRepository: _FakeAgents(agents),
      ticketRepository: _FakeTickets(ticket),
      runLogRepository: _FakeRunLogs({
        'run-alice': AgentRunLog(
          id: 'run-alice',
          agentId: 'alice',
          startedAt: DateTime.utc(2026, 1, 1),
          status: RunStatus.completed,
          ticketId: 'TIX-1',
        ),
      }),
      activityRepository: activity,
      leaderDispatch: dispatch,
    )..start();
  });

  tearDown(() => service.dispose());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test(
    'assigning a ticket to a team dispatches the leader with the roster',
    () async {
      bus.publish(
        TicketAssigned(
          ticketId: 'TIX-1',
          ticketTitle: 'Fix the header',
          assignedTeamId: 'team1',
          workspaceId: 'ws1',
          occurredAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await settle();
      expect(dispatch.calls, hasLength(1));
      expect(dispatch.calls.single.agentId, 'lead');
      expect(
        dispatch.calls.single.prompt,
        contains('[@Alice](mention://agent/alice)'),
      );
      expect(dispatch.calls.single.prompt, contains('record_team_activity'));
    },
  );

  test('a delegated member finishing re-triggers the leader', () async {
    bus.publish(
      AgentRunCompleted(
        agentId: 'alice',
        workspaceId: 'ws1',
        conversationId: null,
        runId: 'run-alice',
        occurredAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await settle();
    expect(dispatch.calls, hasLength(1));
    expect(dispatch.calls.single.agentId, 'lead');
  });

  test('a recorded no_action evaluation suppresses re-triggers', () async {
    activity.noActionExists = true;
    bus.publish(
      AgentRunCompleted(
        agentId: 'alice',
        workspaceId: 'ws1',
        conversationId: null,
        runId: 'run-alice',
        occurredAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await settle();
    expect(dispatch.calls, isEmpty);
  });

  test('the leader finishing does not re-trigger itself', () async {
    bus.publish(
      AgentRunCompleted(
        agentId: 'lead',
        workspaceId: 'ws1',
        conversationId: null,
        runId: 'run-lead',
        occurredAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await settle();
    expect(dispatch.calls, isEmpty);
  });
}
