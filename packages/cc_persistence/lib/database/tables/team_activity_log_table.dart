import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/teams_table.dart';
import 'package:cc_persistence/database/tables/tickets_table.dart';
import 'package:drift/drift.dart';

/// Records each team-leader evaluation of a routed request — both an audit
/// trail and the dedup substrate for the leader re-trigger loop. A row goes
/// with its team and with its ticket (it is an evaluation of that pair).
@TableIndex(
  name: 'idx_team_activity_team_created',
  columns: {#teamId, #createdAt},
)
@TableIndex(name: 'idx_team_activity_ticket', columns: {#ticketId, #createdAt})
@TableIndex(name: 'idx_team_activity_leader', columns: {#leaderId})
@TableIndex(name: 'idx_team_activity_member', columns: {#memberId})
class TeamActivityLogTable extends Table {
  /// Unique identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The team whose leader recorded this evaluation.
  TextColumn get teamId =>
      text().references(TeamsTable, #id, onDelete: KeyAction.cascade)();

  /// The ticket the evaluation is about.
  TextColumn get ticketId =>
      text().references(TicketsTable, #id, onDelete: KeyAction.cascade)();

  /// The recorded outcome: a `TeamActivityKind` storage string.
  TextColumn get kind => text().check(
    // ignore: recursive_getters
    kind.isIn(AgentsStoredValues.teamActivityKind),
  )();

  /// The leader agent that recorded it, if known. `SET NULL`: the record
  /// outlives the agent.
  TextColumn get leaderId => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The member delegated to, for an `action` outcome, if any. `SET NULL`:
  /// the record outlives the agent.
  TextColumn get memberId => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Short human-readable note about the decision.
  TextColumn get summary => text().nullable()();

  /// When the evaluation was recorded.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'team_activity_log';

  @override
  Set<Column> get primaryKey => {id};
}
