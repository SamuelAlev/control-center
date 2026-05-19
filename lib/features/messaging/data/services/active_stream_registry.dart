import 'dart:async';

import 'package:control_center/core/domain/value_objects/thinking_event.dart';

/// Active stream registry.
///
/// Maintains two parallel broadcast streams per message id:
///   * a text stream for free-form markdown deltas (`add` / `streamFor`)
///   * a structured event stream for thinking-timeline updates
///     (`addEvent` / `eventStreamFor`)
///
/// Registering a message id opens both streams; unregistering closes both.
class ActiveStreamRegistry {
  final Map<String, StreamController<String>> _streams = {};
  final Map<String, StreamController<ThinkingEvent>> _eventStreams = {};

  /// Text-delta stream for [messageId].
  Stream<String>? streamFor(String messageId) => _streams[messageId]?.stream;

  /// Structured thinking-event stream for [messageId].
  Stream<ThinkingEvent>? eventStreamFor(String messageId) =>
      _eventStreams[messageId]?.stream;

  /// Returns whether a stream is active for the given [messageId].
  bool isActive(String messageId) => _streams[messageId]?.isClosed == false;

  /// Register both the text and event channels for [messageId].
  StreamController<String> register(String messageId) {
    final controller = StreamController<String>.broadcast();
    _streams[messageId] = controller;
    _eventStreams[messageId] = StreamController<ThinkingEvent>.broadcast();
    return controller;
  }

  /// Adds a text delta to the stream for [messageId].
  void add(String messageId, String value) {
    _streams[messageId]?.add(value);
  }

  /// Adds a structured thinking event to the stream for [messageId].
  void addEvent(String messageId, ThinkingEvent event) {
    _eventStreams[messageId]?.add(event);
  }

  /// Close both channels for [messageId].
  Future<void> unregister(String messageId) async {
    final controller = _streams.remove(messageId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
    final events = _eventStreams.remove(messageId);
    if (events != null && !events.isClosed) {
      await events.close();
    }
  }
}
