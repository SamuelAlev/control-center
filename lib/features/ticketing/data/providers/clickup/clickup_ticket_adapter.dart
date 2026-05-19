import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:control_center/features/ticketing/domain/ports/ticket_provider_capabilities.dart';
import 'package:control_center/features/ticketing/domain/ports/ticket_provider_port.dart';
import 'package:control_center/features/ticketing/domain/ports/ticket_query.dart';

/// ClickUp provider — scaffolded for the abstraction, not yet implemented.
class ClickUpTicketAdapter implements TicketProviderPort {
  /// Creates a [ClickUpTicketAdapter].
  const ClickUpTicketAdapter();

  static const _msg = 'ClickUp ticketing is not yet implemented.';

  @override
  TicketProvider get provider => TicketProvider.clickup;

  @override
  TicketProviderCapabilities get capabilities =>
      const TicketProviderCapabilities.none(TicketProvider.clickup);

  @override
  List<String> get allowedDomains => const [];

  @override
  Future<RemoteTicket> create(RemoteTicketDraft draft) =>
      throw UnimplementedError(_msg);

  @override
  Future<RemoteTicket?> getByExternalId(String externalId) =>
      throw UnimplementedError(_msg);

  @override
  Future<List<RemoteTicket>> list({TicketQuery query = const TicketQuery()}) =>
      throw UnimplementedError(_msg);

  @override
  Future<RemoteTicket> update(String externalId, RemoteTicketPatch patch) =>
      throw UnimplementedError(_msg);

  @override
  Future<RemoteTicket> transitionStatus(
    String externalId,
    TicketStatus target,
  ) =>
      throw UnimplementedError(_msg);

  @override
  Future<RemoteTicket> assign(String externalId, String? assigneeExternalId) =>
      throw UnimplementedError(_msg);

  @override
  Stream<RemoteTicket> watchAssigned() => const Stream.empty();
}
