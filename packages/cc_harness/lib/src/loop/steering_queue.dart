import 'dart:async';

import 'package:cc_harness/src/loop/steering_message.dart';

/// In-memory three-lane FIFO for agent-loop injection. Steering/aside differ in
/// framing (user+notice vs system), not timing — see [SteeringChannel].
/// Follow-up drains only when the agent would stop. Sync only; [enqueue]/`push*`
/// produce, `drain*` consume one lane FIFO.
class SteeringQueue {
  /// Creates an empty [SteeringQueue] with three empty lanes.
  SteeringQueue();

  final List<SteeringMessage> _steering = <SteeringMessage>[];
  final List<SteeringMessage> _aside = <SteeringMessage>[];
  final List<SteeringMessage> _followUp = <SteeringMessage>[];

  /// Per-lane cap. The loop drains every lane once per turn, so in normal
  /// operation a lane holds a handful of messages. A run parked on the
  /// take-over `pauseGate` drains nothing, though, and a chatty producer would
  /// then grow a lane without bound. Dropping the OLDEST keeps the newest
  /// instruction — the one a human just sent — and bounds the memory.
  static const int maxLaneLength = 500;

  /// Invoked once for every message that LEAVES a lane via a `drain*` call,
  /// after the lane is cleared but before the caller sees the list.
  ///
  /// This is the host's delivery signal: a message with a [SteeringMessage.ref]
  /// that reaches this callback has been handed to the loop (injected into its
  /// next turn), so the durable record behind the ref can be marked delivered.
  /// It is deliberately a plain callback, not a stream, so the kernel stays
  /// synchronous and free of async bookkeeping. Messages dropped by the lane
  /// cap never pass through here — they were not delivered.
  void Function(SteeringMessage message)? onDrained;

  /// Invoked after every [enqueue] / `push*` / [pushFront], once the message
  /// is in its lane.
  ///
  /// The arrival signal for a consumer that cannot poll at turn boundaries —
  /// an external CLI whose stdin is its only input lane drains as messages
  /// arrive instead of waiting for a loop to ask.
  void Function()? onEnqueued;

  final List<Completer<void>> _arrivalWaiters = [];

  /// Completes when the next message enters any lane.
  ///
  /// For a loop that waits with no turn to run (parked on a background
  /// command): a message a person or the server sends meanwhile ends the
  /// wait. Unlike [onEnqueued] it has any number of listeners, each heard
  /// once.
  Future<void> nextArrival() {
    final waiter = Completer<void>();
    _arrivalWaiters.add(waiter);
    return waiter.future;
  }

  void _arrived() {
    onEnqueued?.call();
    if (_arrivalWaiters.isEmpty) {
      return;
    }
    final waiters = List<Completer<void>>.of(_arrivalWaiters);
    _arrivalWaiters.clear();
    for (final waiter in waiters) {
      waiter.complete();
    }
  }

  /// Whether this is a nested run's view of a parent's queue
  /// ([nestedView]). A nested run's own notices must not go through a view:
  /// what is enqueued there lands in the parent's lanes.
  bool get isNestedView => false;

  /// Routes [message] into the lane named by its [SteeringMessage.channel].
  void enqueue(SteeringMessage message) {
    switch (message.channel) {
      case SteeringChannel.steering:
        _push(_steering, message);
      case SteeringChannel.aside:
        _push(_aside, message);
      case SteeringChannel.followUp:
        _push(_followUp, message);
    }
    _arrived();
  }

  /// Enqueues [message] at the FRONT of its lane, ahead of anything already
  /// queued there.
  ///
  /// The jump-to-front affordance for user steering ("deliver this one
  /// first"). Front-insertion still respects the lane cap on total length. A
  /// message already in a lane is NOT deduplicated — callers move a message to
  /// the front via [removeByRef] followed by this, not by double-pushing.
  void pushFront(SteeringMessage message) {
    switch (message.channel) {
      case SteeringChannel.steering:
        _steering.insert(0, message);
        _cap(_steering);
      case SteeringChannel.aside:
        _aside.insert(0, message);
        _cap(_aside);
      case SteeringChannel.followUp:
        _followUp.insert(0, message);
        _cap(_followUp);
    }
    _arrived();
  }

  /// Removes the first message (searching the steering lane, then aside, then
  /// follow-up) whose [SteeringMessage.ref] equals [ref].
  ///
  /// Returns whether a message was removed. A null [ref] matches nothing —
  /// internal producers (repo-switch announcements, peer asides) carry no ref
  /// and must stay untouched by host-side queue surgery.
  bool removeByRef(String? ref) {
    if (ref == null) {
      return false;
    }
    for (final lane in [_steering, _aside, _followUp]) {
      for (var i = 0; i < lane.length; i++) {
        if (lane[i].ref == ref) {
          lane.removeAt(i);
          return true;
        }
      }
    }
    return false;
  }

  static void _push(List<SteeringMessage> lane, SteeringMessage message) {
    lane.add(message);
    _cap(lane);
  }

  static void _cap(List<SteeringMessage> lane) {
    if (lane.length > maxLaneLength) {
      lane.removeRange(0, lane.length - maxLaneLength);
    }
  }

