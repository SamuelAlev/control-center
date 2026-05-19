import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:control_center/features/ticketing/domain/ports/ticket_provider_capabilities.dart';
import 'package:control_center/features/ticketing/domain/ports/ticket_provider_port.dart';
import 'package:control_center/features/ticketing/domain/ports/ticket_query.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';

/// The local provider — its "backend" IS the Control Center database, so this
/// adapter is a thin projection over [TicketRepository]. It never syncs
/// (`supportsRemoteSync == false`): the local row is already the source of
/// truth. The `TicketWorkflowService` writes local tickets directly through the
/// repository, so `create`/`transitionStatus` here are only used when something
/// drives the port uniformly across providers.
class LocalTicketAdapter implements TicketProviderPort {
  /// Creates a [LocalTicketAdapter].
  const LocalTicketAdapter(this._repository);

  final TicketRepository _repository;

  @override
  TicketProvider get provider => TicketProvider.local;

  @override
  TicketProviderCapabilities get capabilities =>
      const TicketProviderCapabilities.full(TicketProvider.local);

  @override
  List<String> get allowedDomains => const [];

  @override
  Future<RemoteTicket> create(RemoteTicketDraft draft) async {
    // Local creation is owned by TicketWorkflowService.createTicket; this path
    // is intentionally not used for the local provider.
    throw UnsupportedError(
      'Use TicketWorkflowService.createTicket for local tickets.',
    );
  }

  @override
  Future<RemoteTicket?> getByExternalId(String externalId) async {
    final ticket =
        await _repository.getByExternal(TicketProvider.local, externalId);
    return ticket == null ? null : _toRemote(ticket);
  }

  @override
  Future<List<RemoteTicket>> list({TicketQuery query = const TicketQuery()}) {
    // Local listing is served reactively from the DB via providers, not the
    // port; sync is a no-op for local.
    return Future.value(const []);
  }

  @override
  Future<RemoteTicket> update(String externalId, RemoteTicketPatch patch) {
    throw UnsupportedError(
      'Use TicketWorkflowService for local ticket updates.',
    );
  }

  @override
  Future<RemoteTicket> transitionStatus(
    String externalId,
    TicketStatus target,
  ) {
    throw UnsupportedError(
      'Use TicketWorkflowService.transitionStatus for local tickets.',
    );
  }

  @override
  Future<RemoteTicket> assign(String externalId, String? assigneeExternalId) {
    throw UnsupportedError(
      'Use TicketWorkflowService.assign for local tickets.',
    );
  }

  @override
  Stream<RemoteTicket> watchAssigned() => const Stream.empty();

  RemoteTicket _toRemote(Ticket t) => RemoteTicket(
        externalId: t.externalKey ?? t.id,
        externalKey: t.externalKey,
        url: t.url,
        title: t.title,
        description: t.description,
        priority: t.priority,
        labels: t.labels,
        status: t.status,
        rawStatus: t.rawStatus,
        assigneeExternalId: t.assignedAgentId,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      );
}
