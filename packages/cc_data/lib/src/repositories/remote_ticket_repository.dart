import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates tickets over the RPC client instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The server is stateless
/// (it holds no session workspace) and a workspace id selects the database file,
/// so every op that names a single ticket carries its `workspace_id` — a ticket
/// id is a uuid, not an access boundary, and one from another workspace must not
/// resolve. [watch] likewise pins its stream to the workspace the caller named
/// so a switch can't race the client's ambient id into it. Mirrors the
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

  /// A single ticket by id within [workspaceId]. A ticket owned by another
  /// workspace is not matched.
  Future<TicketDto> get(String workspaceId, String ticketId) async {
    final data = await _client.call('tickets.get', {
      'workspace_id': workspaceId,
      'ticket_id': ticketId,
    });
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
  Future<void> insert(TicketDto ticket) => _client.call('tickets.insert', {
    // The ticket's own workspace, sent explicitly rather than left to the
    // client's ambient session id: the host asserts the two agree, so relying on
    // the ambient value only means the assertion fires whenever the caller is on
    // another workspace's route.
    'workspace_id': ticket.workspaceId,
    'ticket': ticket.toJson(),
  });

  /// Updates [ticket] with optimistic concurrency. When [expectedVersion] is
  /// stale the host throws and the call surfaces a [RemoteRpcException] carrying
  /// [RpcErrorCodes.conflict].
  Future<void> update(TicketDto ticket, {int? expectedVersion}) => _client.call(
    'tickets.update',
    {'ticket': ticket.toJson(), 'expected_version': ?expectedVersion},
  );

  /// Per-column LWW field patch (PRD 16 §6): concurrent edits to DIFFERENT
  /// fields both land in server receipt order — no `expectedVersion`, no
  /// clobbering. Only `title` / `description` / `priority` / `labels` are
  /// patchable (the host validates and throws on any other key). Returns the
  /// patched ticket, or null if the server reported no row in [workspaceId].
  Future<TicketDto?> patchFields(
    String workspaceId,
    String ticketId,
    Map<String, dynamic> fields, {
    String? idempotencyKey,
  }) async {
    final data = await _client.call('tickets.patch', {
      'workspace_id': workspaceId,
      'ticket_id': ticketId,
      'fields': fields,
    }, idempotencyKey: idempotencyKey);
    final ticket = data['ticket'];
    return ticket is Map
        ? TicketDto.fromJson(ticket.cast<String, dynamic>())
        : null;
  }

  /// Deletes the ticket [ticketId] from [workspaceId]. A ticket owned by
  /// another workspace is not matched.
  Future<void> delete(String workspaceId, String ticketId) => _client.call(
    'tickets.delete',
    {'workspace_id': workspaceId, 'ticket_id': ticketId},
  );

  /// Live tickets of [workspaceId] — a fresh snapshot on every change — or of
  /// the client's ambient active workspace when it is omitted.
  ///
  /// A workspace-keyed caller MUST pass its own id: the ambient injection
  /// follows the active route and flips on a switch independently of the
  /// workspace being asked about, so relying on it lets a `family` provider
  /// keyed by workspace be answered with another workspace's tickets. An
  /// explicit `workspace_id` in the args wins over the injection.
  Stream<List<TicketDto>> watch({String? workspaceId}) => _client
      .subscribe('tickets.watchForWorkspace', {'workspace_id': ?workspaceId})
      .map(_tickets);

  /// Adds a collaborator to a ticket in [workspaceId]. The client passes the
  /// id/joinedAt it minted so the row round-trips losslessly.
  Future<void> addCollaborator({
    required String workspaceId,
    required String id,
    required String ticketId,
    required String principalId,
    required String collaboratorType,
    required String role,
    required String joinedAt,
  }) => _client.call('tickets.addCollaborator', {
    'workspace_id': workspaceId,
    'id': id,
    'ticket_id': ticketId,
    'principal_id': principalId,
    'collaborator_type': collaboratorType,
    'role': role,
    'joined_at': joinedAt,
  });

  /// Removes the collaborator [principalId] from [ticketId] in [workspaceId].
  Future<void> removeCollaborator(
    String workspaceId,
    String ticketId,
    String principalId,
  ) => _client.call('tickets.removeCollaborator', {
    'workspace_id': workspaceId,
    'ticket_id': ticketId,
    'principal_id': principalId,
  });

  /// A ticket's collaborators within [workspaceId].
  Future<List<Map<String, dynamic>>> getCollaborators(
    String workspaceId,
    String ticketId,
  ) async {
    final data = await _client.call('tickets.getCollaborators', {
      'workspace_id': workspaceId,
      'ticket_id': ticketId,
    });
    return _collaborators(data);
  }

  /// Live collaborators for a ticket in [workspaceId] — a fresh snapshot on
  /// every change.
  Stream<List<Map<String, dynamic>>> watchCollaborators(
    String workspaceId,
    String ticketId,
  ) => _client
      .subscribe('tickets.watchCollaborators', {
        'workspace_id': workspaceId,
        'ticket_id': ticketId,
      })
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
