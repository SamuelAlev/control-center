import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:control_center/features/ticketing/domain/ports/ticket_provider_port.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart' show TicketWorkflowService;

/// Pushes ticket changes to the active remote provider.
///
/// Listens to domain events and mirrors the local ticket state to the remote
/// tracker. This keeps [TicketWorkflowService] pure (no infrastructure calls)
/// while ensuring remote-backed tickets stay in sync.
class TicketRemoteSyncHandler {
  TicketRemoteSyncHandler({
    required this.eventBus,
    required this.repository,
    required this.providerPort,
  });

  final DomainEventBus eventBus;
  final TicketRepository repository;
  final TicketProviderPort providerPort;

  final List<StreamSubscription<dynamic>> _subs = [];

  void start() {
    _subs
      ..add(eventBus.on<TicketCreated>().listen(_onCreated))
      ..add(eventBus.on<TicketStatusChanged>().listen(_onStatusChanged))
      ..add(eventBus.on<TicketAssigned>().listen(_onAssigned))
      ..add(eventBus.on<TicketReassigned>().listen(_onReassigned))
      ..add(eventBus.on<TicketDetailsUpdated>().listen(_onDetailsUpdated));
  }

  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  Future<void> _onCreated(TicketCreated event) async {
    final ticket = await repository.getById(event.ticketId);
    if (ticket == null || !ticket.isRemote) return;
    if (ticket.provider != providerPort.provider) return;
    if (!providerPort.capabilities.supportsCreate) return;

    try {
      final remote = await providerPort.create(
        RemoteTicketDraft(
          title: ticket.title,
          description: ticket.description,
          priority: ticket.priority,
          labels: ticket.labels,
          parentExternalId: ticket.parentTicketId,
        ),
      );
      await repository.upsertMirror(
        ticket.copyWith(
          externalKey: remote.externalKey ?? remote.externalId,
          url: remote.url,
          rawStatus: remote.rawStatus,
          metadata: {'externalId': remote.externalId},
        ),
      );
    } on Object catch (e, st) {
      AppLog.e('TicketRemoteSyncHandler', 'remote create failed', e, st);
    }
  }

  Future<void> _onStatusChanged(TicketStatusChanged event) async {
    final ticket = await repository.getById(event.ticketId);
    if (ticket == null || !ticket.isRemote) return;
    if (ticket.provider != providerPort.provider) return;
    if (!providerPort.capabilities.supportsStatusUpdate) return;
    if (ticket.externalKey == null) return;

    final status = TicketStatus.fromStorage(event.to);
    try {
      await providerPort.transitionStatus(ticket.externalKey!, status);
    } on Object catch (e, st) {
      AppLog.e('TicketRemoteSyncHandler', 'remote status push failed', e, st);
    }
  }

  Future<void> _onAssigned(TicketAssigned event) async {
    final ticket = await repository.getById(event.ticketId);
    if (ticket == null || !ticket.isRemote) return;
    if (ticket.provider != providerPort.provider) return;
    if (!providerPort.capabilities.supportsAssignee) return;
    if (ticket.externalKey == null) return;
    if (ticket.assignedAgentId == null) return;

    try {
      await providerPort.assign(
        ticket.externalKey!,
        ticket.assignedAgentId!,
      );
    } on Object catch (e, st) {
      AppLog.e('TicketRemoteSyncHandler', 'remote assign failed', e, st);
    }
  }

  Future<void> _onReassigned(TicketReassigned event) async {
    await _onAssigned(TicketAssigned(
      ticketId: event.ticketId,
      ticketTitle: '',
      assignedAgentId: event.toAgentId,
      occurredAt: event.occurredAt,
    ));
  }

  Future<void> _onDetailsUpdated(TicketDetailsUpdated event) async {
    final ticket = await repository.getById(event.ticketId);
    if (ticket == null || !ticket.isRemote) return;
    if (ticket.provider != providerPort.provider) return;
    if (!providerPort.capabilities.supportsUpdate) return;
    if (ticket.externalKey == null) return;

    try {
      await providerPort.update(
        ticket.externalKey!,
        RemoteTicketPatch(
          title: ticket.title,
          description: ticket.description,
          priority: ticket.priority,
        ),
      );
    } on Object catch (e, st) {
      AppLog.e('TicketRemoteSyncHandler', 'remote update failed', e, st);
    }
  }
}
