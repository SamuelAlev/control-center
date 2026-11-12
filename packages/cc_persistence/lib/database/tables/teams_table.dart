import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:drift/drift.dart';

/// Drift table for teams — named groups of agents.
@TableIndex(name: 'idx_teams_leader', columns: {#leaderId})
class TeamsTable extends Table {
  /// Unique team identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Team display name.
  TextColumn get name => text()();

  /// Optional team description.
  TextColumn get description => text().nullable()();

  /// Agent id of the team's leader (coordinator), or null when leaderless.
  /// `SET NULL`: deleting the leader agent leaves the team leaderless.
  TextColumn get leaderId => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Optional free-form operating instructions for the leader briefing.
  TextColumn get instructions => text().nullable()();

  /// When this team was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'teams';

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table linking agents to teams. A membership goes with its team and
/// with its agent.
@TableIndex(name: 'idx_teamMembers_agentId', columns: {#agentId})
class TeamMembersTable extends Table {
  /// Team this membership belongs to.
  TextColumn get teamId =>
      text().references(TeamsTable, #id, onDelete: KeyAction.cascade)();

  /// Agent who is a member.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// Role within the team: a `TeamMemberRole` name.
  TextColumn get role => text()
      .check(
        // ignore: recursive_getters
        role.isIn(AgentsStoredValues.teamMemberRole),
      )
      .withDefault(const Constant('member'))();

  @override
  String get tableName => 'team_members';

  @override
  Set<Column> get primaryKey => {teamId, agentId};
}
