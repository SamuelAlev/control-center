import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
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
/// * **Re-trigger** — when a member's run that the leader's own wake started
///   (an `@mention` or a message from the leader: the wake's source is the
///   leader) settles (`AgentRunSettled`), the leader is woken with a
///   `childCompleted` wake in the conversation it woke the member from,
///   UNLESS it has already recorded a `no_action` evaluation for the ticket
///   (the dedup guard that stops the infinite re-trigger loop). The member's
///   run is found by the wake that started it, not by a ticket id on its run
///   log; work the leader handed over with `delegate_task` wakes it through
///   the ticket's own completion wake instead, and an ask through its reply.
///
/// Pure-Dart and event-driven: it composes repositories + a dispatch port, so
/// it is fully unit-testable with fakes.
class TeamRoutingService {
  /// Creates a [TeamRoutingService].
  TeamRoutingService({
    required this._eventBus,
    required TeamRepository teamRepository,
    required AgentRepository agentRepository,
    required TicketRepository ticketRepository,
    required AgentRunLogRepository runLogRepository,
    required WakeRepository wakeRepository,
    required TeamActivityRepository activityRepository,
    required TeamLeaderDispatchPort leaderDispatch,
  }) : _teams = teamRepository,
       _agents = agentRepository,
       _tickets = ticketRepository,
       _runLogs = runLogRepository,
       _wakes = wakeRepository,
       _activity = activityRepository,
       _dispatch = leaderDispatch;

  final DomainEventBus _eventBus;
  final TeamRepository _teams;
  final AgentRepository _agents;
  final TicketRepository _tickets;
  final AgentRunLogRepository _runLogs;
  final WakeRepository _wakes;
  final TeamActivityRepository _activity;
  final TeamLeaderDispatchPort _dispatch;

  final List<StreamSubscription<DomainEvent>> _subs = [];

  /// Begins listening for team-assignment and member-completion events.
  void start() {
    _subs.add(_eventBus.on<TicketAssigned>().listen(_onTicketAssigned));
    _subs.add(_eventBus.on<AgentRunSettled>().listen(_onRunCompleted));
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
    final ticket = await _tickets.getById(workspaceId, event.ticketId);
    await _routeToLeader(
      workspaceId: workspaceId,
      teamId: teamId,
      ticketId: event.ticketId,
      title: event.ticketTitle,
      body: event.ticketBody,
      cause: 'the ticket was assigned to the team',
      reason: WakeReason.assignment,
      spaceId: ticket?.workspaceId == workspaceId ? ticket?.spaceId : null,
      // The agent run whose `assign_ticket` call made the assignment: the
      // leader's run records it as its starter (null for a person's).
      startedByRunId: event.assigningRunId,
    );
  }

  Future<void> _onRunCompleted(AgentRunSettled event) async {
    // A run the server's stop ended did not finish its work: there is
    // nothing for the leader to evaluate.
    if (event.endReason == RunEndReason.serverStopped) {
      return;
    }
    try {
      await _wakeLeaderAfterRun(event);
    } on DeletedWorkspaceException {
      // The run outlived its workspace: there is no team left to wake.
    }
  }

  Future<void> _wakeLeaderAfterRun(AgentRunSettled event) async {
    final workspaceId = event.workspaceId;
    final woken = <String>{};
    for (final wakeId in event.wakeIds) {
      final wake = await _wakes.getById(workspaceId, wakeId);
      // A leader's mention or message; an ask is answered by its reply.
      if (wake == null ||
          wake.workspaceId != workspaceId ||
          wake.agentId != event.agentId ||
          wake.reason != WakeReason.peerMessage ||
          wake.detail.askId != null) {
        continue;
      }
      final leaderId = wake.detail.sourceAgentId;
      // The leader's own completion never re-triggers itself.
      if (leaderId == null ||
          leaderId == event.agentId ||
          !woken.add(leaderId)) {
        continue;
      }
      final teamId = await _teamLedBy(workspaceId, leaderId, event.agentId);
      if (teamId == null) {
        continue;
      }
      final leaderRunId = wake.detail.sourceRunId;
      final leaderRun = leaderRunId == null
          ? null
          : await _runLogs.getById(workspaceId, leaderRunId);
      final ticketId = wake.detail.ticketId ?? leaderRun?.ticketId;
      // No-action dedup: once the leader declared "nothing more to do", stop.
      if (ticketId != null &&
          await _activity.hasNoActionEvaluationForTicket(
            workspaceId,
            teamId,
            ticketId,
          )) {
        CcDomainLog.info(
          'TeamRouting: suppressing re-trigger for ticket $ticketId — leader '
          'already recorded a no_action evaluation.',
        );
        continue;
      }
      final leaderConversation =
          wake.detail.sourceConversationId ??
          leaderRun?.conversationId ??
          event.conversationId;
      if (leaderConversation == null) {
        continue;
      }
      await _dispatch.wakeLeader(
        TeamMemberSettled(
          workspaceId: workspaceId,
          teamId: teamId,
          leaderAgentId: leaderId,
          leaderConversationId: leaderConversation,
          leaderRunId: leaderRun?.id,
          memberAgentId: event.agentId,
          memberRunId: event.runId,
          memberConversationId: event.conversationId,
          ticketId: ticketId,
          endReason: event.endReason.wire,
        ),
      );
    }
  }

  /// The team [leaderId] leads that has [memberId] as a member, or null.
  Future<String?> _teamLedBy(
    String workspaceId,
    String leaderId,
    String memberId,
  ) async {
    for (final team in await _teams.teamsForWorkspace(workspaceId)) {
      if (team.workspaceId != workspaceId ||
          !team.hasLeader ||
          team.leaderId != leaderId) {
        continue;
      }
      final members = await _teams.membersOf(workspaceId, team.id);
      if (members.any((m) => m.agentId == memberId)) {
        return team.id;
      }
    }
    return null;
  }

  Future<void> _routeToLeader({
    required String workspaceId,
    required String teamId,
    required String ticketId,
    required String title,
    String? body,
    required String cause,
    required WakeReason reason,
    required String? startedByRunId,
    String? spaceId,
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
        reason: reason,
        startedByRunId: startedByRunId,
        ticketId: ticketId,
        spaceId: spaceId,
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
