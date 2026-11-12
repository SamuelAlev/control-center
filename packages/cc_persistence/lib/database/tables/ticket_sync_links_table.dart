import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:drift/drift.dart';

/// Maps one Control Center ticket to its counterpart on one vendor. A CC ticket
/// (the primary) can have several links — one per synced vendor — so this is a
/// separate table rather than columns on the ticket row.
///
/// `(ticket_id, vendor)` is unique (one link per ticket per vendor, the key
/// `TicketSyncDao.upsertLink` writes against); `(vendor, external_id)` is the
/// reverse lookup a pull / webhook uses to find the local ticket. A link goes
/// with its ticket.
@TableIndex(
  name: 'uq_ticket_sync_links_ticket_vendor',
  columns: {#ticketId, #vendor},
  unique: true,
)
@TableIndex(
  name: 'idx_ticket_sync_links_vendor_ext',
  columns: {#vendor, #externalId},
)
class TicketSyncLinksTable extends Table {
  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text().customConstraint('NOT NULL')();

  /// The Control Center ticket id.
  TextColumn get ticketId => text().customConstraint(
    'NOT NULL REFERENCES tickets (id) ON DELETE CASCADE',
  )();

  /// Vendor identifier.
  TextColumn get vendor => text()();

  /// Stable vendor id for the linked ticket.
  TextColumn get externalId => text()();

  /// Vendor-native human key (e.g. `ENG-123`).
  TextColumn get externalKey => text().nullable()();

  /// Web URL on the vendor.
  TextColumn get externalUrl => text().nullable()();

  /// When the link last synced in either direction.
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  /// Direction of the last successful sync: a `SyncDirection` name.
  TextColumn get lastDirection =>
      text().nullable()
      // ignore: recursive_getters
      .check(lastDirection.isIn(AgentsStoredValues.syncDirection))();

  @override
  String get tableName => 'ticket_sync_links';

  @override
  Set<Column> get primaryKey => {id};
}
