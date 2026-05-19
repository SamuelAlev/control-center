import 'package:drift/drift.dart';

/// Drift table for teams — named groups of agents.
@TableIndex(name: 'idx_teams_workspaceId', columns: {#workspaceId})
class TeamsTable extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table linking agents to teams.
@TableIndex(name: 'idx_teamMembers_teamId', columns: {#teamId})
@TableIndex(name: 'idx_teamMembers_agentId', columns: {#agentId})
class TeamMembersTable extends Table {
  TextColumn get teamId => text()();
  TextColumn get agentId => text()();
  TextColumn get role => text().withDefault(const Constant('member'))();

  @override
  Set<Column> get primaryKey => {teamId, agentId};
}
