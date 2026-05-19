/// Logs domain activity events to the event bus for observability.
library;

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:uuid/uuid.dart';

/// Publishes domain activity events to the event bus for observability.
class ActivityLogger {
  /// Creates an [ActivityLogger] that publishes to the optional [eventBus].
  ActivityLogger({DomainEventBus? eventBus}) : _eventBus = eventBus;

  final DomainEventBus? _eventBus;
  static const _uuid = Uuid();

  /// Logs a domain activity event with the given parameters.
  ///
  /// [actorType] is `agent` / `user` / `system` — it is the persisted wire
  /// value of the `activity_log.actor_type` column, which is why it stays a
  /// string here. Call sites should not pass it directly: use [logAgentRun],
  /// [logUserAction] or [logSystemAction], which are the typed surface.
  void log({
    required String actorType,
    String? actorId,
    required String action,
    required String entityType,
    String? entityId,
    String? details,
    String? workspaceId,
    String? runId,
  }) {
    final id = _uuid.v4();
    final event = ActivityLogged(
      id: id,
      actorType: actorType,
      actorId: actorId,
      action: action,
      entityType: entityType,
      entityId: entityId,
      details: details,
      workspaceId: workspaceId,
      runId: runId,
      occurredAt: DateTime.now(),
    );
    _eventBus?.publish(event);
  }

  /// Logs an agent run activity event.
  void logAgentRun({
    required String agentId,
    required String action,
    String? workspaceId,
    String? conversationId,
    String? details,
    String? runId,
  }) {
    log(
      actorType: 'agent',
      actorId: agentId,
      action: action,
      entityType: 'run',
      entityId: conversationId,
      details: details,
      // Was accepted and then DROPPED: every agent-run `ActivityLogged` event
      // arrived with a null workspaceId, so no listener could scope or filter
      // it — in the audit path, of all places.
      workspaceId: workspaceId,
      runId: runId,
    );
  }

  /// Logs a user action activity event.
  void logUserAction({
    required String action,
    required String entityType,
    String? entityId,
    String? details,
    String? actorId,
    String? workspaceId,
  }) {
    log(
      actorType: 'user',
      actorId: actorId,
      action: action,
      entityType: entityType,
      entityId: entityId,
      details: details,
      workspaceId: workspaceId,
    );
  }

  /// Logs a system action activity event.
  void logSystemAction({
    required String action,
    required String entityType,
    String? entityId,
    String? details,
    String? workspaceId,
  }) {
    log(
      actorType: 'system',
      action: action,
      entityType: entityType,
      entityId: entityId,
      details: details,
      workspaceId: workspaceId,
    );
  }
}
