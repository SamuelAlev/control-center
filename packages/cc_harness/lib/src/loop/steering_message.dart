/// Steering and injection channels for an agent loop. Framing differs, not
/// timing — [SteeringChannel.steering] and [SteeringChannel.aside] both drain
/// at the turn boundary before the provider call (never mid-turn / after tools).
///
/// - [SteeringChannel.steering]: user turn + `LoopNotice` (human → run).
/// - [SteeringChannel.aside]: system turn, silent (background/peer context).
/// - [SteeringChannel.followUp]: only when the agent would otherwise stop.
enum SteeringChannel {
  /// Interrupting channel: injected as a user turn at the next turn boundary
  /// and announced with a `LoopNotice`.
  steering,

  /// Passive channel: injected as a system turn at the next turn boundary,
  /// without a notice. Never aborts in-flight tools.
  aside,

  /// Terminal channel: messages are consumed only when the agent would
  /// otherwise stop.
  followUp,
}

/// A single message destined for one of an agent loop's injection channels.
///
/// The [channel] determines when the agent loop consumes the message (see
/// [SteeringChannel]). [enqueuedAt] records when the message entered its queue
/// so FIFO ordering can be preserved and [source] optionally identifies who
/// produced it (e.g. a peer agent id or a background job name).
///
/// [ref] optionally correlates the in-flight message with a durable record the
/// HOST owns (a persisted conversation row id, for the steering queue UI). The
/// kernel never interprets it; it only carries it back out through drains so
/// the host can mark delivery.
class SteeringMessage {
  /// Creates a [SteeringMessage] bound to [channel].
  ///
  /// [content] must not be empty.
  SteeringMessage({
    required this.content,
    required this.channel,
    required this.enqueuedAt,
    this.source,
    this.ref,
  }) {
    if (content.isEmpty) {
      throw ArgumentError('content must not be empty');
    }
  }

  /// The message body delivered to the agent loop.
  final String content;

  /// The injection channel this message belongs to.
  final SteeringChannel channel;

  /// When the message was enqueued; used to preserve FIFO ordering.
  final DateTime enqueuedAt;

  /// Optional identifier of the producer (a peer agent id, a job name, etc.).
  final String? source;

  /// Optional host-side correlation id (e.g. the persisted message row).
  final String? ref;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SteeringMessage &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          channel == other.channel &&
          enqueuedAt == other.enqueuedAt &&
          source == other.source &&
          ref == other.ref;

  @override
  int get hashCode => Object.hash(content, channel, enqueuedAt, source, ref);

  @override
  String toString() {
    return 'SteeringMessage(channel: $channel, source: $source, ref: $ref, '
        'enqueuedAt: $enqueuedAt, content: $content)';
  }
}
