import 'package:drift/drift.dart';

/// Collaborators on a ticket (the one M:N relation). Mirrors
/// `space_participants`: [principalId] is an agent id or a user id per
/// [collaboratorType], with no FK. The [ticketId] FK cascades on ticket
/// delete.
@TableIndex(name: 'idx_ticket_collaborators_ticketId', columns: {#ticketId})
@TableIndex(
  name: 'uq_ticket_collaborators_ticket_agent',
  columns: {#ticketId, #principalId},
  unique: true,
)
class TicketCollaboratorsTable extends Table {
  /// Unique row id.
  TextColumn get id => text()();

  /// Owning ticket.
  TextColumn get ticketId => text().customConstraint(
    'NOT NULL REFERENCES tickets (id) ON DELETE CASCADE',
  )();

  /// Agent id or user id, per [collaboratorType].
  TextColumn get principalId => text()();

  /// Which kind of principal this row is: `agent` or `user`.
  TextColumn get collaboratorType =>
      text().withDefault(const Constant('agent'))();

  /// Role: `assignee` | `collaborator` | `reviewer`.
  TextColumn get role => text().withDefault(const Constant('collaborator'))();

  /// When they joined.
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'ticket_collaborators';

  @override
  Set<Column> get primaryKey => {id};
}
