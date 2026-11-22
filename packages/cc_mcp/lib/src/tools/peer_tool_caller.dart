import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart'
    show PeerAskRefusals;
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_infra/cc_infra.dart' show PeerAskRefusal, PeerAskService;
import 'package:cc_mcp/src/mcp_scoped_tool.dart';
import 'package:cc_mcp/src/tools/hidden_spaces_for_caller.dart';

/// Who calls a peer tool, from the call's trusted scope: the agent (a forced
/// caller-identity argument), its run (the attested run log id) and its
/// conversation (the attested `caller_conversation_id`). A person's own MCP
/// client has none of them.
class PeerCaller {
  /// Reads the caller of a call: [agentKey] names the forced identity
  /// argument (`from_agent_id`, `agent_id`, `requester_id`).
  factory PeerCaller.of(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    required String agentKey,
  }) {
    final scope = context.scope;
    final attested = scope?.attested ?? false;
    final agent = arguments[agentKey];
    return PeerCaller._(
      agentId: agent is String && agent.isNotEmpty ? agent : null,
      runId: attested ? scope?.runLogId : null,
      conversationId:
          callerConversationOf(arguments) ??
          (attested ? scope?.conversationId : null),
    );
  }

  const PeerCaller._({this.agentId, this.runId, this.conversationId});

  /// The calling agent, when an agent calls.
  final String? agentId;

  /// The calling run, when its identity is attested.
  final String? runId;

  /// The calling run's conversation, when attested.
  final String? conversationId;

  /// The refusal for a call from a read-only run (a review): it may not wake
  /// anyone. Null otherwise.
  PeerAskRefusal? readOnlyRefusal(PeerAskService peers) {
    final run = runId;
    if (run == null || !peers.isReadOnlyRun(conversationId, run)) {
      return null;
    }
    return const PeerAskRefusal(
      PeerAskRefusals.readOnlyRun,
      'This run is read-only (a review): it cannot message or wake another '
      'agent. Put what you found in your final message.',
    );
  }
}

/// `send_to_agent`'s `delivery_status` for a wake receipt: `woken` (a run
/// started or the live run's lane took it), `queued_behind_run` (it waits,
/// for a run of the recipient in that conversation or another reason the
/// queue gives) or `refused` (with the receipt's kind).
({String status, String? kind}) peerDeliveryStatus(WakeReceipt receipt) =>
    switch (receipt) {
      WakeStarted() || WakePushed() => (status: 'woken', kind: null),
      WakeWaiting(:final kind) => (status: 'queued_behind_run', kind: kind),
      WakeSkipped(:final kind) => (status: 'refused', kind: kind),
      WakeDuplicate() => (status: 'refused', kind: 'duplicate'),
    };
