/// Steering and injection channels for an agent loop.
///
/// An agent loop consults three queues at different points in its lifecycle:
///
/// - [SteeringChannel.steering] — interrupting; dequeued at injection
///   boundaries and may interrupt in-flight work.
/// - [SteeringChannel.aside] — passive; never aborts in-flight tools and is
///   polled after each tool batch. Background-job completions and IRC messages
///   arrive here.
/// - [SteeringChannel.followUp] — consumed only when the agent would
///   otherwise stop.
enum SteeringChannel {
  /// Interrupting channel: messages may interrupt in-flight work at the next
  /// injection boundary.
  steering,

  /// Passive channel: messages never abort in-flight tools and are polled
  /// after each tool batch.
  aside,

  /// Terminal channel: messages are consumed only when the agent would
  /// otherwise stop.
  followUp,
}

/// A single message destined for one of an agent loop's injection channels.
///
/// The [channel] determines when the agent loop consumes the message (see
/// [SteeringChannel]). [enqueuedAt] records when the message entered its queue
/// so FIFO ordering can be preserved, and [source] optionally identifies who
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
  }) : assert(content != '', 'content must not be empty');

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
