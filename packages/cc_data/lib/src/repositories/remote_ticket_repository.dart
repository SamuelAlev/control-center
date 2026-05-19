import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates tickets over the RPC client instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so these calls never pass a
/// `workspace_id` — the server injects the authoritative one. Mirrors the
/// `tickets.*` ops + `tickets.watchForWorkspace` query in the host catalog.
class RemoteTicketRepository {
  /// Creates a [RemoteTicketRepository] over [_client].
  RemoteTicketRepository(this._client);

  final RemoteRpcClient _client;

  /// All tickets in the bound workspace.
  Future<List<TicketDto>> list() async {
    final data = await _client.call('tickets.list', const {});
    return _tickets(data);
  }

  /// A single ticket by id (scoped to the bound workspace server-side).
  Future<TicketDto> get(String ticketId) async {
    final data = await _client.call('tickets.get', {'ticket_id': ticketId});
    return TicketDto.fromJson((data['ticket'] as Map).cast<String, dynamic>());
  }

  /// Assigns [ticketId] to an agent or team; returns the updated ticket (or
  /// null if the server reported no row).
  Future<TicketDto?> assign(
    String ticketId, {
    String? agentId,
    String? teamId,
  }) async {
    final data = await _client.call('tickets.assign', {
      'ticket_id': ticketId,
      'agent_id': ?agentId,
      'team_id': ?teamId,
    });
    final ticket = data['ticket'];
    return ticket is Map
        ? TicketDto.fromJson(ticket.cast<String, dynamic>())
        : null;
  }

  /// Inserts [ticket] (the host owns persistence; the workspace is bound
  /// server-side and validated against the payload).
  Future<void> insert(TicketDto ticket) =>
      _client.call('tickets.insert', {'ticket': ticket.toJson()});

  /// Updates [ticket] with optimistic concurrency. When [expectedVersion] is
  /// stale the host throws and the call surfaces a [RemoteRpcException] carrying
  /// [RpcErrorCodes.conflict].
  Future<void> update(TicketDto ticket, {int? expectedVersion}) =>
      _client.call('tickets.update', {
        'ticket': ticket.toJson(),
        'expected_version': ?expectedVersion,
      });

  /// Deletes the ticket [ticketId] (ownership-checked server-side against the
  /// bound workspace; a foreign ticket is a no-op).
  Future<void> delete(String ticketId) =>
      _client.call('tickets.delete', {'ticket_id': ticketId});

  /// Live tickets in the bound workspace — a fresh snapshot on every change.
  Stream<List<TicketDto>> watch() =>
      _client.subscribe('tickets.watchForWorkspace', const {}).map(_tickets);

  /// Adds a collaborator to a ticket (ownership-checked server-side). The
  /// client passes the id/joinedAt it minted so the row round-trips losslessly.
  Future<void> addCollaborator({
    required String id,
    required String ticketId,
    required String agentId,
    required String role,
    required String joinedAt,
  }) => _client.call('tickets.addCollaborator', {
    'id': id,
    'ticket_id': ticketId,
    'agent_id': agentId,
    'role': role,
    'joined_at': joinedAt,
  });

  /// Removes the collaborator [agentId] from [ticketId].
  Future<void> removeCollaborator(String ticketId, String agentId) =>
      _client.call('tickets.removeCollaborator', {
        'ticket_id': ticketId,
        'agent_id': agentId,
      });

  /// A ticket's collaborators (ownership-checked server-side).
  Future<List<Map<String, dynamic>>> getCollaborators(String ticketId) async {
    final data = await _client.call('tickets.getCollaborators', {
      'ticket_id': ticketId,
    });
    return _collaborators(data);
  }

  /// Live collaborators for a ticket — a fresh snapshot on every change.
  Stream<List<Map<String, dynamic>>> watchCollaborators(String ticketId) =>
      _client
          .subscribe('tickets.watchCollaborators', {'ticket_id': ticketId})
          .map(_collaborators);

  List<TicketDto> _tickets(Map<String, dynamic> data) =>
      ((data['tickets'] as List?) ?? const [])
          .whereType<Map>()
          .map((t) => TicketDto.fromJson(t.cast<String, dynamic>()))
          .toList();

  List<Map<String, dynamic>> _collaborators(Map<String, dynamic> data) =>
      ((data['collaborators'] as List?) ?? const [])
          .whereType<Map>()
          .map((c) => c.cast<String, dynamic>())
          .toList();
}
