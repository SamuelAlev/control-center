import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_capabilities.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_port.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_query.dart';

/// Jira provider — scaffolded for the abstraction, not yet implemented. Its
/// capabilities report everything unsupported so the UI/onboarding can list it
/// as "coming soon" without exposing actions that would throw.
class JiraTicketAdapter implements TicketProviderPort {
  /// Creates a [JiraTicketAdapter].
  const JiraTicketAdapter();

  static const _msg = 'Jira ticketing is not yet implemented.';

  @override
  TicketProvider get provider => TicketProvider.jira;

  @override
  TicketProviderCapabilities get capabilities =>
      const TicketProviderCapabilities.none(TicketProvider.jira);

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
