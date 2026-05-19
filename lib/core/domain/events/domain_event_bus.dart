import 'dart:async';

/// Domain event.
abstract class DomainEvent {
  /// Occurred at.
  DateTime get occurredAt;
}

/// Domain event bus.
class DomainEventBus {
  final _controller = StreamController<DomainEvent>.broadcast();

  /// Emits [event] to all subscribers of its type.
  void publish(DomainEvent event) => _controller.add(event);

  /// Returns a stream of every [DomainEvent] whose runtime type is [T].
  Stream<T> on<T extends DomainEvent>() =>
      _controller.stream.where((event) => event is T).cast<T>();

  /// Closes the underlying stream controller.
  void dispose() => _controller.close();
}
