import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_engine.dart';

/// Bridges Control Center's ticket lifecycle events to the multi-vendor
/// [TicketSyncEngine]: every local create / status change / assignment / detail
/// edit is pushed out to every enabled vendor.
///
/// This is the multi-vendor superset of the single-active-provider remote sync:
/// it fires for a CC-primary ticket synced to any number of vendors, reading
/// connections from the workspace's sync configs. Vendor pulls write through the
/// engine without emitting domain events, so a mirrored-in change never reaches
/// this coordinator and cannot loop back out.
class MultiVendorTicketSyncCoordinator {
  /// Creates a [MultiVendorTicketSyncCoordinator].
  MultiVendorTicketSyncCoordinator({
    required this.eventBus,
    required this.engine,
    required this.repository,
  });

  /// Event bus carrying ticket lifecycle changes.
  final DomainEventBus eventBus;

  /// The sync engine the coordinator drives.
  final TicketSyncEngine engine;

  /// Ticket store, to load the current state an event refers to.
  final TicketRepository repository;

  final List<StreamSubscription<dynamic>> _subs = [];

  /// Subscribes to ticket lifecycle events.
  void start() {
    _subs
      ..add(
        eventBus.on<TicketCreated>().listen(
          (e) => _push(e.workspaceId, e.ticketId, TicketChangeType.created),
        ),
      )
      ..add(
        eventBus.on<TicketStatusChanged>().listen(
          (e) =>
              _push(e.workspaceId, e.ticketId, TicketChangeType.statusChanged),
        ),
      )
      ..add(
        eventBus.on<TicketAssigned>().listen(
          (e) => _push(e.workspaceId, e.ticketId, TicketChangeType.assigned),
        ),
      )
      ..add(
        eventBus.on<TicketReassigned>().listen(
          (e) => _push(e.workspaceId, e.ticketId, TicketChangeType.assigned),
        ),
      )
      ..add(
        eventBus.on<TicketDetailsUpdated>().listen(
          (e) => _push(e.workspaceId, e.ticketId, TicketChangeType.updated),
        ),
      );
  }

  /// Cancels all subscriptions.
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  Future<void> _push(
    String workspaceId,
    String ticketId,
    TicketChangeType changeType,
  ) async {
    try {
      final ticket = await repository.getById(workspaceId, ticketId);
      if (ticket == null) {
        return;
      }
      await engine.pushTicket(
        workspaceId: ticket.workspaceId,
        ticket: ticket,
        changeType: changeType,
      );
    } on Object catch (e, st) {
      CcDomainLog.error('MultiVendorTicketSyncCoordinator: push failed', e, st);
    }
  }
}
