import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_persistence/database/daos/ticket_link_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/ticket_link_mapper.dart';

/// Drift-backed [TicketLinkRepository].
///
/// Links live in their workspace's own database file. Every method either
/// takes the `workspaceId` or reads it off the [TicketLink] being written, so
/// the file is picked before any SQL runs — and a link can never span two
/// workspaces.
class DaoTicketLinkRepository implements TicketLinkRepository {
  /// Creates a [DaoTicketLinkRepository] over the per-workspace databases.
  DaoTicketLinkRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  static const _mapper = TicketLinkMapper();

  TicketLinkDao _dao(String workspaceId) => _dbs.of(workspaceId).ticketLinkDao;

  @override
  Future<void> insert(TicketLink link) =>
      _dao(link.workspaceId).insert(_mapper.toCompanion(link));

  @override
  Future<int> deleteById(String id, {required String workspaceId}) =>
      _dao(workspaceId).deleteById(id, workspaceId);

  @override
  Future<int> deleteByEndpoints({
    required String workspaceId,
    required String sourceTicketId,
    required String targetTicketId,
    required TicketLinkType type,
  }) => _dao(workspaceId).deleteByEndpoints(
    workspaceId: workspaceId,
    sourceTicketId: sourceTicketId,
    targetTicketId: targetTicketId,
    type: type.toStorageString(),
  );

  @override
  Future<List<TicketLink>> getForTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final rows = await _dao(workspaceId).getForTicket(workspaceId, ticketId);
    return rows.map(_mapper.fromRowOrNull).whereType<TicketLink>().toList();
  }

  @override
  Stream<List<TicketLink>> watchForTicket(
    String workspaceId,
    String ticketId,
  ) => _dao(workspaceId)
      .watchForTicket(workspaceId, ticketId)
      .map(
        (rows) =>
            rows.map(_mapper.fromRowOrNull).whereType<TicketLink>().toList(),
      );
}
