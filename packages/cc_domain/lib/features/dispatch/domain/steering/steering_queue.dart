import 'package:cc_domain/features/dispatch/domain/steering/steering_message.dart';

/// An in-memory, three-lane FIFO queue feeding an agent loop's injection
/// channels.
///
/// Each [SteeringChannel] has its own independent lane:
///
/// - the steering lane carries interrupting messages dequeued at injection
///   boundaries;
/// - the aside lane carries passive messages polled after each tool batch;
/// - the follow-up lane carries messages consumed only when the agent would
///   otherwise stop.
///
/// The queue is purely synchronous and holds no streams. Producers
/// [enqueue] (or use the `push*` helpers); the agent loop consumes a whole
/// lane at once via the `drain*` methods, which return messages in FIFO order
/// and clear only that lane.
class SteeringQueue {
  /// Creates an empty [SteeringQueue] with three empty lanes.
  SteeringQueue();

  final List<SteeringMessage> _steering = <SteeringMessage>[];
  final List<SteeringMessage> _aside = <SteeringMessage>[];
  final List<SteeringMessage> _followUp = <SteeringMessage>[];

  /// Routes [message] into the lane named by its [SteeringMessage.channel].
  void enqueue(SteeringMessage message) {
    switch (message.channel) {
      case SteeringChannel.steering:
        _steering.add(message);
      case SteeringChannel.aside:
        _aside.add(message);
      case SteeringChannel.followUp:
        _followUp.add(message);
    }
  }

  /// Enqueues [content] onto the interrupting steering lane.
  ///
  /// [now] stamps [SteeringMessage.enqueuedAt]; it defaults to the current
  /// wall-clock time and may be overridden for deterministic tests.
  void pushSteering(String content, {String? source, DateTime? now}) {
    enqueue(
      SteeringMessage(
        content: content,
        channel: SteeringChannel.steering,
        enqueuedAt: now ?? DateTime.now(),
        source: source,
      ),
    );
  }

  /// Enqueues [content] onto the passive aside lane.
  ///
  /// [now] stamps [SteeringMessage.enqueuedAt]; it defaults to the current
  /// wall-clock time and may be overridden for deterministic tests.
  void pushAside(String content, {String? source, DateTime? now}) {
    enqueue(
      SteeringMessage(
        content: content,
        channel: SteeringChannel.aside,
        enqueuedAt: now ?? DateTime.now(),
        source: source,
      ),
    );
  }

  /// Enqueues [content] onto the terminal follow-up lane.
  ///
  /// [now] stamps [SteeringMessage.enqueuedAt]; it defaults to the current
  /// wall-clock time and may be overridden for deterministic tests.
  void pushFollowUp(String content, {String? source, DateTime? now}) {
    enqueue(
      SteeringMessage(
        content: content,
        channel: SteeringChannel.followUp,
        enqueuedAt: now ?? DateTime.now(),
        source: source,
      ),
    );
  }

  /// Removes and returns every steering-lane message in FIFO order.
  ///
  /// Returns an empty list when the lane is empty; the lane is cleared.
  List<SteeringMessage> drainSteering() {
    return _drain(_steering);
  }

  /// Removes and returns every aside-lane message in FIFO order.
  ///
  /// Returns an empty list when the lane is empty; the lane is cleared.
  List<SteeringMessage> drainAside() {
    return _drain(_aside);
  }

  /// Removes and returns every follow-up-lane message in FIFO order.
  ///
  /// Returns an empty list when the lane is empty; the lane is cleared.
  List<SteeringMessage> drainFollowUp() {
    return _drain(_followUp);
  }

  /// Returns a non-destructive copy of [channel]'s lane in FIFO order.
  List<SteeringMessage> peek(SteeringChannel channel) {
    switch (channel) {
      case SteeringChannel.steering:
        return List<SteeringMessage>.unmodifiable(_steering);
      case SteeringChannel.aside:
        return List<SteeringMessage>.unmodifiable(_aside);
      case SteeringChannel.followUp:
        return List<SteeringMessage>.unmodifiable(_followUp);
    }
  }

  /// Whether the steering lane has at least one pending message.
  bool get hasSteering => _steering.isNotEmpty;

  /// Whether the aside lane has at least one pending message.
  bool get hasAside => _aside.isNotEmpty;

  /// Whether the follow-up lane has at least one pending message.
  bool get hasFollowUp => _followUp.isNotEmpty;

  /// Whether all three lanes are empty.
  bool get isEmpty => _steering.isEmpty && _aside.isEmpty && _followUp.isEmpty;

  static List<SteeringMessage> _drain(List<SteeringMessage> lane) {
    if (lane.isEmpty) {
      return <SteeringMessage>[];
    }
    final drained = List<SteeringMessage>.of(lane);
    lane.clear();
    return drained;
  }
}
