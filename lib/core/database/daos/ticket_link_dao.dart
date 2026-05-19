import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/ticket_links_table.dart';
import 'package:drift/drift.dart';

part 'ticket_link_dao.g.dart';

/// Data access for directional ticket dependencies ([TicketLinksTable]).
@DriftAccessor(tables: [TicketLinksTable])
class TicketLinkDao extends DatabaseAccessor<AppDatabase>
    with _$TicketLinkDaoMixin {
  /// Creates a [TicketLinkDao].
  TicketLinkDao(super.db);

  /// Inserts a link, ignoring duplicates (the unique
  /// `(source, target, type)` index makes this idempotent).
  Future<void> insert(TicketLinksTableCompanion link) =>
      into(ticketLinksTable).insert(link, mode: InsertMode.insertOrIgnore);

  /// Deletes a link by id, scoped to [workspaceId]. Returns rows deleted.
  Future<int> deleteById(String id, String workspaceId) =>
      (delete(ticketLinksTable)
            ..where((l) =>
                l.id.equals(id) & l.workspaceId.equals(workspaceId)))
          .go();

  /// Deletes a link identified by its endpoints + type, scoped to
  /// [workspaceId]. Returns rows deleted.
  Future<int> deleteByEndpoints({
    required String workspaceId,
    required String sourceTicketId,
    required String targetTicketId,
    required String type,
  }) =>
      (delete(ticketLinksTable)
            ..where((l) =>
                l.workspaceId.equals(workspaceId) &
                l.sourceTicketId.equals(sourceTicketId) &
                l.targetTicketId.equals(targetTicketId) &
                l.type.equals(type)))
          .go();

  /// All links touching [ticketId] (as source or target), scoped to
  /// [workspaceId].
  Future<List<TicketLinksTableData>> getForTicket(
    String workspaceId,
    String ticketId,
  ) =>
      (select(ticketLinksTable)
            ..where((l) =>
                l.workspaceId.equals(workspaceId) &
                (l.sourceTicketId.equals(ticketId) |
                    l.targetTicketId.equals(ticketId))))
          .get();

  /// Watches all links touching [ticketId] (as source or target), scoped to
  /// [workspaceId].
  Stream<List<TicketLinksTableData>> watchForTicket(
    String workspaceId,
    String ticketId,
  ) =>
      (select(ticketLinksTable)
            ..where((l) =>
                l.workspaceId.equals(workspaceId) &
                (l.sourceTicketId.equals(ticketId) |
                    l.targetTicketId.equals(ticketId)))
            ..orderBy([(l) => OrderingTerm.asc(l.createdAt)]))
          .watch();
}
