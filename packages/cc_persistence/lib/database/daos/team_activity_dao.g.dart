// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_activity_dao.dart';

// ignore_for_file: type=lint
mixin _$TeamActivityDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $TeamsTableTable get teamsTable => attachedDatabase.teamsTable;
  $ProjectsTableTable get projectsTable => attachedDatabase.projectsTable;
  $PipelineRunsTableTable get pipelineRunsTable =>
      attachedDatabase.pipelineRunsTable;
  $SpacesTableTable get spacesTable => attachedDatabase.spacesTable;
  $TicketsTableTable get ticketsTable => attachedDatabase.ticketsTable;
  $TeamActivityLogTableTable get teamActivityLogTable =>
      attachedDatabase.teamActivityLogTable;
  TeamActivityDaoManager get managers => TeamActivityDaoManager(this);
}

class TeamActivityDaoManager {
  final _$TeamActivityDaoMixin _db;
  TeamActivityDaoManager(this._db);
  $$BudgetPolicyTableTableTableManager get budgetPolicyTable =>
      $$BudgetPolicyTableTableTableManager(
        _db.attachedDatabase,
        _db.budgetPolicyTable,
      );
  $$RuntimeProfilesTableTableTableManager get runtimeProfilesTable =>
      $$RuntimeProfilesTableTableTableManager(
        _db.attachedDatabase,
        _db.runtimeProfilesTable,
      );
  $$AgentsTableTableTableManager get agentsTable =>
      $$AgentsTableTableTableManager(_db.attachedDatabase, _db.agentsTable);
  $$TeamsTableTableTableManager get teamsTable =>
      $$TeamsTableTableTableManager(_db.attachedDatabase, _db.teamsTable);
  $$ProjectsTableTableTableManager get projectsTable =>
      $$ProjectsTableTableTableManager(_db.attachedDatabase, _db.projectsTable);
  $$PipelineRunsTableTableTableManager get pipelineRunsTable =>
      $$PipelineRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineRunsTable,
      );
  $$SpacesTableTableTableManager get spacesTable =>
      $$SpacesTableTableTableManager(_db.attachedDatabase, _db.spacesTable);
  $$TicketsTableTableTableManager get ticketsTable =>
      $$TicketsTableTableTableManager(_db.attachedDatabase, _db.ticketsTable);
  $$TeamActivityLogTableTableTableManager get teamActivityLogTable =>
      $$TeamActivityLogTableTableTableManager(
        _db.attachedDatabase,
        _db.teamActivityLogTable,
      );
}
