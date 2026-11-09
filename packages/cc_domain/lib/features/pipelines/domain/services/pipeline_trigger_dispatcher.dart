import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/event_payload_mapper.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';

/// Subscribes to domain events and auto-starts pipeline runs for enabled
/// triggers.
///
/// Uses a compile-time-curated map of event types → subscriptions. When an
/// event fires, queries enabled triggers for that event type and calls
/// [PipelineEngine.start] for each matching trigger **of the event's own
/// workspace**.
///
/// Workspace scoping fails closed: an event whose payload names no
/// `workspace_id` starts nothing, because the alternative is firing the
/// matching trigger in every workspace on the install. One trigger that throws
/// is logged and the remaining triggers still fire.
class PipelineTriggerDispatcher {
  /// Creates a [PipelineTriggerDispatcher].
  PipelineTriggerDispatcher({
    required this.eventBus,
    required this.engine,
    required this.triggerRepository,
  });

  /// The domain event bus to listen on.
  final DomainEventBus eventBus;

  /// The pipeline engine used to start runs.
  final PipelineEngine engine;

  /// Repository for looking up enabled triggers.
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
    if (payload == null) {
      return;
    }
    final scopeWorkspaceId = payload['workspace_id'];
    if (scopeWorkspaceId is! String || scopeWorkspaceId.isEmpty) {
      CcDomainLog.warning(
        'PipelineTrigger: $typeName carries no workspace_id; '
        'not offering it to any workspace\'s triggers.',
      );
      return;
    }
    final dedupKey = EventPayloadMapper.dedupKeyFor(event);

    final List<PipelineTrigger> triggers;
    try {
      triggers = await triggerRepository.enabledForEvent(typeName);
    } on Object catch (e, st) {
      CcDomainLog.error(
        'PipelineTrigger: Failed to load triggers for $typeName',
        e,
        st,
      );
      return;
    }
    for (final trigger in triggers) {
      if (trigger.workspaceId != scopeWorkspaceId) {
        continue;
      }
      // Honour the per-trigger value filter (e.g. PR status ∈ merged/closed).
      if (!trigger.matches(payload)) {
        continue;
      }
      try {
        final run = await engine.start(
          trigger.templateId,
          workspaceId: trigger.workspaceId,
          triggerEventType: typeName,
          triggerPayload: {...payload, 'triggerEventType': typeName},
          dedupKey: dedupKey,
        );
        if (run != null) {
          CcDomainLog.info(
            'PipelineTrigger: Started ${trigger.templateId} for $typeName in '
            'workspace ${trigger.workspaceId}',
          );
        }
      } on Object catch (e, st) {
        CcDomainLog.error(
          'PipelineTrigger: trigger ${trigger.id} (${trigger.templateId}) '
          'failed to start for $typeName',
          e,
          st,
        );
      }
    }
  }
}