  /// Enqueues [content] onto the interrupting steering lane.
  ///
  /// [now] stamps [SteeringMessage.enqueuedAt]; it defaults to the current
  /// wall-clock time and may be overridden for deterministic tests. [ref] is
  /// the optional host-side correlation id carried through to the drain.
  void pushSteering(
    String content, {
    String? source,
    DateTime? now,
    String? ref,
  }) {
    enqueue(
      SteeringMessage(
        content: content,
        channel: SteeringChannel.steering,
        enqueuedAt: now ?? DateTime.now(),
        source: source,
        ref: ref,
      ),
    );
  }

  /// Enqueues [content] onto the passive aside lane.
  ///
  /// [now] stamps [SteeringMessage.enqueuedAt]; it defaults to the current
  /// wall-clock time and may be overridden for deterministic tests.
  void pushAside(String content, {String? source, DateTime? now, String? ref}) {
    enqueue(
      SteeringMessage(
        content: content,
        channel: SteeringChannel.aside,
        enqueuedAt: now ?? DateTime.now(),
        source: source,
        ref: ref,
      ),
    );
  }

  /// Enqueues [content] onto the terminal follow-up lane.
  ///
  /// [now] stamps [SteeringMessage.enqueuedAt]; it defaults to the current
  /// wall-clock time and may be overridden for deterministic tests.
  void pushFollowUp(
    String content, {
    String? source,
    DateTime? now,
    String? ref,
  }) {
    enqueue(
      SteeringMessage(
        content: content,
        channel: SteeringChannel.followUp,
        enqueuedAt: now ?? DateTime.now(),
        source: source,
        ref: ref,
      ),
    );
  }

  /// A read-only view for a NESTED run (a subagent) working on this queue's
  /// behalf.
  ///
  /// The parent is blocked on the subagent's tool call while it runs, so a
  /// message the user sends meanwhile would otherwise wait — possibly for
  /// many minutes — until the subagent returned. The view lets the running
  /// subagent SEE each steering and aside message once (so it can react now)
  /// without consuming it: the messages stay queued and the parent still
  /// drains them at its next turn, firing [onDrained] exactly once. Follow-ups
  /// are the parent's alone (they decide whether the PARENT stops), so the
  /// view never surfaces them. Anything enqueued through the view lands here.
  SteeringQueue nestedView() => _NestedSteeringView(this);

  /// Removes and returns every steering-lane message in FIFO order.
  ///
  /// Returns an empty list when the lane is empty; the lane is cleared. Every
  /// departed message is reported to [onDrained].
  List<SteeringMessage> drainSteering() {
    return _drainReporting(_steering);
  }

  /// Removes and returns every aside-lane message in FIFO order.
  ///
  /// Returns an empty list when the lane is empty; the lane is cleared. Every
  /// departed message is reported to [onDrained].
  List<SteeringMessage> drainAside() {
    return _drainReporting(_aside);
  }

  /// Removes and returns every follow-up-lane message in FIFO order.
  ///
  /// Returns an empty list when the lane is empty; the lane is cleared. Every
  /// departed message is reported to [onDrained].
  List<SteeringMessage> drainFollowUp() {
    return _drainReporting(_followUp);
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

  /// Drains [lane] and reports every departed message to [onDrained].
  List<SteeringMessage> _drainReporting(List<SteeringMessage> lane) {
    final drained = _drain(lane);
    if (onDrained != null) {
      for (final message in drained) {
        onDrained!(message);
      }
    }
    return drained;
  }
}

/// See [SteeringQueue.nestedView].
class _NestedSteeringView extends SteeringQueue {
  _NestedSteeringView(this._parent);

  final SteeringQueue _parent;

  /// Messages already surfaced to the nested run, by identity.
  final Set<SteeringMessage> _seen = Set<SteeringMessage>.identity();

  List<SteeringMessage> _unseen(SteeringChannel channel) => [
    for (final message in _parent.peek(channel))
      if (_seen.add(message)) message,
  ];

  @override
  bool get isNestedView => true;

  @override
  Future<void> nextArrival() => _parent.nextArrival();

  @override
  void enqueue(SteeringMessage message) => _parent.enqueue(message);

  @override
  void pushFront(SteeringMessage message) => _parent.pushFront(message);

  @override
  bool removeByRef(String? ref) => _parent.removeByRef(ref);

  @override
  List<SteeringMessage> drainSteering() => _unseen(SteeringChannel.steering);

  @override
  List<SteeringMessage> drainAside() => _unseen(SteeringChannel.aside);

  @override
  List<SteeringMessage> drainFollowUp() => const <SteeringMessage>[];

  @override
  List<SteeringMessage> peek(SteeringChannel channel) => [
    if (channel != SteeringChannel.followUp)
      for (final message in _parent.peek(channel))
        if (!_seen.contains(message)) message,
  ];

  @override
  bool get hasSteering => peek(SteeringChannel.steering).isNotEmpty;

  @override
  bool get hasAside => peek(SteeringChannel.aside).isNotEmpty;

  @override
  bool get hasFollowUp => false;

  @override
  bool get isEmpty => !hasSteering && !hasAside;
}
