// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_studio_dao.dart';

// ignore_for_file: type=lint
mixin _$PlanStudioDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
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
  $PipelineTemplatesTableTable get pipelineTemplatesTable =>
      attachedDatabase.pipelineTemplatesTable;
  $OrchestrationsTableTable get orchestrationsTable =>
      attachedDatabase.orchestrationsTable;
  $OrchestrationRevisionsTableTable get orchestrationRevisionsTable =>
      attachedDatabase.orchestrationRevisionsTable;
  $ConversationsTableTable get conversationsTable =>
      attachedDatabase.conversationsTable;
  $PlanDocumentsTableTable get planDocumentsTable =>
      attachedDatabase.planDocumentsTable;
  $PlaybooksTableTable get playbooksTable => attachedDatabase.playbooksTable;
  PlanStudioDaoManager get managers => PlanStudioDaoManager(this);
}

class PlanStudioDaoManager {
  final _$PlanStudioDaoMixin _db;
  PlanStudioDaoManager(this._db);
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
  $$PipelineTemplatesTableTableTableManager get pipelineTemplatesTable =>
      $$PipelineTemplatesTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineTemplatesTable,
      );
  $$OrchestrationsTableTableTableManager get orchestrationsTable =>
      $$OrchestrationsTableTableTableManager(
        _db.attachedDatabase,
        _db.orchestrationsTable,
      );
  $$OrchestrationRevisionsTableTableTableManager
  get orchestrationRevisionsTable =>
      $$OrchestrationRevisionsTableTableTableManager(
        _db.attachedDatabase,
        _db.orchestrationRevisionsTable,
      );
  $$ConversationsTableTableTableManager get conversationsTable =>
      $$ConversationsTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationsTable,
      );
  $$PlanDocumentsTableTableTableManager get planDocumentsTable =>
      $$PlanDocumentsTableTableTableManager(
        _db.attachedDatabase,
        _db.planDocumentsTable,
      );
  $$PlaybooksTableTableTableManager get playbooksTable =>
      $$PlaybooksTableTableTableManager(
        _db.attachedDatabase,
        _db.playbooksTable,
      );
}
