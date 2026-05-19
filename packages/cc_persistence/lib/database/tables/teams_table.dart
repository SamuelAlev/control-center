import 'package:drift/drift.dart';

/// Drift table for teams — named groups of agents.
@TableIndex(name: 'idx_teams_workspaceId', columns: {#workspaceId})
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
  TextColumn get leaderId => text().nullable()();

  /// Optional free-form operating instructions for the leader briefing.
  TextColumn get instructions => text().nullable()();

  /// When this team was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'teams';

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table linking agents to teams.
@TableIndex(name: 'idx_teamMembers_teamId', columns: {#teamId})
@TableIndex(name: 'idx_teamMembers_agentId', columns: {#agentId})
class TeamMembersTable extends Table {
  /// Team this membership belongs to.
  TextColumn get teamId => text()();

  /// Agent who is a member.
  TextColumn get agentId => text()();

  /// Role within the team.
  TextColumn get role => text().withDefault(const Constant('member'))();

  @override
  String get tableName => 'team_members';

  @override
  Set<Column> get primaryKey => {teamId, agentId};
}
