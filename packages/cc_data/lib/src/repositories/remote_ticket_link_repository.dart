import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates ticket dependency links over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one and
/// enforces that the link belongs to that workspace before touching it (links
/// carry their own `workspace_id`, but an ID/endpoint lookup is not itself a
/// scoping boundary). Mirrors the `ticket_link.*` ops + the
/// `ticket_link.watchForTicket` subscription in the host catalog.
class RemoteTicketLinkRepository {
  /// Creates a [RemoteTicketLinkRepository] over [_client].
  RemoteTicketLinkRepository(this._client);

  final RemoteRpcClient _client;

  /// Inserts [link] (the host owns persistence; idempotent on
  /// `(source, target, type)`).
  Future<void> insert(TicketLinkDto link) =>
      _client.call('ticket_link.insert', {'link': link.toJson()});

  /// Deletes a link by id in the bound workspace. Returns rows deleted.
  Future<int> deleteById(String id) async {
    final data = await _client.call('ticket_link.deleteById', {'id': id});
    return (data['deleted'] as num?)?.toInt() ?? 0;
  }

  /// Deletes a link identified by its endpoints + type in the bound workspace.
  /// Returns rows deleted.
  Future<int> deleteByEndpoints({
    required String sourceTicketId,
    required String targetTicketId,
    required String type,
  }) async {
    final data = await _client.call('ticket_link.deleteByEndpoints', {
      'source_ticket_id': sourceTicketId,
      'target_ticket_id': targetTicketId,
      'type': type,
    });
    return (data['deleted'] as num?)?.toInt() ?? 0;
  }

  /// All links touching [ticketId] (source or target) in the bound workspace.
  Future<List<TicketLinkDto>> getForTicket(String ticketId) async {
    final data = await _client.call('ticket_link.getForTicket', {
      'ticket_id': ticketId,
    });
    return _links(data);
  }

  /// Live links touching [ticketId] (source or target) in the bound workspace —
  /// a fresh snapshot on every change.
  Stream<List<TicketLinkDto>> watchForTicket(String ticketId) => _client
      .subscribe('ticket_link.watchForTicket', {'ticket_id': ticketId})
      .map(_links);

  List<TicketLinkDto> _links(Map<String, dynamic> data) =>
      ((data['links'] as List?) ?? const [])
          .whereType<Map>()
          .map((l) => TicketLinkDto.fromJson(l.cast<String, dynamic>()))
          .toList();
}
