import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
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
  final List<
    ({
      String agentId,
      String prompt,
      String? ticketId,
      String? spaceId,
      String? startedByRunId,
    })
  >
  calls = [];
  final List<TeamMemberSettled> woken = [];
  @override
  Future<void> dispatchLeader({
    required String workspaceId,
    required String agentId,
    required String prompt,
    required WakeReason reason,
    required String? startedByRunId,
    String? ticketId,
    String? spaceId,
  }) async {
    calls.add((
      agentId: agentId,
      prompt: prompt,
      ticketId: ticketId,
      spaceId: spaceId,
      startedByRunId: startedByRunId,
    ));
  }

  @override
  Future<void> wakeLeader(TeamMemberSettled settled) async =>
      woken.add(settled);
}

class _FakeWakes implements WakeRepository {
  final Map<String, Wake> byId = {};
  @override
  Future<Wake?> getById(String workspaceId, String id) async {
    final wake = byId[id];
    return wake?.workspaceId == workspaceId ? wake : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  Future<List<Team>> teamsForWorkspace(String workspaceId) async => [team];
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
  late _FakeWakes wakes;

  final ticket = Ticket(
    id: 'TIX-1',
    workspaceId: 'ws1',
    title: 'Fix the header',
    status: TicketStatus.open,
    assignedTeamId: 'team1',
    spaceId: 'sp-routed',
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
    wakes = _FakeWakes();
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
        'run-lead': AgentRunLog(
          id: 'run-lead',
          agentId: 'lead',
          conversationId: 'c-lead',
          startedAt: DateTime.utc(2026, 1, 1),
          status: RunStatus.completed,
          ticketId: 'TIX-1',
        ),
      }),
      wakeRepository: wakes,
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
          assigningRunId: null,
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

  /// The wake [from] sent [to] (a mention or a message), with no ask.
  Wake peerWake(String id, {String from = 'lead', String to = 'alice'}) =>
      wakes.byId[id] = Wake(
        id: id,
        workspaceId: 'ws1',
        spaceId: 'sp-dm',
        conversationId: 'c-dm',
        agentId: to,
        reason: WakeReason.peerMessage,
        payload: 'Take the header.',
        dedupKey: 'k:$id',
        notBefore: DateTime.utc(2026, 1, 1),
        detail: WakeDetail(
          sourceAgentId: from,
          sourceRunId: 'run-$from',
          sourceConversationId: 'c-$from',
        ),
        createdAt: DateTime.utc(2026, 1, 1),
      );

  AgentRunSettled settled({
    String agentId = 'alice',
    List<String> wakeIds = const ['wk-1'],
    RunEndReason endReason = RunEndReason.completed,
  }) => AgentRunSettled(
    agentId: agentId,
    workspaceId: 'ws1',
    spaceId: 'sp-dm',
    conversationId: 'c-dm',
    runId: 'run-$agentId',
    status: endReason == RunEndReason.completed
        ? RunStatus.completed
        : RunStatus.error,
    endReason: endReason,
    costMicros: 0,
    limitResetsAt: null,
    wakeIds: wakeIds,
    requestedByUserId: null,
    wakeReason: WakeReason.peerMessage,
    occurredAt: DateTime.utc(2026, 1, 1),
  );

  test('assignment reuses the ticket\'s routed space', () async {
    bus.publish(
      TicketAssigned(
        assigningRunId: null,
        ticketId: 'TIX-1',
        ticketTitle: 'Fix the header',
        assignedTeamId: 'team1',
        workspaceId: 'ws1',
        occurredAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await settle();
    expect(dispatch.calls.single.spaceId, 'sp-routed');
  });

  test('an agent run\'s assignment routes the leader with that run as its '
      'starter; a person\'s carries none', () async {
    for (final run in ['run-assigner', null]) {
      bus.publish(
        TicketAssigned(
          assigningRunId: run,
          ticketId: 'TIX-1',
          ticketTitle: 'Fix the header',
          assignedTeamId: 'team1',
          workspaceId: 'ws1',
          occurredAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await settle();
    }
    expect(dispatch.calls.map((c) => c.startedByRunId), [
      'run-assigner',
      null,
    ]);
  });

  test('a member the leader woke finishing wakes the leader once, in its '
      'own conversation, with no new dispatch', () async {
    peerWake('wk-1');
    bus.publish(settled());
    await settle();
    expect(dispatch.calls, isEmpty, reason: 'no new space or run prompt');
    final woken = dispatch.woken.single;
    expect(woken.leaderAgentId, 'lead');
    expect(woken.teamId, 'team1');
    expect(woken.leaderConversationId, 'c-lead');
    expect(woken.leaderRunId, 'run-lead');
    expect(woken.memberAgentId, 'alice');
    expect(woken.memberRunId, 'run-alice');
    expect(woken.ticketId, 'TIX-1');
    expect(woken.endReason, 'completed');
  });

  test('a member run no leader woke wakes nobody', () async {
    peerWake('wk-1', from: 'stranger');
    bus.publish(settled());
    bus.publish(settled(wakeIds: const []));
    await settle();
    expect(dispatch.woken, isEmpty);
  });

  test('a member run the server stop ended wakes no leader', () async {
    peerWake('wk-1');
    bus.publish(settled(endReason: RunEndReason.serverStopped));
    await settle();
    expect(dispatch.woken, isEmpty);
  });

  test('a recorded no_action evaluation suppresses re-triggers', () async {
    activity.noActionExists = true;
    peerWake('wk-1');
    bus.publish(settled());
    await settle();
    expect(dispatch.woken, isEmpty);
  });

  test('the leader finishing does not re-trigger itself', () async {
    peerWake('wk-1', from: 'lead', to: 'lead');
    bus.publish(settled(agentId: 'lead'));
    await settle();
    expect(dispatch.woken, isEmpty);
  });
}
