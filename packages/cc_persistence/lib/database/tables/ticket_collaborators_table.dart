import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:drift/drift.dart';

/// Collaborators on a ticket (the one M:N relation). Mirrors
/// `space_participants`: [principalId] is an agent id or a user id per
/// [collaboratorType], with no FK. The [ticketId] FK cascades on ticket
/// delete.
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

  /// Which kind of principal this row is: a `PrincipalType` wire name.
  TextColumn get collaboratorType => text()
      .check(
        // ignore: recursive_getters
        collaboratorType.isIn(AgentsStoredValues.principalType),
      )
      .withDefault(const Constant('agent'))();

  /// Role: a `TicketCollaboratorRole` name.
  TextColumn get role => text()
      .check(
        // ignore: recursive_getters
        role.isIn(AgentsStoredValues.ticketCollaboratorRole),
      )
      .withDefault(const Constant('collaborator'))();

  /// When they joined.
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'ticket_collaborators';

  @override
  Set<Column> get primaryKey => {id};
}
