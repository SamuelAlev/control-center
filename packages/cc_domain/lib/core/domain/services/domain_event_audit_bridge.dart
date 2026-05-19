import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/orchestration_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/services/activity_logger.dart';

/// Converts selected workspace-scoped domain events into [ActivityLogger]
/// calls, so the audit trail is fed from one funnel (the logger publishes
/// `ActivityLogged`, which `ActivityLogPersister` writes). Only events that
/// carry a `workspaceId` are bridged, so every audit row is workspace-scoped.
class DomainEventAuditBridge {
  /// Creates a [DomainEventAuditBridge].
  DomainEventAuditBridge({
    required DomainEventBus eventBus,
    required ActivityLogger logger,
  })  : _eventBus = eventBus,
        _logger = logger;

  final DomainEventBus _eventBus;
  final ActivityLogger _logger;

  final List<StreamSubscription<dynamic>> _subs = [];

  /// Starts bridging events.
  void start() {
    _subs
      ..add(_eventBus.on<TicketAssigned>().listen((e) {
        _logger.log(
          actorType: e.assignedAgentId != null ? 'agent' : 'system',
          actorId: e.assignedAgentId,
          action: 'ticket_assigned',
          entityType: 'ticket',
          entityId: e.ticketId,
          workspaceId: e.workspaceId,
          details: e.ticketTitle,
        );
      }))
      ..add(_eventBus.on<TicketStatusChanged>().listen((e) {
        // Capture the meaningful terminal transitions.
        if (e.to != 'done' && e.to != 'failed' && e.to != 'cancelled') {
          return;
        }
        _logger.log(
          actorType: 'system',
          action: 'ticket_${e.to}',
          entityType: 'ticket',
          entityId: e.ticketId,
          workspaceId: e.workspaceId,
          details: 'from ${e.from}',
        );
      }))
      ..add(_eventBus.on<AgentRunCompleted>().listen((e) {
        final ws = e.workspaceId;
        if (ws == null) {
          return;
        }
        _logger.log(
          actorType: 'agent',
          actorId: e.agentId,
          action: 'run_completed',
          entityType: 'run',
          entityId: e.runId ?? e.conversationId,
          workspaceId: ws,
          runId: e.runId,
        );
      }))
      ..add(_eventBus.on<OrchestrationApproved>().listen((e) => _orch(e, 'approved')))
      ..add(_eventBus.on<OrchestrationExecutionStarted>()
          .listen((e) => _orch(e, 'execution_started')))
      ..add(_eventBus.on<OrchestrationCompleted>().listen((e) => _orch(e, 'completed')))
      ..add(_eventBus.on<OrchestrationFailed>().listen((e) => _orch(e, 'failed')))
      ..add(_eventBus.on<OrchestrationCancelled>().listen((e) => _orch(e, 'cancelled')));
  }

  void _orch(OrchestrationEvent e, String action) {
    _logger.log(
      actorType: 'system',
      action: 'orchestration_$action',
      entityType: 'orchestration',
      entityId: e.orchestrationId,
      workspaceId: e.workspaceId,
    );
  }

  /// Stops bridging.
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }
}
