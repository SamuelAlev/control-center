import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/memory_events.dart';

/// A bounded, replayable view over the workspace's memory events, ported from
/// oh-my-pi mnemopi `core/streaming.ts` `MemoryStream`.
///
/// Wraps the shared [DomainEventBus]: it forwards every [MemoryEvent] as a live
/// stream and retains the most recent [maxBuffer] events for late subscribers to
/// replay (e.g. a memory panel that opens mid-session and wants recent history).
class MemoryStream {
  /// Creates a [MemoryStream] over the event bus, retaining up to [maxBuffer]
  /// events. Call `start` to begin buffering.
  MemoryStream(this._eventBus, {this.maxBuffer = 1000});

  final DomainEventBus _eventBus;

  /// Maximum number of events retained for replay.
  final int maxBuffer;

  final List<MemoryEvent> _buffer = <MemoryEvent>[];
  StreamSubscription<MemoryEvent>? _sub;

  /// Live stream of memory events (delegates to the shared bus).
  Stream<MemoryEvent> get events => _eventBus.on<MemoryEvent>();

  /// Begins retaining events for replay.
  void start() {
    _sub ??= _eventBus.on<MemoryEvent>().listen(_record);
  }

  void _record(MemoryEvent event) {
    _buffer.add(event);
    if (_buffer.length > maxBuffer) {
      _buffer.removeRange(0, _buffer.length - maxBuffer);
    }
  }

  /// Returns buffered events, optionally only those at/after [since] and/or
  /// scoped to [workspaceId]. Newest events are last.
  List<MemoryEvent> replay({DateTime? since, String? workspaceId}) {
    return _buffer.where((e) {
      if (since != null && e.occurredAt.isBefore(since)) {
        return false;
      }
      if (workspaceId != null && e.workspaceId != workspaceId) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Clears the replay buffer.
  void clear() => _buffer.clear();

  /// Stops buffering.
  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}