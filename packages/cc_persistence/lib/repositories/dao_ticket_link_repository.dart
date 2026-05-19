import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_persistence/database/daos/ticket_link_dao.dart';
import 'package:cc_persistence/mappers/ticket_link_mapper.dart';

/// Drift-backed [TicketLinkRepository].
class DaoTicketLinkRepository implements TicketLinkRepository {
  /// Creates a [DaoTicketLinkRepository].
  DaoTicketLinkRepository(this._dao);

  final TicketLinkDao _dao;
  static const _mapper = TicketLinkMapper();

  @override
  Future<void> insert(TicketLink link) =>
      _dao.insert(_mapper.toCompanion(link));

  @override
  Future<int> deleteById(String id, {required String workspaceId}) =>
      _dao.deleteById(id, workspaceId);

  @override
  Future<int> deleteByEndpoints({
    required String workspaceId,
    required String sourceTicketId,
    required String targetTicketId,
    required TicketLinkType type,
  }) =>
      _dao.deleteByEndpoints(
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
    final rows = await _dao.getForTicket(workspaceId, ticketId);
    return rows.map(_mapper.fromRowOrNull).whereType<TicketLink>().toList();
  }

  @override
  Stream<List<TicketLink>> watchForTicket(
    String workspaceId,
    String ticketId,
  ) =>
      _dao.watchForTicket(workspaceId, ticketId).map(
            (rows) =>
                rows.map(_mapper.fromRowOrNull).whereType<TicketLink>().toList(),
          );
}
