import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/services/active_stream_registry.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart'
    show PairRateLimiter;
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        AgentRegistryImpl,
        CompletionFacts,
        DispatchSession,
        DispatchSessionPark,
        MessagingTeamLeaderDispatch,
        PeerAskService,
        SandboxedAgentDispatchAdapter,
        TicketSettledWakes,
        WakeQueueService,
        peerRunSetWakeFrom;
import 'package:cc_mcp/cc_mcp.dart'
    show
        AgentActivityTool,
        AskAgentTool,
        ConsultAgentTool,
        DelegateTaskTool,
        DelegateTicketTool,
        HiddenSpacesForCaller,
        LiveRunSignals,
        RequestPeerReviewTool,
        SendToAgentTool;
import 'package:cc_persistence/cc_persistence.dart'
    show
        DaoAgentGoalRunRepository,
        DaoPeerAskRepository,
        WorkspaceDatabaseManager;
import 'package:cc_server_core/src/agent_awaiting_input_publisher.dart';

/// The server's peer machinery (plan section 10): the asks service, the
/// ticket-completion wakes and the team leader's dispatch. Built by
/// [registerPeerTools]; [attach] hooks it to the wake queue once that
/// exists, [start] runs the boot sweep after the queue started.
class ServerPeers {
  ServerPeers._({
    required this.asks,
    required this.ticketWakes,
    required this.teamLeader,
  });

  /// Asks: `ask_agent`, `consult_agent`, `request_peer_review`.
  final PeerAskService asks;

  /// Wakes the delegator of a ticket that completed, failed or was
  /// cancelled.
  final TicketSettledWakes ticketWakes;

  /// The team leader's dispatch (`TeamRoutingService`'s port).
  final MessagingTeamLeaderDispatch teamLeader;

  /// Hooks the wake queue: the asks' guard and settled handler, and where
  /// ticket and team completion wakes go.
  void attach(WakeQueueService queue) {
    asks.attachQueue(queue);
    ticketWakes.sink = queue.enqueue;
    teamLeader.sink = queue.enqueue;
  }

  /// The asks' boot sweep (expired asks, missed settlements), then every
  /// five minutes.
  Future<void> start() => asks.start();
}

/// Registers the tools one agent uses to reach or observe another: the
/// messages (`send_to_agent`, `ask_agent`, `consult_agent`,
/// `request_peer_review`), the hand-offs (`delegate_task`,
/// `delegate_ticket`) and the read-only look (`agent_activity`), and builds
/// the [ServerPeers] they deliver through.
///
/// Every hand-off shares ONE [PairRateLimiter] and ONE [PeerAskService], so
/// a burst that alternates between the tools still trips the same
/// ordered-pair window, and the depth and cycle guards read the same rows.
ServerPeers registerPeerTools(
  McpToolRegistry registry, {
  required WorkspaceDatabaseManager workspaceDbs,
  required AgentRepository agents,
  required MessagingRepository messaging,
  required MessagingPort messagingService,
  required ConversationRepository conversations,
  required TicketWorkflowService ticketWorkflow,
  required TicketRepository tickets,
  required PairRateLimiter rateLimiter,
  required DomainEventBus eventBus,
  required AgentRunLogRepository runLogs,
  required WakeRepository wakes,
  required WakeRuleRepository wakeRules,
  required TodoRepository todos,
  required ActiveStreamRegistry streams,
  required HiddenSpacesForCaller hiddenSpaces,
  required SandboxedAgentDispatchAdapter agentDispatch,
  required AgentAwaitingInputPublisher personWaits,
  required WakeQueueService? Function() wakeQueue,
}) {
  final asks =
      PeerAskService(
          asks: DaoPeerAskRepository(workspaceDbs),
          wakes: wakes,
          runLogs: runLogs,
          messages: messaging,
          agents: agents,
          conversations: conversations,
          runSetWake: peerRunSetWakeFrom(wakeRules),
          queue: wakeQueue,
          eventBus: eventBus,
        )
        ..readOnlyRunOf = (conversationId, runId) =>
            conversationId != null &&
            agentDispatch
                .sessionsForConversation(conversationId)
                .any((view) => view.runLogId == runId && view.readOnly);
  // A4: a run that owes a peer an answer and would end with no final
  // message is reminded once (before the owner's `stop` hook).
  agentDispatch.wouldStopHandlers.add(asks.onWouldStop);
  final facts = CompletionFacts(
    messages: messaging,
    runLogs: runLogs,
    goals: DaoAgentGoalRunRepository(workspaceDbs),
  );
  final ticketWakes = TicketSettledWakes(
    tickets: tickets,
    agents: agents,
    conversations: conversations,
    facts: facts,
  )..start(eventBus);
  final teamLeader = MessagingTeamLeaderDispatch(
    messagingService,
    tickets: tickets,
    agents: agents,
    conversations: conversations,
    facts: facts,
  );
  registry
    ..register(
      SendToAgentTool(
        agents: agents,
        messaging: messaging,
        rateLimiter: rateLimiter,
        service: ticketWorkflow,
        peerAsks: asks,
        eventBus: eventBus,
      ),
    )
    ..register(
      AskAgentTool(
        agents: agents,
        messaging: messaging,
        rateLimiter: rateLimiter,
        service: ticketWorkflow,
        peerAsks: asks,
        eventBus: eventBus,
      ),
    )
    ..register(DelegateTaskTool(service: ticketWorkflow, peerAsks: asks))
    ..register(DelegateTicketTool(service: ticketWorkflow, peerAsks: asks))
    ..register(
      ConsultAgentTool(
        agents: agents,
        messaging: messaging,
        service: ticketWorkflow,
        peerAsks: asks,
        rateLimiter: rateLimiter,
      ),
    )
    ..register(
      RequestPeerReviewTool(
        agents: agents,
        messaging: messaging,
        service: ticketWorkflow,
        peerAsks: asks,
        rateLimiter: rateLimiter,
      ),
    )
    ..register(
      AgentActivityTool(
        agents: agents,
        registry: AgentRegistryImpl.global(),
        runLogs: runLogs,
        wakes: wakes,
        todos: todos,
        messaging: messaging,
        streams: streams,
        hiddenSpaces: hiddenSpaces,
        live: (run) => liveRunSignals(
          run,
          agentDispatch: agentDispatch,
          personWaits: personWaits,
        ),
      ),
    );
  return ServerPeers._(
    asks: asks,
    ticketWakes: ticketWakes,
    teamLeader: teamLeader,
  );
}

/// What the live sessions say about [run]: parked when a session of the run
/// has a harness loop parked on a background command, waiting on a person
/// when an announced wait (question, approval, credential block) holds it.
LiveRunSignals liveRunSignals(
  AgentRunLog run, {
  required SandboxedAgentDispatchAdapter agentDispatch,
  required AgentAwaitingInputPublisher personWaits,
}) {
  final workspaceId = run.workspaceId;
  final conversationId = run.conversationId;
  final session = conversationId == null
      ? null
      : agentDispatch
            .sessionsForConversation(conversationId)
            .whereType<DispatchSession>()
            .where((view) => view.runLogId == run.id)
            .firstOrNull;
  final parked = session?.parked ?? false;
  final waiting =
      workspaceId != null &&
      personWaits.holdsRun(
        workspaceId: workspaceId,
        agentId: run.agentId,
        runId: run.id,
        conversationId: conversationId,
        spaceId: run.spaceId,
      );
  return LiveRunSignals(
    parked: parked,
    waitingOnPerson: waiting,
    compacting: session?.compacting ?? false,
    compactionEndedAt: session?.lastCompactionEndedAt,
  );
}
