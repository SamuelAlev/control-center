import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/teams/domain/ports/team_leader_dispatch_port.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_infra/src/dispatch/ticket_settled_wakes.dart';

/// Dispatches a team's leader in the team's routed space, and wakes it when
/// a member it woke finished.
///
/// The routed space is the ticket's: reused on every routing, created once
/// (and recorded on the ticket) when the ticket has none. Reuses the
/// standard messaging → dispatch path (the same one a `@`-mention uses), so
/// the leader's delegation links (`[@Name](mention://agent/<uuid>)` from the
/// roster) resolve and summon members through the existing flow. A member's
/// finished run reaches the leader as a `childCompleted` wake through the
/// wake queue ([wakeLeader]), never as a new space.
class MessagingTeamLeaderDispatch implements TeamLeaderDispatchPort {
  /// Creates a [MessagingTeamLeaderDispatch].
  MessagingTeamLeaderDispatch(
    this._messaging, {
    required this._tickets,
    required this._agents,
    required this._conversations,
    required this._facts,
    this._clock = DateTime.now,
  });

  final MessagingPort _messaging;
  final TicketRepository _tickets;
  final AgentRepository _agents;
  final ConversationRepository _conversations;
  final CompletionFacts _facts;
  final DateTime Function() _clock;

  /// Where leader wakes go (`WakeQueueService.enqueue`). Late-bound: the
  /// queue is built after team routing starts. Null inserts nothing.
  Future<bool> Function(Wake wake)? sink;

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
    try {
      final routed =
          spaceId ?? await _routedSpace(workspaceId, ticketId, agentId);
      await _messaging.sendUserMessage(workspaceId, routed, prompt);
      await _messaging.dispatchAgent(
        workspaceId: workspaceId,
        spaceId: routed,
        agentId: agentId,
        prompt: prompt,
        ticketId: ticketId,
        wakeContext: WakeContext(
          wakeReason: reason,
          startedByRunId: startedByRunId,
          ticketId: ticketId,
        ),
      );
    } on Object catch (e, st) {
      CcDomainLog.error(
        'MessagingTeamLeaderDispatch: failed to dispatch leader $agentId',
        e,
        st,
      );
    }
  }

  /// The ticket's space, or a new one recorded on the ticket. A concurrent
  /// routing that recorded its own first wins: its space is used.
  Future<String> _routedSpace(
    String workspaceId,
    String? ticketId,
    String agentId,
  ) async {
    final ticket = ticketId == null
        ? null
        : await _tickets.getById(workspaceId, ticketId);
    final existing = ticket?.spaceId;
    if (existing != null) {
      return existing;
    }
    final space = await _messaging.createSpace(
      workspaceId,
      ticketId != null ? 'Team routing · $ticketId' : 'Team routing',
      [agentId],
    );
    if (ticket != null && ticket.workspaceId == workspaceId) {
      try {
        await _tickets.update(
          ticket.copyWith(spaceId: space.id),
          expectedVersion: ticket.version,
        );
      } on Object {
        final winner = (await _tickets.getById(
          workspaceId,
          ticket.id,
        ))?.spaceId;
        if (winner != null) {
          return winner;
        }
      }
    }
    return space.id;
  }

  @override
  Future<void> wakeLeader(TeamMemberSettled settled) async {
    final sink = this.sink;
    if (sink == null) {
      return;
    }
    final ws = settled.workspaceId;
    try {
      final conversation = await _conversations.getById(
        workspaceId: ws,
        conversationId: settled.leaderConversationId,
      );
      if (conversation == null) {
        return;
      }
      final leaderRunId = settled.leaderRunId;
      final leaderRun = leaderRunId == null
          ? null
          : await _facts.run(ws, leaderRunId);
      final memberRun = await _facts.run(ws, settled.memberRunId);
      final answer = await _facts.finalAnswer(ws, settled.memberRunId);
      final status = settled.endReason == 'error'
          ? 'failed'
          : settled.endReason;
      await sink(
        childCompletedWake(
          id: 'team-${settled.teamId}-run-${settled.memberRunId}',
          workspaceId: ws,
          spaceId: conversation.spaceId,
          conversationId: settled.leaderConversationId,
          delegatorAgentId: settled.leaderAgentId,
          workerAgentId: settled.memberAgentId,
          workerName:
              (await _agents.getById(ws, settled.memberAgentId))?.name ??
              settled.memberAgentId,
          status: status,
          dedupKey: 'team:${settled.teamId}:run:${settled.memberRunId}',
          now: _clock(),
          payload: answer,
          ticketId: settled.ticketId,
          workerRunId: settled.memberRunId,
          workerConversationId: settled.memberConversationId,
          // The wake continues the leader's run, for whoever it acted for.
          requestedByUserId: leaderRun?.agentId == settled.leaderAgentId
              ? leaderRun?.requestedByUserId
              : null,
          summary: memberRun?.summary ?? answer,
          verified: memberRun == null ? null : await _facts.verified(memberRun),
          fields: {
            WakeFields.teamId: settled.teamId,
            WakeFields.endReason: settled.endReason,
          },
        ),
      );
    } on Object catch (e, st) {
      CcDomainLog.error(
        'MessagingTeamLeaderDispatch: failed to wake leader '
        '${settled.leaderAgentId}',
        e,
        st,
      );
    }
  }
}
