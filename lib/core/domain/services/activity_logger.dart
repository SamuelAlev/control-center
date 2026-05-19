import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/observability_events.dart';
import 'package:uuid/uuid.dart';

class ActivityLogger {
  ActivityLogger({DomainEventBus? eventBus}) : _eventBus = eventBus;

  final DomainEventBus? _eventBus;
  static const _uuid = Uuid();

  void log({
    required String actorType,
    String? actorId,
    required String action,
    required String entityType,
    String? entityId,
    String? details,
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
      occurredAt: DateTime.now(),
    );
    _eventBus?.publish(event);
  }

  void logAgentRun({
    required String agentId,
    required String action,
    String? workspaceId,
    String? conversationId,
    String? details,
  }) {
    log(
      actorType: 'agent',
      actorId: agentId,
      action: action,
      entityType: 'run',
      entityId: conversationId,
      details: details,
    );
  }

  void logUserAction({
    required String action,
    required String entityType,
    String? entityId,
    String? details,
  }) {
    log(
      actorType: 'user',
      action: action,
      entityType: entityType,
      entityId: entityId,
      details: details,
    );
  }

  void logSystemAction({
    required String action,
    required String entityType,
    String? entityId,
    String? details,
  }) {
    log(
      actorType: 'system',
      action: action,
      entityType: entityType,
      entityId: entityId,
      details: details,
    );
  }
}
