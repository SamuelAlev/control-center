import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart'
    show PairRateLimiter;
import 'package:cc_domain/features/messaging/domain/services/peer_message_limits.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        PeerAskPending,
        PeerAskRefusal,
        PeerAskRefused,
        PeerAskRequest,
        PeerAskService,
        PeerAskSettledInline;
import 'package:cc_mcp/src/mcp_scoped_tool.dart';
import 'package:cc_mcp/src/tools/hidden_spaces_for_caller.dart';
import 'package:cc_mcp/src/tools/peer_agent_messaging.dart';
import 'package:cc_mcp/src/tools/peer_delegation_gate.dart';
import 'package:cc_mcp/src/tools/peer_tool_caller.dart';

/// Asks another agent a question (PRD 22 §2, §4; plan section 10).
///
/// The ask is durable: a `PeerAsk` row is written before the question is
/// delivered (as a `peerMessage` wake through the queue, into the pair's DM
/// space), and the answer reaches the asker exactly once: in this call's
/// result when it arrives while a `wait` call blocks, otherwise as a
/// `peerReply` wake in the asker's conversation. A blocking call that times
/// out becomes a background ask; it never tells the model to poll.
///
/// The asker is the caller (`from_agent_id` is forced from the run's scope)
/// and the conversation the answer wakes it in is the attested one. Every
/// guard runs before any side effect: the shared [PeerDelegationGate]
/// (depth, cycle, autonomy, budget; chains read from rows), the ask limits
/// (`ask_duplicate`, `ask_limit_reached`) and the shared pair rate limit.
class AskAgentTool extends McpScopedTool {
  /// Creates an [AskAgentTool]. [eventBus] lets a freshly minted DM space
  /// announce itself so the background provisioner runs (see
  /// [PeerAgentMessaging]).
  AskAgentTool({
    required AgentRepository agents,
    required MessagingRepository messaging,
    required this._rateLimiter,
    required TicketWorkflowService service,
    required this._peerAsks,
    DomainEventBus? eventBus,
  }) : _peers = PeerAgentMessaging(
         agents: agents,
         messaging: messaging,
         eventBus: eventBus,
       ),
       _gate = PeerDelegationGate(service: service),
       _agents = agents,
       _messaging = messaging;

  final PeerAgentMessaging _peers;
  final AgentRepository _agents;
  final MessagingRepository _messaging;
  final PairRateLimiter _rateLimiter;
  final PeerDelegationGate _gate;
  final PeerAskService _peerAsks;

  @override
  String get name => 'ask_agent';

