import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart'
    show PairRateLimiter;
import 'package:cc_domain/features/messaging/domain/services/peer_message_limits.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
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
import 'package:uuid/uuid.dart';

/// MCP tool used by a reviewer agent to ask a teammate for a second
/// opinion on a specific review node. Posts a thread reply tagging the
/// target agent with the question and wakes it through the wake queue (a
/// `peerMessage` wake that expects a reply). The request is a durable ask
/// (`PeerAsk`, kind `review`, background): the requester is woken in its
/// conversation when the reviewer finishes. Distinct from
/// `request_confirmation` (which prompts the *user* for UI confirmation of a
/// destructive action).
///
/// The asking reviewer is the caller (`requester_id` is one of
/// `McpCallScope.callerIdentityKeys`), and the request passes the same
/// [PeerDelegationGate], ask limits and shared [PairRateLimiter] as
/// `ask_agent` before anything is posted.
class RequestPeerReviewTool extends McpScopedTool {
  /// Creates a new [RequestPeerReviewTool]. [service], `peerAsks` and
  /// `rateLimiter` are the instances every peer tool shares.
  RequestPeerReviewTool({
    required AgentRepository agents,
    required this._messaging,
    required TicketWorkflowService service,
    required this._peerAsks,
    required this._rateLimiter,
  }) : _peers = PeerAgentMessaging(agents: agents, messaging: _messaging),
       _agents = agents,
       _gate = PeerDelegationGate(service: service);

  final PeerAgentMessaging _peers;
  final AgentRepository _agents;
  final MessagingRepository _messaging;
  final PeerAskService _peerAsks;
  final PeerDelegationGate _gate;
  final PairRateLimiter _rateLimiter;

  /// The in-process harness's call carries its run's attested scope.
  @override
  Future<CallResult> callForRun(
    Map<String, dynamic> arguments,
    McpCallScope scope, {
    Future<void>? abandoned,
  }) =>
      callScoped(arguments, McpCallContext(scope: scope), abandoned: abandoned);

  @override
  String get name => 'request_peer_review';

  /// Not for scripts: it starts a peer agent's review run (see
  /// [McpTool.scriptCallable]).
  @override
  bool get scriptCallable => false;

