import 'package:drift/drift.dart';

/// Append-only audit row for one ticket sync attempt (workspace-scoped). Also
/// the durable source for inbound-event dedupe: an `ok`/`deduplicated` row for
/// `(workspace_id, vendor, dedupe_key)` means the event was already processed.
@TableIndex(name: 'idx_ticket_sync_log_ws', columns: {#workspaceId})
@TableIndex(
  name: 'idx_ticket_sync_log_dedupe',
  columns: {#workspaceId, #vendor, #dedupeKey},
)
class TicketSyncLogTable extends Table {
  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text().customConstraint('NOT NULL')();

  /// The Control Center ticket involved, when known.
  TextColumn get ticketId => text().nullable()();

  /// Vendor identifier.
  TextColumn get vendor => text()();

  /// Direction of this attempt (`push` | `pull`).
  TextColumn get direction => text()();

  /// Outcome (`ok` | `failed` | `skipped` | `deduplicated`).
  TextColumn get outcome => text()();

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
