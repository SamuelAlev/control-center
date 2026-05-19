import 'dart:async';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/events/agent_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/features/pipelines/domain/ports/ticket_workflow_port.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';

/// Bridges `AgentRunCompleted` events into the ticket layer so that
/// `pipeline.promptAgent` step bodies don't get stuck if the dispatched agent
/// never calls `complete_ticket`.
///
/// This is a **fallback safety net** — agents are expected to call
/// `complete_ticket` explicitly with structured output. When an agent finishes
/// a run without completing the ticket, this listener auto-completes it using
/// the agent's last channel message as a best-effort output. The explicit
/// `complete_ticket` path always wins because [TicketWorkflowPort.completeTicket]
/// is a no-op on terminal tickets.
///
/// Every auto-completion logs a warning so the UI can flag it for review.
class AgentRunTaskCompleter {
  /// Creates an [AgentRunTaskCompleter].
  AgentRunTaskCompleter({
    required this.eventBus,
    required this.ticketRepository,
    required this.ticketWorkflow,
    required this.messagingRepository,
  });

  /// Event bus we subscribe to.
  final DomainEventBus eventBus;

  /// Read-only access to tickets; used to find work owned by the agent.
  final TicketRepository ticketRepository;

  /// Write path for marking tickets complete.
  final TicketWorkflowPort ticketWorkflow;

  /// Used to harvest the agent's last channel message as task output.
  final MessagingRepository messagingRepository;

  StreamSubscription<AgentRunCompleted>? _sub;

  /// Start listening for `AgentRunCompleted` events.
  void start() {
    _sub = eventBus.on<AgentRunCompleted>().listen(_onCompleted);
  }

  /// Stop listening.
  void dispose() {
    _sub?.cancel();
  }

  Future<void> _onCompleted(AgentRunCompleted event) async {
    try {
      // Pipeline tickets always carry a workspace; a workspace-less run has
      // none to auto-complete. Bailing keeps the workspace-scoped `forAgent`
      // query honest (no cross-workspace fan-out).
      final workspaceId = event.workspaceId;
      if (workspaceId == null) {
        return;
      }
      final tickets = await ticketRepository.forAgent(workspaceId, event.agentId);
      final candidates = tickets.where(
        (t) =>
            !t.isTerminal &&
            t.pipelineRunId != null &&
            t.pipelineStepId != null &&
            (event.conversationId == null ||
                t.channelId == event.conversationId),
      );

      if (candidates.isEmpty) {
        return;
      }

      String? lastAgentMessage;
      if (event.conversationId != null) {
        lastAgentMessage = await _latestAgentMessage(
          event.conversationId!,
          event.agentId,
        );
      }

      for (final ticket in candidates) {
        // A ticket that declares an output contract cannot be satisfied by
        // free-form chat text — auto-completing from the last message would be
        // a backdoor around the schema. Fail it loudly instead so the pipeline
        // step surfaces the problem rather than silently merging garbage.
        if (ticket.expectedOutputSchema != null) {
          AppLog.w(
            'AgentRunTaskCompleter',
            'Failing ticket ${ticket.id} — agent ${event.agentId} ended '
            'without calling complete_ticket, but the ticket requires '
            'structured output (expected_output_schema is set).',
          );
          await ticketWorkflow.failTicket(
            ticket.id,
            'Agent run ended without calling complete_ticket; this ticket '
            'requires structured output matching its expected output schema.',
            workspaceId: ticket.workspaceId,
          );
          continue;
        }
        AppLog.w(
          'AgentRunTaskCompleter',
          'Auto-completing ticket ${ticket.id} — '
          'agent ${event.agentId} finished without calling complete_ticket. '
          'This is a fallback; agents should call complete_ticket explicitly.',
        );
        await ticketWorkflow.completeTicket(
          ticket.id,
          workspaceId: ticket.workspaceId,
          output: {
            'result': lastAgentMessage ?? '',
          },
        );
      }
    } on Object catch (e, st) {
      AppLog.e(
        'AgentRunTaskCompleter',
        'Failed to auto-complete task for agent ${event.agentId}',
        e,
        st,
      );
    }
  }

  /// Returns the most recent agent-authored message content for [agentId]
  /// in [channelId], or null if nothing matched.
  Future<String?> _latestAgentMessage(
    String channelId,
    String agentId,
  ) async {
    final messages = await messagingRepository.getMessages(channelId);
    ChannelMessage? best;
    for (final m in messages) {
      if (m.senderId != agentId) {
        continue;
      }
      if (m.senderType != ChannelSenderType.agent) {
        continue;
      }
      if (best == null || m.createdAt.isAfter(best.createdAt)) {
        best = m;
      }
    }
    return best?.content;
  }
}