  /// Not for scripts: it messages another agent run (see
  /// [McpTool.scriptCallable]).
  @override
  bool get scriptCallable => false;
  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.workspaceMutation,
    ActionClass.processSpawn,
  };

  /// The in-process harness's call carries its run's attested scope: the
  /// asking run and its conversation.
  @override
  Future<CallResult> callForRun(
    Map<String, dynamic> arguments,
    McpCallScope scope, {
    Future<void>? abandoned,
  }) =>
      callScoped(arguments, McpCallContext(scope: scope), abandoned: abandoned);

  @override
  String get description =>
      'Ask another agent a question. Name the recipient by to_agent_id or '
      'exact to_agent_name (ambiguous or unknown names are rejected with the '
      'candidates; no fuzzy matching). The question is posted in your DM '
      'space with that agent and wakes it. $askAgentModeText '
      '$peerMessageGuidance';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace both agents belong to.',
      },
      'to_agent_id': {
        'type': 'string',
        'description': 'Recipient agent id (preferred).',
      },
      'to_agent_name': {
        'type': 'string',
        'description':
            'Recipient agent name (must be an exact, unique match in the '
            'workspace). Provide this OR to_agent_id.',
      },
      'message': {
        'type': 'string',
        'description': 'The question to ask the recipient agent.',
      },
      'mode': {
        'type': 'string',
        'enum': PeerAskModeWire.wireNames,
        'description':
            '`wait` (default) blocks up to timeout_seconds; `background` '
            'returns at once.',
      },
      'from_agent_id': {
        'type': 'string',
        'description': 'Set by Control Center to you (the asker).',
      },
      McpCallScope.callerConversationKey: callerConversationProperty,
      'parent_ticket_id': {
        'type': 'string',
        'description':
            'Current ticket id, if this ask belongs to a delegated task.',
      },
      'timeout_seconds': {
        'type': 'integer',
        'description':
            'How long `wait` blocks before the ask turns into a background '
            'one. Defaults to 600, capped at 1800.',
      },
      'context_refs': {
        'type': 'array',
        'items': {'type': 'string'},
        'description':
            'Optional ids of tickets/PRs/messages that give the recipient '
            'context for the question.',
      },
    },
    'required': ['workspace_id', 'message', 'from_agent_id'],
  };

  @override
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final message = arguments['message'];
    if (message is! String || message.trim().isEmpty) {
      return CallResult.error(
        'Missing or invalid argument: message (expected non-empty string)',
      );
    }
    final tooLong = peerMessageSizeRefusal(message, label: 'message');
    if (tooLong != null) {
      return CallResult.error(tooLong);
    }
    final caller = PeerCaller.of(
      arguments,
      context,
      agentKey: 'from_agent_id',
    );
    final fromAgentId = caller.agentId;
    if (fromAgentId == null) {
      return CallResult.error('Missing or invalid argument: from_agent_id');
    }
    final rawMode = arguments['mode'];
    final mode = rawMode == null
        ? PeerAskMode.wait
        : PeerAskModeWire.tryParse('$rawMode');
    if (mode == null) {
      return CallResult.error('Invalid argument: mode (wait or background)');
    }
    final timeoutSeconds = _resolveTimeoutSeconds(arguments['timeout_seconds']);
    final parentTicketId = arguments['parent_ticket_id'];
    if (parentTicketId != null && parentTicketId is! String) {
      return CallResult.error('Invalid argument: parent_ticket_id');
    }
    final readOnly = caller.readOnlyRefusal(_peerAsks);
    if (readOnly != null) {
      return peerRefusalResult(readOnly);
    }

    final resolution = await _peers.resolveRecipient(
      workspaceId: workspaceId,
      toAgentId: arguments['to_agent_id'] as String?,
      toAgentName: arguments['to_agent_name'] as String?,
    );
    if (resolution is UnresolvedRecipient) {
      return CallResult.error(resolution.message);
    }
    final recipient = (resolution as ResolvedRecipient).agent;

    // Every guard runs BEFORE any side effect: a refused ask mints no DM
    // space, posts nothing and spends no rate-limit slot. Autonomy resolves
    // in the pair's existing DM when there is one.
    final chain = await _peerAsks.chainOf(
      workspaceId,
      fromAgentId,
      runId: caller.runId,
      conversationId: caller.conversationId,
    );
    final existingDm = await _peers.findAgentDm(
      workspaceId: workspaceId,
      toAgentId: recipient.id,
      fromAgentId: fromAgentId,
    );
    final refusal =
        await _gate.refusal(
          workspaceId: workspaceId,
          fromAgentId: fromAgentId,
          recipientId: recipient.id,
          chain: chain,
          parentTicketId: parentTicketId as String?,
          spaceId: existingDm?.id,
        ) ??
        await _peerAsks.refusalFor(
          workspaceId: workspaceId,
          askerAgentId: fromAgentId,
          askerConversationId: caller.conversationId,
          recipientAgentId: recipient.id,
          question: message,
          chain: chain,
        );
    if (refusal != null) {
      return peerRefusalResult(refusal);
    }
    if (!_rateLimiter.tryAcquire(fromAgentId, recipient.id, DateTime.now())) {
      return peerRefusalResult(
        PeerAskRefusal(
          PeerGateRefusals.rateLimited,
          'Rate limited: too many messages from "$fromAgentId" to '
          '"${recipient.name}" in a short window. Wait before asking again.',
        ),
      );
    }
    final space =
        existingDm ??
        await _peers.resolveOrCreateAgentDm(
          workspaceId: workspaceId,
          toAgentId: recipient.id,
          toAgentName: recipient.name,
          fromAgentId: fromAgentId,
        );
    final askMessageId = await _messaging.sendMessage(
      workspaceId: workspaceId,
      spaceId: space.id,
      content: message,
      senderId: fromAgentId,
      senderType: 'agent',
    );
    final questionConversation = (await _messaging.getMessageById(
      workspaceId,
      askMessageId,
    ))?.conversationId;
    if (questionConversation == null) {
      return CallResult.error(
        'The question was posted in space ${space.id} but its conversation '
        'could not be read; it was not delivered.',
      );
    }
    final asker = await _agents.getById(workspaceId, fromAgentId);
    final result = await _peerAsks.ask(
      PeerAskRequest(
        workspaceId: workspaceId,
        kind: PeerAskKind.ask,
        mode: mode,
        askerAgentId: fromAgentId,
        askerName: asker?.name ?? fromAgentId,
        askerRunId: caller.runId,
        askerConversationId: caller.conversationId!,
        recipientAgentId: recipient.id,
        recipientSpaceId: space.id,
        recipientConversationId: questionConversation,
        questionMessageId: askMessageId,
        question: message,
        chain: chain.extendedBy(fromAgentId),
        wait: Duration(seconds: timeoutSeconds),
      ),
    );
    final base = <String, Object?>{
      'space_id': space.id,
      'question_message_id': askMessageId,
      'recipient_agent_id': recipient.id,
      'recipient_agent_name': recipient.name,
    };
    if (result case PeerAskRefused(:final refusal)) {
      return peerRefusalResult(refusal);
    }
    final reference = _peerAsks.referenceOnce(caller.runId);
    final body = switch (result) {
      PeerAskRefused() => const <String, Object?>{},
      PeerAskSettledInline(:final ask, :final status, :final reply, :final error) =>
        {
          'status': status.wire,
          'ask_id': ask.id,
          'reply': ?reply,
          'error': ?error,
          'reply_inline': true,
          ...base,
        },
      PeerAskPending(:final ask, :final why, :final requestKind) => {
        'status': why == 'blocked_on_person' ? why : 'pending',
        'ask_id': ask.id,
        'request_kind': ?requestKind,
        'note': _pendingNote(why, recipient.name, timeoutSeconds),
        ...base,
      },
    };
    return CallResult.success(
      jsonEncode({...body, 'reference': ?reference}),
    );
  }

  static String _pendingNote(String why, String name, int seconds) =>
      switch (why) {
        'timeout' =>
          'No answer within ${seconds}s. The ask stays open: you are woken '
              'in this conversation when $name answers (it expires after 24 '
              'hours). Keep working on what the answer does not block, then '
              'end your turn.',
        'blocked_on_person' =>
          '$name is waiting on a person. The ask stays open: you are woken '
              'in this conversation when it answers.',
        'queued_behind_run' =>
          '$name is busy in that conversation; the question waits for its '
              'run to end. You are woken here when it answers.',
        _ =>
          'Asked. You are woken in this conversation when $name answers. '
              'Keep working on what the answer does not block, then end your '
              'turn.',
      };

  /// Clamps the requested timeout to `[1, PeerAskLimits.maxWaitSeconds]`,
  /// defaulting to [PeerAskLimits.defaultWaitSeconds].
  int _resolveTimeoutSeconds(Object? raw) {
    var seconds = PeerAskLimits.defaultWaitSeconds;
    if (raw is num) {
      seconds = raw.toInt();
    }
    return seconds.clamp(1, PeerAskLimits.maxWaitSeconds);
  }
}
