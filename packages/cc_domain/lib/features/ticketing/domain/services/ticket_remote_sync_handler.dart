import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_port.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart' show TicketWorkflowService;

/// Pushes ticket changes to the active remote provider.
///
/// Listens to domain events and mirrors the local ticket state to the remote
/// tracker. This keeps [TicketWorkflowService] pure (no infrastructure calls)
/// while ensuring remote-backed tickets stay in sync.
class TicketRemoteSyncHandler {
  /// Creates a handler that mirrors local ticket events to the remote provider.
  TicketRemoteSyncHandler({
    required this.eventBus,
    required this.repository,
    required this.providerPort,
  });

  /// Event bus that publishes ticket lifecycle changes.
  final DomainEventBus eventBus;

  /// Repository used to load the latest local ticket state before syncing.
  final TicketRepository repository;

  /// Remote provider used to persist ticket changes outside the app.
  final TicketProviderPort providerPort;

  final List<StreamSubscription<dynamic>> _subs = [];

  /// Starts listening for ticket domain events and syncing them remotely.
  void start() {
    _subs
      ..add(eventBus.on<TicketCreated>().listen(_onCreated))
      ..add(eventBus.on<TicketStatusChanged>().listen(_onStatusChanged))
      ..add(eventBus.on<TicketAssigned>().listen(_onAssigned))
      ..add(eventBus.on<TicketReassigned>().listen(_onReassigned))
      ..add(eventBus.on<TicketDetailsUpdated>().listen(_onDetailsUpdated));
  }

  /// Cancels all event subscriptions held by this handler.
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  Future<void> _onCreated(TicketCreated event) async {
    final ticket = await repository.getById(event.ticketId);
    if (ticket == null || !ticket.isRemote) {
      return;
    }
    if (ticket.provider != providerPort.provider) {
      return;
    }
    if (!providerPort.capabilities.supportsCreate) {
      return;
    }

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
      CcDomainLog.error('TicketRemoteSyncHandler: remote create failed', e, st);
    }
  }

  Future<void> _onStatusChanged(TicketStatusChanged event) async {
    final ticket = await repository.getById(event.ticketId);
    if (ticket == null || !ticket.isRemote) {
      return;
    }
    if (ticket.provider != providerPort.provider) {
      return;
    }
    if (!providerPort.capabilities.supportsStatusUpdate) {
      return;
    }
    if (ticket.externalKey == null) {
      return;
    }

    final status = TicketStatus.fromStorage(event.to);
    try {
      await providerPort.transitionStatus(ticket.externalKey!, status);
    } on Object catch (e, st) {
      CcDomainLog.error('TicketRemoteSyncHandler: remote status push failed', e, st);
    }
  }

  Future<void> _onAssigned(TicketAssigned event) async {
    final ticket = await repository.getById(event.ticketId);
    if (ticket == null || !ticket.isRemote) {
      return;
    }
    if (ticket.provider != providerPort.provider) {
      return;
    }
    if (!providerPort.capabilities.supportsAssignee) {
      return;
    }
    if (ticket.externalKey == null) {
      return;
    }
    if (ticket.assignedAgentId == null) {
      return;
    }

    try {
      await providerPort.assign(
        ticket.externalKey!,
        ticket.assignedAgentId!,
      );
    } on Object catch (e, st) {
      CcDomainLog.error('TicketRemoteSyncHandler: remote assign failed', e, st);
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
    if (ticket == null || !ticket.isRemote) {
      return;
    }
    if (ticket.provider != providerPort.provider) {
      return;
    }
    if (!providerPort.capabilities.supportsUpdate) {
      return;
    }
    if (ticket.externalKey == null) {
      return;
    }

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
      CcDomainLog.error('TicketRemoteSyncHandler: remote update failed', e, st);
    }
  }
}
