import 'dart:async';

/// Domain event.
abstract class DomainEvent {
  /// Occurred at.
  DateTime get occurredAt;
}

/// Domain event bus.
///
/// Dispatch is **type-keyed**: one broadcast lane per subscribed type `T`, and
/// a per-concrete-event-type route cache saying which lanes want it. Publishing
/// is a map lookup plus an `add` to the handful of lanes that actually match.
///
/// It used to be one broadcast controller with a `.where((e) => e is T)` per
/// CALL of [on]. That made every publish O(total subscriptions): the app holds
/// ~95 of them and each remote session's event forwarder adds ~20 more, so a
/// single event ran ~95 type tests and hopped ~95 filtered streams to reach the
/// one or two listeners that wanted it. Ten `on<AgentRunCompleted>()` callers
/// were ten independent filtered subscriptions; they are now ten listeners on
/// one lane.
///
/// The public contract is unchanged — [on] still returns a broadcast
/// `Stream<T>` that each caller listens to and cancels independently, and
/// subtype subscriptions still work ([on] of an abstract event type, or of
/// `DomainEvent` itself, receives every subtype).
class DomainEventBus {
  /// Lanes keyed by the subscribed type `T` (never by the event's runtime
  /// type — a lane for an abstract supertype has to receive its subtypes).
  final _lanes = <Type, _Lane>{};

  /// Concrete event type → the lanes that accept it.
  ///
  /// The `is T` tests are what cost; a concrete event type's answer never
  /// changes, so it is computed once and reused. Cleared whenever a new lane
  /// appears, because that lane may want events already routed.
  final _routes = <Type, List<_Lane>>{};

  var _closed = false;

  /// Emits [event] to all subscribers of its type.
  ///
  /// Throws a [StateError] after [dispose], as it always has: a publish to a
  /// torn-down bus is a lifecycle bug, and swallowing it would hide the
  /// listener that never fired.
  void publish(DomainEvent event) {
    if (_closed) {
      throw StateError('Cannot publish on a disposed DomainEventBus.');
    }
    final lanes = _routes[event.runtimeType] ??= [
      for (final lane in _lanes.values)
        if (lane.accepts(event)) lane,
    ];
    // Indexed rather than for-in: this is the hot path and the list is fixed
    // for the duration of the loop (a new lane clears the cache, it does not
    // mutate this list).
    for (var i = 0; i < lanes.length; i++) {
      lanes[i].add(event);
    }
  }

  /// Returns a broadcast stream of every [DomainEvent] that is a [T].
  ///
  /// Repeated calls for the same `T` share one lane, so N listeners cost one
  /// controller rather than N filtered streams over a common one.
  Stream<T> on<T extends DomainEvent>() {
    final existing = _lanes[T];
    if (existing != null) {
      // Safe: the map is keyed by the very type parameter the lane was made
      // with, so `_lanes[T]` is always a `_TypedLane<T>`.
      return (existing as _TypedLane<T>).stream;
    }
    final lane = _TypedLane<T>();
    _lanes[T] = lane;
    _routes.clear();
    return lane.stream;
  }

  /// Closes every lane.
  void dispose() {
    _closed = true;
    for (final lane in _lanes.values) {
      lane.close();
    }
    _lanes.clear();
    _routes.clear();
  }
}

/// A lane with its type parameter erased, so [DomainEventBus] can hold them in
/// one map and dispatch without knowing `T`.
abstract class _Lane {
  bool accepts(DomainEvent event);
  void add(DomainEvent event);
  void close();
}

class _TypedLane<T extends DomainEvent> implements _Lane {
  final _controller = StreamController<T>.broadcast();

  Stream<T> get stream => _controller.stream;

  @override
  bool accepts(DomainEvent event) => event is T;

  // Only ever called for an event this lane accepted, so the cast holds.
  @override
  void add(DomainEvent event) => _controller.add(event as T);

  @override
  void close() => _controller.close();
}
