// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_product_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkProductDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
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
  $WorkProductRevisionsTableTable get workProductRevisionsTable =>
      attachedDatabase.workProductRevisionsTable;
  $WorkProductsTableTable get workProductsTable =>
      attachedDatabase.workProductsTable;
  WorkProductDaoManager get managers => WorkProductDaoManager(this);
}

class WorkProductDaoManager {
  final _$WorkProductDaoMixin _db;
  WorkProductDaoManager(this._db);
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
  $$WorkProductRevisionsTableTableTableManager get workProductRevisionsTable =>
      $$WorkProductRevisionsTableTableTableManager(
        _db.attachedDatabase,
        _db.workProductRevisionsTable,
      );
  $$WorkProductsTableTableTableManager get workProductsTable =>
      $$WorkProductsTableTableTableManager(
        _db.attachedDatabase,
        _db.workProductsTable,
      );
}
