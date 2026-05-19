import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/teams/domain/ports/team_leader_dispatch_port.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_activity_repository.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_domain/features/teams/domain/services/team_operating_protocol.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';

/// Routes team-assigned work to the team **leader** and keeps the
/// leader-coordination loop alive without looping forever.
///
/// Two entry points:
/// * **Assignment** — when a ticket is assigned to a team (`TicketAssigned`
///   with a non-null `assignedTeamId`), the leader is dispatched with the hard
///   operating protocol + the skill-surfaced roster so it can delegate to the
///   best-suited member.
/// * **Re-trigger** — when a delegated member finishes a run for that ticket
///   (`AgentRunCompleted`), the leader is re-woken to evaluate, UNLESS it has
///   already recorded a `no_action` evaluation for the ticket (the dedup guard
///   that stops the infinite re-trigger loop).
///
/// Pure-Dart and event-driven: it composes repositories + a dispatch port, so
/// it is fully unit-testable with fakes.
class TeamRoutingService {
  /// Creates a [TeamRoutingService].
  TeamRoutingService({
    required DomainEventBus eventBus,
    required TeamRepository teamRepository,
    required AgentRepository agentRepository,
    required TicketRepository ticketRepository,
    required AgentRunLogRepository runLogRepository,
    required TeamActivityRepository activityRepository,
    required TeamLeaderDispatchPort leaderDispatch,
  }) : _eventBus = eventBus,
       _teams = teamRepository,
       _agents = agentRepository,
       _tickets = ticketRepository,
       _runLogs = runLogRepository,
       _activity = activityRepository,
       _dispatch = leaderDispatch;

  final DomainEventBus _eventBus;
  final TeamRepository _teams;
  final AgentRepository _agents;
  final TicketRepository _tickets;
  final AgentRunLogRepository _runLogs;
  final TeamActivityRepository _activity;
  final TeamLeaderDispatchPort _dispatch;

  final List<StreamSubscription<DomainEvent>> _subs = [];

  /// Begins listening for team-assignment and member-completion events.
  void start() {
    _subs.add(_eventBus.on<TicketAssigned>().listen(_onTicketAssigned));
    _subs.add(_eventBus.on<AgentRunCompleted>().listen(_onRunCompleted));
  }

  /// Stops listening.
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
  }

  Future<void> _onTicketAssigned(TicketAssigned event) async {
    final teamId = event.assignedTeamId;
    final workspaceId = event.workspaceId;
    if (teamId == null) {
      return;
    }
    await _routeToLeader(
      workspaceId: workspaceId,
      teamId: teamId,
      ticketId: event.ticketId,
      title: event.ticketTitle,
      body: event.ticketBody,
      cause: 'the ticket was assigned to the team',
    );
  }

  Future<void> _onRunCompleted(AgentRunCompleted event) async {
    final workspaceId = event.workspaceId;
    if (workspaceId == null) {
      return;
    }
    final ticketId = await _ticketIdForRun(event, workspaceId);
    if (ticketId == null) {
      return;
    }
    final ticket = await _tickets.getById(workspaceId, ticketId);
    if (ticket == null || ticket.workspaceId != workspaceId) {
      return;
    }
    final teamId = ticket.assignedTeamId;
    if (teamId == null) {
      return;
    }
    final team = await _teams.getTeam(workspaceId, teamId);
    if (team == null || team.workspaceId != workspaceId || !team.hasLeader) {
      return;
    }
    // The leader's own completion never re-triggers itself.
    if (event.agentId == team.leaderId) {
      return;
    }
    // Only a member of this team re-wakes the leader.
    final members = await _teams.membersOf(workspaceId, teamId);
    if (!members.any((m) => m.agentId == event.agentId)) {
      return;
    }
    // No-action dedup: once the leader declared "nothing more to do", stop.
    if (await _activity.hasNoActionEvaluationForTicket(
      workspaceId,
      teamId,
      ticketId,
    )) {
      CcDomainLog.info(
        'TeamRouting: suppressing re-trigger for ticket $ticketId — leader '
        'already recorded a no_action evaluation.',
      );
      return;
    }
    await _routeToLeader(
      workspaceId: workspaceId,
      teamId: teamId,
      ticketId: ticketId,
      title: ticket.title,
      body: ticket.description,
      cause: 'member ${event.agentId} finished their run',
    );
  }

  Future<String?> _ticketIdForRun(
    AgentRunCompleted event,
    String workspaceId,
  ) async {
    final runId = event.runId;
    if (runId == null) {
      return null;
    }
    final log = await _runLogs.getById(workspaceId, runId);
    return log?.ticketId;
  }

  Future<void> _routeToLeader({
    required String workspaceId,
    required String teamId,
    required String ticketId,
    required String title,
    String? body,
    required String cause,
  }) async {
    try {
      final team = await _teams.getTeam(workspaceId, teamId);
      if (team == null || team.workspaceId != workspaceId || !team.hasLeader) {
        return;
      }
      final members = await _teams.membersOf(workspaceId, teamId);
      final agents = await _agents.watchByWorkspace(workspaceId).first;
      final agentsById = {for (final a in agents) a.id: a};
      final leader = agentsById[team.leaderId];
      if (leader == null) {
        CcDomainLog.warning(
          'TeamRouting: team ${team.name} leader ${team.leaderId} not found '
          'in workspace $workspaceId — cannot route.',
        );
        return;
      }
      final protocol = TeamOperatingProtocol.build(
        team: team,
        members: members,
        agentsById: agentsById,
        ticketId: ticketId,
      );
      final buf = StringBuffer()
        ..writeln(protocol)
        ..writeln()
        ..writeln('## Request (re-trigger cause: $cause)')
        ..writeln('Ticket `$ticketId` — $title');
      if (body != null && body.trim().isNotEmpty) {
        buf
          ..writeln()
          ..writeln(body.trim());
      }
      await _dispatch.dispatchLeader(
        workspaceId: workspaceId,
        agentId: leader.id,
        prompt: buf.toString().trimRight(),
        ticketId: ticketId,
      );
      CcDomainLog.info(
        'TeamRouting: dispatched leader ${leader.name} for team ${team.name} '
        'on ticket $ticketId ($cause).',
      );
    } on Object catch (e, st) {
      CcDomainLog.error('TeamRouting: failed to route ticket $ticketId', e, st);
    }
  }
}
