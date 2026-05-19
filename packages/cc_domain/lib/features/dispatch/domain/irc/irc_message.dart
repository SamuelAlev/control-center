/// How an [IrcMessage] reached (or failed to reach) its recipient. Reports the
/// delivery mechanism, never what the recipient did with the message.
enum IrcDeliveryOutcome {
  /// A pending `wait()` (or live session sink) consumed the message directly.
  injected,

  /// An idle recipient was given a real wake turn.
  woken,

  /// A parked recipient was revived first, then the message delivered.
  revived,

  /// Live hand-off failed; the message was buffered into the mailbox (or the
  /// recipient is unknown / terminated / not a messageable peer).
  failed,
}

/// A peer-to-peer message on the `IrcBus`.
class IrcMessage {
  /// Creates an [IrcMessage].
  IrcMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    required this.ts,
    this.replyTo,
  })  : assert(id.isNotEmpty, 'IrcMessage.id must not be empty'),
        assert(from.isNotEmpty, 'IrcMessage.from must not be empty'),
        assert(to.isNotEmpty, 'IrcMessage.to must not be empty');

  /// Stable message id.
  final String id;

  /// Sender agent id.
  final String from;

  /// Recipient agent id.
  final String to;

  /// Message body.
  final String body;

  /// Wall-clock send time (ms since epoch).
  final int ts;

  /// Id of the message this one answers, if any.
  final String? replyTo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IrcMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          from == other.from &&
          to == other.to &&
          body == other.body &&
          ts == other.ts &&
          replyTo == other.replyTo;

  @override
  int get hashCode => Object.hash(id, from, to, body, ts, replyTo);

  @override
  String toString() => 'IrcMessage($from → $to, "$body")';
}

/// Outcome of a single `IrcBus.send`.
class IrcDeliveryReceipt {
  /// Creates a receipt for recipient [to] with the given [outcome].
  const IrcDeliveryReceipt({
    required this.to,
    required this.outcome,
    this.error,
  });

  /// Recipient agent id.
  final String to;

  /// How the message reached the recipient.
  final IrcDeliveryOutcome outcome;

  /// Failure detail when [outcome] is [IrcDeliveryOutcome.failed].
  final String? error;

  /// Whether delivery succeeded (anything but [IrcDeliveryOutcome.failed]).
  bool get delivered => outcome != IrcDeliveryOutcome.failed;

  @override
  String toString() =>
      'IrcDeliveryReceipt($to, ${outcome.name}${error == null ? '' : ', $error'})';
}
