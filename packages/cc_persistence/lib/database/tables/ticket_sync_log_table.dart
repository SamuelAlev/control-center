import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/tickets_table.dart';
import 'package:drift/drift.dart';

/// Append-only audit row for one ticket sync attempt (workspace-scoped). Also
/// the durable source for inbound-event dedupe: an `ok`/`deduplicated` row for
/// `(vendor, dedupe_key)` means the event was already processed.
@TableIndex(name: 'idx_ticket_sync_log_dedupe', columns: {#vendor, #dedupeKey})
@TableIndex(name: 'idx_ticket_sync_log_created', columns: {#createdAt})
@TableIndex(name: 'idx_ticket_sync_log_ticket', columns: {#ticketId})
class TicketSyncLogTable extends Table {
  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text().customConstraint('NOT NULL')();

  /// The Control Center ticket involved, when known. `SET NULL`: the audit
  /// row outlives the ticket.
  TextColumn get ticketId => text().nullable().references(
    TicketsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Vendor identifier.
  TextColumn get vendor => text()();

  /// Direction of this attempt: a `SyncDirection` name.
  TextColumn get direction => text().check(
    // ignore: recursive_getters
    direction.isIn(AgentsStoredValues.syncDirection),
  )();

  /// Outcome: a `SyncOutcome` name.
  TextColumn get outcome => text().check(
    // ignore: recursive_getters
    outcome.isIn(AgentsStoredValues.syncOutcome),
  )();

  /// Human-readable detail (error message or short note).
  TextColumn get message => text().nullable()();

  /// Vendor idempotency token (e.g. webhook delivery id) for dedupe.
  TextColumn get dedupeKey => text().nullable()();

  /// When the attempt happened.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'ticket_sync_log';

  @override
  Set<Column> get primaryKey => {id};
}
