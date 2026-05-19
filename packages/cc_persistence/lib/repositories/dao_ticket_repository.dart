import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_persistence/database/daos/ticket_dao.dart';
import 'package:cc_persistence/database/daos/workspace_route_dao.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/ticket_mapper.dart';

/// Drift-backed [TicketRepository].
///
/// Tickets live in their workspace's own database file, so every read and
/// write resolves `_dbs.of(workspaceId).ticketDao` first. The one lookup with
/// no workspace id — [getByExternal], reached from an inbound provider webhook
/// carrying nothing but `provider` + external key — resolves the owning
/// workspace through the global routing table, which is kept in step by
/// [_recordExternalRoute] on write and dropped in [delete].
class DaoTicketRepository implements TicketRepository {
  /// Creates a [DaoTicketRepository] over the per-workspace databases [_dbs],
  /// using [_routes] to resolve provider/external-key lookups to a workspace.
  DaoTicketRepository(this._dbs, this._routes);

  final WorkspaceDatabaseManager _dbs;
  final WorkspaceRouteDao _routes;
  static const _mapper = TicketMapper();

  TicketDao _dao(String workspaceId) => _dbs.of(workspaceId).ticketDao;

  /// The routing key for a mirrored ticket: `provider:externalKey`.
  static String _externalRouteKey(String provider, String externalKey) =>
      '$provider:$externalKey';

  /// Points the global routing table at [ticket]'s workspace, so a later
  /// provider webhook naming only `provider` + external key can find it.
  ///
  /// Written after the row so the route never resolves to a ticket that does
  /// not exist yet. A ticket with no external key has nothing to route.
  Future<void> _recordExternalRoute(Ticket ticket) async {
    final externalKey = ticket.externalKey;
    if (externalKey == null) {
      return;
    }
    await _routes.put(
      WorkspaceRouteKind.ticketExternalKey,
      _externalRouteKey(ticket.provider.toStorageString(), externalKey),
      ticket.workspaceId,
    );
  }

  @override
  Future<void> insert(Ticket ticket) async {
    await _dao(ticket.workspaceId).insert(_mapper.toCompanion(ticket));
    await _recordExternalRoute(ticket);
  }

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async {
    await _dao(ticket.workspaceId).updateById(
      ticket.id,
      _mapper.toCompanion(ticket),
      expectedVersion: expectedVersion,
    );
    // An external key can be attached to a local ticket after creation (the
    // first push to a vendor), so the route is refreshed on every update.
    await _recordExternalRoute(ticket);
  }

  @override
  Future<void> upsertMirror(Ticket ticket) async {
    final dao = _dao(ticket.workspaceId);
    final existing = ticket.externalKey == null
        ? null
        : await dao.getByExternalKey(
            ticket.provider.toStorageString(),
            ticket.externalKey!,
          );
    if (existing == null) {
      await dao.insert(_mapper.toCompanion(ticket));
    } else {
      await dao.updateById(existing.id, _mapper.toMirrorCompanion(ticket));
    }
    await _recordExternalRoute(ticket);
  }

  @override
  Future<void> delete(String ticketId, {required String workspaceId}) async {
    final dao = _dao(workspaceId);
    // Read the row before deleting it: its provider + external key are the only
    // way to name the route that must die with it. A route outliving its ticket
    // would send the next inbound webhook to a workspace that no longer has it.
    final row = await dao.getById(ticketId);
    await dao.deleteTicket(ticketId, workspaceId);
    final externalKey = row?.externalKey;
    if (row != null && externalKey != null) {
      await _routes.remove(
        WorkspaceRouteKind.ticketExternalKey,
        _externalRouteKey(row.provider, externalKey),
      );
    }
  }

  @override
  Future<Ticket?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(id);
    if (row == null) {
      return null;
    }
    final collaborators = await _collaborators(workspaceId, id);
    return _mapper.fromRow(row, collaborators: collaborators);
  }

  @override
  Future<Ticket?> getByExternal(
    TicketProvider provider,
    String externalKey,
  ) async {
    final storageProvider = provider.toStorageString();
    final workspaceId = await _routes.resolve(
      WorkspaceRouteKind.ticketExternalKey,
      _externalRouteKey(storageProvider, externalKey),
    );
    if (workspaceId == null) {
      return null;
    }
    final row = await _dao(
      workspaceId,
    ).getByExternalKey(storageProvider, externalKey);
    return row == null ? null : _mapper.fromRow(row);
  }

  @override
  Future<List<Ticket>> forAgent(String workspaceId, String agentId) async {
    final rows = await _dao(workspaceId).forAgent(workspaceId, agentId);
    return rows.map((r) => _mapper.fromRow(r)).toList();
  }

  @override
  Future<List<Ticket>> childrenOf(
    String workspaceId,
    String parentTicketId,
  ) async {
    final rows = await _dao(
      workspaceId,
    ).childrenOf(workspaceId, parentTicketId);
    return rows.map((r) => _mapper.fromRow(r)).toList();
  }

  @override
  Stream<List<Ticket>> watchForWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchForWorkspace(workspaceId)
          .map((rows) => rows.map((r) => _mapper.fromRow(r)).toList());

  @override
  Stream<List<Ticket>> watchByStatus(String workspaceId, TicketStatus status) =>
      _dao(workspaceId)
          .watchByStatus(workspaceId, status.toStorageString())
          .map((rows) => rows.map((r) => _mapper.fromRow(r)).toList());

  @override
  Stream<List<Ticket>> watchByAssignee(String workspaceId, String agentId) =>
      _dao(workspaceId)
          .watchByAssignee(workspaceId, agentId)
          .map((rows) => rows.map((r) => _mapper.fromRow(r)).toList());

  @override
  Future<void> addCollaborator(
    String workspaceId,
    TicketCollaborator collaborator,
  ) => _dao(
    workspaceId,
  ).addCollaborator(_mapper.collaboratorToCompanion(collaborator));

  @override
  Future<void> removeCollaborator(
    String workspaceId,
    String ticketId,
    String agentId,
  ) => _dao(workspaceId).removeCollaborator(ticketId, agentId);

  @override
  Stream<List<TicketCollaborator>> watchCollaborators(
    String workspaceId,
    String ticketId,
  ) => _dao(workspaceId)
      .watchCollaborators(ticketId)
      .map((rows) => rows.map(_mapper.collaboratorFromRow).toList());

  @override
  Future<List<TicketCollaborator>> getCollaborators(
    String workspaceId,
    String ticketId,
  ) => _collaborators(workspaceId, ticketId);

  Future<List<TicketCollaborator>> _collaborators(
    String workspaceId,
    String ticketId,
  ) async {
    final rows = await _dao(workspaceId).getCollaborators(ticketId);
    return rows.map(_mapper.collaboratorFromRow).toList();
  }
}
