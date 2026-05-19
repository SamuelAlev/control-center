import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart' show Ticket;
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_capabilities.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_query.dart';

/// The vendor-agnostic boundary between Control Center and a ticketing backend.
///
/// The rest of the codebase talks only to this port (and to [Ticket] /
/// [TicketStatus]); every vendor-specific detail (GraphQL, REST, auth, status
/// normalization) lives inside an adapter folder. Selected at onboarding via
/// the pool + active + firstWhere pattern (the `SandboxPort` analogue).
abstract interface class TicketProviderPort {
  /// The backend this adapter implements.
  TicketProvider get provider;

  /// What this adapter supports.
  TicketProviderCapabilities get capabilities;

  /// Network domains the adapter needs reachable from a sandboxed agent
  /// (threaded into the sandbox allow-list as plain data — no import coupling).
  List<String> get allowedDomains;

  /// Creates a ticket on the backend.
  Future<RemoteTicket> create(RemoteTicketDraft draft);

  /// Fetches a ticket by its provider id, or null if missing.
  Future<RemoteTicket?> getByExternalId(String externalId);

  /// Lists tickets matching [query].
  Future<List<RemoteTicket>> list({TicketQuery query = const TicketQuery()});

  /// Applies a partial update.
  Future<RemoteTicket> update(String externalId, RemoteTicketPatch patch);

  /// Transitions a ticket to a normalized [target] status.
  Future<RemoteTicket> transitionStatus(String externalId, TicketStatus target);

  /// Assigns (or clears, when null) the remote assignee.
  Future<RemoteTicket> assign(String externalId, String? assigneeExternalId);

  /// Streams tickets assigned to the current user, for live mirroring.
  Stream<RemoteTicket> watchAssigned();
}
