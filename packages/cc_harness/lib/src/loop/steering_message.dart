/// Steering and injection channels for an agent loop.
///
/// An agent loop consults three queues, and the difference between the first
/// two is HOW A MESSAGE IS FRAMED to the model, not when it arrives:
///
/// - [SteeringChannel.steering] — injected as a **user** turn at the top of
///   the next turn, and announced to the host with a `LoopNotice`. This is a
///   person talking to the run.
/// - [SteeringChannel.aside] — injected as a **system** turn at the same
///   point, silently. Background-job completions and peer-agent messages
///   arrive here: context the model should have, not an instruction it was
///   given.
/// - [SteeringChannel.followUp] — consumed only when the agent would
///   otherwise stop, so it can extend a run rather than steer one.
///
/// Neither of the first two aborts in-flight work: both are drained at the
/// turn boundary, before the provider call. The docs used to say the aside
/// lane was "polled after each tool batch", which described a mid-turn poll
/// the loop has never done — a host integrator choosing between the lanes for
/// their timing was choosing on a difference that does not exist. Choose on
/// the framing.
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
class SteeringMessage {
  /// Creates a [SteeringMessage] bound to [channel].
  ///
  /// [content] must not be empty.
  SteeringMessage({
    required this.content,
    required this.channel,
    required this.enqueuedAt,
    this.source,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SteeringMessage &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          channel == other.channel &&
          enqueuedAt == other.enqueuedAt &&
          source == other.source;

  @override
  int get hashCode => Object.hash(content, channel, enqueuedAt, source);

  @override
  String toString() {
    return 'SteeringMessage(channel: $channel, source: $source, '
        'enqueuedAt: $enqueuedAt, content: $content)';
  }
}