  @override
  String get description =>
      'Ask another reviewer agent to take a second look at a review node. '
      'Posts a thread reply on the target node tagging the teammate with '
      'your question and wakes it; you are woken in this conversation when '
      'it answers. Use when you are unsure about a finding and want a '
      'peer confirmation before it lands in the final review. Message another '
      'agent only with a question that blocks you or a decision it must '
      'make, and send it to the one agent that can answer. Never send '
      'status, progress or completion notes: your result reaches whoever '
      'started you without a message.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the review space belongs to.',
      },
      'space_id': {'type': 'string', 'description': 'The review space ID.'},
      'node_message_id': {
        'type': 'string',
        'description':
            'The review-node message id the question is attached to.',
      },
      'requester_id': {
        'type': 'string',
        'description':
            'Set by Control Center to the calling agent (the asker); any '
            'value you pass is replaced.',
      },
      'target_agent_id': {
        'type': 'string',
        'description': 'The teammate being asked.',
      },
      'question': {
        'type': 'string',
        'description': 'The question or context for the peer review.',
      },
      McpCallScope.callerConversationKey: callerConversationProperty,
    },
    'required': [
      'workspace_id',
      'space_id',
      'node_message_id',
      'requester_id',
      'target_agent_id',
      'question',
    ],
  };

  @override
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String || rawWorkspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final rawSpaceId = arguments['space_id'];
    if (rawSpaceId is! String) {
      return CallResult.error(
        'Missing or invalid argument: space_id (expected string)',
      );
    }
    final rawNodeMessageId = arguments['node_message_id'];
    if (rawNodeMessageId is! String) {
      return CallResult.error(
        'Missing or invalid argument: node_message_id (expected string)',
      );
    }
    final rawRequester = arguments['requester_id'];
    if (rawRequester is! String || rawRequester.isEmpty) {
      return CallResult.error(
        'Missing or invalid argument: requester_id (expected string)',
      );
    }
    final rawTarget = arguments['target_agent_id'];
    if (rawTarget is! String) {
      return CallResult.error(
        'Missing or invalid argument: target_agent_id (expected string)',
      );
    }
    final rawQuestion = arguments['question'];
    if (rawQuestion is! String) {
      return CallResult.error(
        'Missing or invalid argument: question (expected string)',
      );
    }

    final tooLong = peerMessageSizeRefusal(rawQuestion, label: 'question');
    if (tooLong != null) {
      return CallResult.error(tooLong);
    }

    if (!await _messaging.spaceExists(rawWorkspaceId, rawSpaceId)) {
      return CallResult.error('Space belongs to a different workspace.');
    }
    final resolution = await _peers.resolveRecipient(
      workspaceId: rawWorkspaceId,
      toAgentId: rawTarget,
    );
    if (resolution is UnresolvedRecipient) {
      return CallResult.error(resolution.message);
    }
    final target = (resolution as ResolvedRecipient).agent;
    final caller = PeerCaller.of(
      arguments,
      context,
      agentKey: 'requester_id',
    );
    final readOnly = caller.readOnlyRefusal(_peerAsks);
    if (readOnly != null) {
      return peerRefusalResult(readOnly);
    }
    // Every guard runs BEFORE any side effect, as for `ask_agent`: a refused
    // request posts nothing and spends no rate slot.
    final chain = await _peerAsks.chainOf(
      rawWorkspaceId,
      rawRequester,
      runId: caller.runId,
      conversationId: caller.conversationId,
    );
    final refusal =
        await _gate.refusal(
          workspaceId: rawWorkspaceId,
          fromAgentId: rawRequester,
          recipientId: target.id,
          chain: chain,
          spaceId: rawSpaceId,
        ) ??
        await _peerAsks.refusalFor(
          workspaceId: rawWorkspaceId,
          askerAgentId: rawRequester,
          askerConversationId: caller.conversationId,
          recipientAgentId: target.id,
          question: rawQuestion,
          chain: chain,
        );
    if (refusal != null) {
      return peerRefusalResult(refusal);
    }
    if (!_rateLimiter.tryAcquire(rawRequester, target.id, DateTime.now())) {
      return peerRefusalResult(
        PeerAskRefusal(
          PeerGateRefusals.rateLimited,
          'Rate limited: too many messages from "$rawRequester" to '
          '"${target.name}" in a short window. Wait before asking again.',
        ),
      );
    }
    final replyId = const Uuid().v4();
    await _messaging.sendMessage(
      workspaceId: rawWorkspaceId,
      spaceId: rawSpaceId,
      content: '@$rawTarget $rawQuestion',
      senderId: rawRequester,
      senderType: 'agent',
      messageType: 'text',
      id: replyId,
      // Link the discussion message to its review node via metadata (threading
      // was removed). The review accordion filters on `reviewNodeId`.
      metadata: {
        'peerReviewRequest': true,
        'reviewNodeId': rawNodeMessageId,
        'requester': rawRequester,
        'target': rawTarget,
      },
    );
    final conversationId = (await _messaging.getMessageById(
      rawWorkspaceId,
      replyId,
    ))?.conversationId;
    if (conversationId == null) {
      return CallResult.error(
        'The request was posted in space $rawSpaceId but its conversation '
        'could not be read; the reviewer was not woken.',
      );
    }
    final requester = await _agents.getById(rawWorkspaceId, rawRequester);
    final result = await _peerAsks.ask(
      PeerAskRequest(
        workspaceId: rawWorkspaceId,
        kind: PeerAskKind.review,
        mode: PeerAskMode.background,
        askerAgentId: rawRequester,
        askerName: requester?.name ?? rawRequester,
        askerRunId: caller.runId,
        askerConversationId: caller.conversationId!,
        recipientAgentId: target.id,
        recipientSpaceId: rawSpaceId,
        recipientConversationId: conversationId,
        questionMessageId: replyId,
        question: rawQuestion,
        chain: chain.extendedBy(rawRequester),
      ),
    );
    final base = <String, Object?>{
      'reply_id': replyId,
      'review_node_id': rawNodeMessageId,
      'target_agent_id': rawTarget,
    };
    return switch (result) {
      PeerAskRefused(:final refusal) => peerRefusalResult(refusal),
      PeerAskSettledInline(:final ask, :final status, :final error) =>
        CallResult.success(
          jsonEncode({
            ...base,
            'ask_id': ask.id,
            'status': status.wire,
            'error': ?error,
          }),
        ),
      PeerAskPending(:final ask) => CallResult.success(
        jsonEncode({
          ...base,
          'ask_id': ask.id,
          'status': 'pending',
          'note':
              'You are woken in this conversation when ${target.name} '
              'answers. Keep working on what the answer does not block, then '
              'end your turn.',
        }),
      ),
    };
  }
}
