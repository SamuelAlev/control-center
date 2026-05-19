import 'package:cc_data/src/repositories/remote_ticket_link_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [TicketLinkRepository] backed by the RPC client — the thin-client data
/// path for ticket dependency links.
///
/// Implements the domain interface over the host's `ticket_link.*` ops + the
/// `ticket_link.watchForTicket` subscription, mapping the [TicketLinkDto] wire
/// shape back to [TicketLink]. The host owns persistence and enforces that each
/// link belongs to the bound workspace; this client never touches a database.
/// The `workspaceId` arguments the interface threads are bound server-side, so
/// they are dropped on the wire (the server supplies the authoritative one).
class RpcTicketLinkRepository implements TicketLinkRepository {
  /// Creates an [RpcTicketLinkRepository] over [client].
  RpcTicketLinkRepository(RemoteRpcClient client)
    : _remote = RemoteTicketLinkRepository(client);

  final RemoteTicketLinkRepository _remote;

  /// Rebuilds a [TicketLink] from its wire DTO. The `type` enum is encoded as
  /// its stored snake_case string; `createdAt` is an ISO-8601 string.
  static TicketLink _fromDto(TicketLinkDto d) => TicketLink(
    id: d.id,
    workspaceId: d.workspaceId,
    sourceTicketId: d.sourceTicketId,
    targetTicketId: d.targetTicketId,
    type: TicketLinkType.fromStorage(d.type) ?? TicketLinkType.relatesTo,
    createdAt: DateTime.parse(d.createdAt),
  );

  static TicketLinkDto _toDto(TicketLink l) => TicketLinkDto(
    id: l.id,
    workspaceId: l.workspaceId,
    sourceTicketId: l.sourceTicketId,
    targetTicketId: l.targetTicketId,
    type: l.type.toStorageString(),
    createdAt: l.createdAt.toIso8601String(),
  );

  @override
  Future<void> insert(TicketLink link) => _remote.insert(_toDto(link));

  @override
  Future<int> deleteById(String id, {required String workspaceId}) =>
      _remote.deleteById(id);

  @override
  Future<int> deleteByEndpoints({
    required String workspaceId,
    required String sourceTicketId,
    required String targetTicketId,
    required TicketLinkType type,
  }) => _remote.deleteByEndpoints(
    sourceTicketId: sourceTicketId,
    targetTicketId: targetTicketId,
    type: type.toStorageString(),
  );

  @override
  Future<List<TicketLink>> getForTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final dtos = await _remote.getForTicket(ticketId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Stream<List<TicketLink>> watchForTicket(String workspaceId, String ticketId) =>
      _remote.watchForTicket(ticketId).map(
        (dtos) => dtos.map(_fromDto).toList(),
      );
}
