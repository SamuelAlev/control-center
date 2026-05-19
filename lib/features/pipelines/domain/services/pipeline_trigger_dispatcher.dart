import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:control_center/features/pipelines/domain/services/event_payload_mapper.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_engine.dart';

/// Subscribes to domain events and auto-starts pipeline runs for enabled
/// triggers.
///
/// Uses a compile-time-curated map of event types → subscriptions.
/// When an event fires, queries enabled triggers for that event type,
/// and calls [PipelineEngine.start] for each matching trigger.
class PipelineTriggerDispatcher {
  /// Creates a [PipelineTriggerDispatcher].
  PipelineTriggerDispatcher({
    required this.eventBus,
    required this.engine,
    required this.triggerRepository,
  });

  final DomainEventBus eventBus;
  final PipelineEngine engine;
  final PipelineTriggerRepository triggerRepository;

  StreamSubscription<DomainEvent>? _subscription;

  /// Starts listening for domain events.
  void start() {
    _subscription = eventBus.on<DomainEvent>().listen(_onEvent);
  }

  /// Stops listening.
  void dispose() {
    _subscription?.cancel();
  }

  Future<void> _onEvent(DomainEvent event) async {
    final typeName = EventPayloadMapper.typeName(event);
    if (!EventPayloadMapper.knownEventTypes.contains(typeName)) {
      return; // Short-circuit before the DB hit.
    }
    final payload = EventPayloadMapper.toPayload(event);
    if (payload == null) return;
    final dedupKey = EventPayloadMapper.dedupKeyFor(event);

    try {
      final triggers = await triggerRepository.enabledForEvent(typeName);
      final scopeWorkspaceId = payload['workspaceId'] as String?;
      for (final trigger in triggers) {
        if (scopeWorkspaceId != null &&
            trigger.workspaceId != scopeWorkspaceId) {
          continue;
        }
        // Honour the per-trigger value filter (e.g. PR status ∈ merged/closed).
        if (!trigger.matches(payload)) continue;
        final fullPayload = <String, dynamic>{
          ...payload,
          'workspaceId': trigger.workspaceId,
          'triggerEventType': typeName,
        };
        final run = await engine.start(
          trigger.templateId,
          workspaceId: trigger.workspaceId,
          triggerEventType: typeName,
          triggerPayload: fullPayload,
          dedupKey: dedupKey,
        );
        if (run != null) {
          AppLog.i(
            'PipelineTrigger',
            'Started ${trigger.templateId} for $typeName in workspace ${trigger.workspaceId}',
          );
        }
      }
    } on Object catch (e, st) {
      AppLog.e('PipelineTrigger', 'Failed to dispatch for $typeName', e, st);
    }
  }
}
