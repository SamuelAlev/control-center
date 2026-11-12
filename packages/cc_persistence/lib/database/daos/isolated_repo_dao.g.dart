// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isolated_repo_dao.dart';

// ignore_for_file: type=lint
mixin _$IsolatedRepoDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ProjectsTableTable get projectsTable => attachedDatabase.projectsTable;
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $TeamsTableTable get teamsTable => attachedDatabase.teamsTable;
  $PipelineRunsTableTable get pipelineRunsTable =>
      attachedDatabase.pipelineRunsTable;
  $SpacesTableTable get spacesTable => attachedDatabase.spacesTable;
  $TicketsTableTable get ticketsTable => attachedDatabase.ticketsTable;
  $IsolatedReposTableTable get isolatedReposTable =>
      attachedDatabase.isolatedReposTable;
  IsolatedRepoDaoManager get managers => IsolatedRepoDaoManager(this);
}

class IsolatedRepoDaoManager {
  final _$IsolatedRepoDaoMixin _db;
  IsolatedRepoDaoManager(this._db);
  $$ProjectsTableTableTableManager get projectsTable =>
      $$ProjectsTableTableTableManager(_db.attachedDatabase, _db.projectsTable);
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
  $$PipelineRunsTableTableTableManager get pipelineRunsTable =>
      $$PipelineRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineRunsTable,
      );
  $$SpacesTableTableTableManager get spacesTable =>
      $$SpacesTableTableTableManager(_db.attachedDatabase, _db.spacesTable);
  $$TicketsTableTableTableManager get ticketsTable =>
      $$TicketsTableTableTableManager(_db.attachedDatabase, _db.ticketsTable);
  $$IsolatedReposTableTableTableManager get isolatedReposTable =>
      $$IsolatedReposTableTableTableManager(
        _db.attachedDatabase,
        _db.isolatedReposTable,
      );
}
