import 'package:drift/drift.dart';

/// Drift table for directional dependencies between tickets.
///
/// One row is one canonical, directional relationship `source --type--> target` with [type]
/// in `{blocks, relates_to, duplicate_of}`.
/// The UI derives the inverse views from a given ticket's perspective:
/// A partial-unique index on `(source_ticket_id, target_ticket_id, type)` keeps links
/// idempotent.
@TableIndex(name: 'idx_ticket_links_source', columns: {#sourceTicketId})
@TableIndex(name: 'idx_ticket_links_target', columns: {#targetTicketId})
@TableIndex(
  name: 'uq_ticket_links_source_target_type',
  columns: {#sourceTicketId, #targetTicketId, #type},
  unique: true,
)
class TicketLinksTable extends Table {
  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope (denormalized from the endpoints for scoped queries).
  TextColumn get workspaceId => text()();

  /// The relationship's origin ticket.
  TextColumn get sourceTicketId => text().customConstraint(
    'NOT NULL REFERENCES tickets (id) ON DELETE CASCADE',
  )();

  /// The relationship's destination ticket.
  TextColumn get targetTicketId => text().customConstraint(
    'NOT NULL REFERENCES tickets (id) ON DELETE CASCADE',
  )();

  /// Canonical relationship type: `blocks` | `relates_to` | `duplicate_of`.
  TextColumn get type => text()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'ticket_links';

  @override
  Set<Column> get primaryKey => {id};
}
