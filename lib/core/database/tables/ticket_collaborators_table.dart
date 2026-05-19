import 'package:drift/drift.dart';

/// Collaborators on a ticket (the one M:N relation). Mirrors
/// `channel_participants`: [agentId] is an agent UUID or the `user` sentinel,
/// with no FK to the agents table. The [ticketId] FK cascades on ticket delete.
@TableIndex(name: 'idx_ticket_collaborators_ticketId', columns: {#ticketId})
@TableIndex(name: 'uq_ticket_collaborators_ticket_agent', columns: {#ticketId, #agentId}, unique: true)
class TicketCollaboratorsTable extends Table {
  /// Unique row id.
  TextColumn get id => text()();

  /// Owning ticket.
  TextColumn get ticketId => text().customConstraint(
        'NOT NULL REFERENCES tickets (id) ON DELETE CASCADE',
      )();

  /// Agent UUID, or `user` for the human.
  TextColumn get agentId => text()();

  /// Role: `assignee` | `collaborator` | `reviewer`.
  TextColumn get role => text().withDefault(const Constant('collaborator'))();

  /// When they joined.
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'ticket_collaborators';

  @override
  Set<Column> get primaryKey => {id};
}
