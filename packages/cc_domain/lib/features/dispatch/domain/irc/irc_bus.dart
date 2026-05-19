import 'package:cc_domain/core/utils/cancellation_token.dart';
import 'package:cc_domain/features/dispatch/domain/irc/irc_message.dart';

/// Delivers a message to a recipient's LIVE session — the hook a future
/// in-process agent loop (the CC Harness, PRD 13) implements so a busy agent
/// receives the message as a non-interrupting aside at the next step boundary,
/// and an idle agent gets a real wake turn.
///
/// When no sink is registered for a recipient, the bus falls back to buffering
/// the message in the recipient's mailbox, which a later `wait`/`inbox` drains.
abstract interface class AgentMessageSink {
  /// Hands [message] to the recipient's live session. Returns how it was
  /// delivered ([IrcDeliveryOutcome.injected] or [IrcDeliveryOutcome.woken]).
  /// Throws when the live hand-off fails so the bus can buffer instead.
  ///
  /// [expectsReply] marks a send whose caller is blocked on an answer, so a
  /// mid-turn recipient that cannot reach a step boundary may generate an
  /// ephemeral side-channel reply (Feature #5) instead of stranding the sender.
  Future<IrcDeliveryOutcome> deliver(
    IrcMessage message, {
    required bool expectsReply,
  });
}

/// Resolves the [AgentMessageSink] for a recipient agent, or null when the
/// recipient has no live in-process session (the mailbox-buffering fallback
/// applies). Injected so the bus stays decoupled from the dispatch runtime.
typedef AgentMessageSinkResolver = AgentMessageSink? Function(String agentId);

/// Process-global peer-to-peer mailbox bus for agent-to-agent messaging.
///
/// A `send` never blocks on the recipient generating anything: the receipt
/// reports how the message reached the recipient. Delivery resolves the
/// recipient via the `AgentRegistry` — parked agents are revived through the
/// `AgentLifecycleManager`, a pending `wait` is satisfied directly, and a live
/// session (when one exists) receives the message via its [AgentMessageSink];
/// otherwise the message is buffered in the recipient's mailbox.
///
/// ## Workspace isolation
///
/// The bus is process-global and spans every workspace, so it enforces the
/// isolation boundary: a send only succeeds when sender and recipient belong to
/// the SAME workspace. A cross-workspace send fails loudly — an agent can never
/// message a peer in another workspace.
abstract interface class IrcBus {
  /// Fire-and-forget delivery from `from` to `to`. Returns a receipt describing
  /// how the message reached the recipient (never what they did with it).
  ///
  /// [expectsReply] marks a send whose caller is blocked on an answer
  /// (`send await:true`); it is forwarded to the recipient's sink so a mid-turn
  /// recipient can produce an ephemeral side-channel reply.
  Future<IrcDeliveryReceipt> send({
    required String from,
    required String to,
    required String body,
    String? replyTo,
    bool expectsReply = false,
  });

  /// Blocks until a message for [agentId] (optionally only from `from`)
  /// arrives, then consumes and returns it. Returns null on timeout
  /// (`timeoutMs <= 0` waits forever). Throws [CancelledException] when
  /// [signal] cancels. By default already-buffered mail satisfies the wait
  /// before parking a future waiter; pass `drainPending: false` to require a
  /// strictly future message.
  Future<IrcMessage?> wait(
    String agentId, {
    String? from,
    required int timeoutMs,
    CancellationToken? signal,
    bool drainPending = true,
  });

  /// Drains (or peeks, when [peek] is true) pending messages for [agentId].
  List<IrcMessage> inbox(String agentId, {bool peek = false});

  /// Number of buffered, unread messages for [agentId].
  int unreadCount(String agentId);
}
