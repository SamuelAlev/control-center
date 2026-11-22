// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_mode_dao.dart';

// ignore_for_file: type=lint
mixin _$CodeModeDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $PipelineRunsTableTable get pipelineRunsTable =>
      attachedDatabase.pipelineRunsTable;
  $SpacesTableTable get spacesTable => attachedDatabase.spacesTable;
  $ConversationsTableTable get conversationsTable =>
      attachedDatabase.conversationsTable;
  $ProjectsTableTable get projectsTable => attachedDatabase.projectsTable;
  $TeamsTableTable get teamsTable => attachedDatabase.teamsTable;
  $TicketsTableTable get ticketsTable => attachedDatabase.ticketsTable;
  $AgentRunLogsTableTable get agentRunLogsTable =>
      attachedDatabase.agentRunLogsTable;
  $CodeExecutionsTableTable get codeExecutionsTable =>
      attachedDatabase.codeExecutionsTable;
  $CodeExecutionPayloadsTableTable get codeExecutionPayloadsTable =>
      attachedDatabase.codeExecutionPayloadsTable;
  $CodeExecutionCallsTableTable get codeExecutionCallsTable =>
      attachedDatabase.codeExecutionCallsTable;
  $CodeModeStoreTableTable get codeModeStoreTable =>
      attachedDatabase.codeModeStoreTable;
  CodeModeDaoManager get managers => CodeModeDaoManager(this);
}

class CodeModeDaoManager {
  final _$CodeModeDaoMixin _db;
  CodeModeDaoManager(this._db);
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
  $$PipelineRunsTableTableTableManager get pipelineRunsTable =>
      $$PipelineRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineRunsTable,
      );
  $$SpacesTableTableTableManager get spacesTable =>
      $$SpacesTableTableTableManager(_db.attachedDatabase, _db.spacesTable);
  $$ConversationsTableTableTableManager get conversationsTable =>
      $$ConversationsTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationsTable,
      );
  $$ProjectsTableTableTableManager get projectsTable =>
      $$ProjectsTableTableTableManager(_db.attachedDatabase, _db.projectsTable);
  $$TeamsTableTableTableManager get teamsTable =>
      $$TeamsTableTableTableManager(_db.attachedDatabase, _db.teamsTable);
  $$TicketsTableTableTableManager get ticketsTable =>
      $$TicketsTableTableTableManager(_db.attachedDatabase, _db.ticketsTable);
  $$AgentRunLogsTableTableTableManager get agentRunLogsTable =>
      $$AgentRunLogsTableTableTableManager(
        _db.attachedDatabase,
        _db.agentRunLogsTable,
      );
  $$CodeExecutionsTableTableTableManager get codeExecutionsTable =>
      $$CodeExecutionsTableTableTableManager(
        _db.attachedDatabase,
        _db.codeExecutionsTable,
      );
  $$CodeExecutionPayloadsTableTableTableManager
  get codeExecutionPayloadsTable =>
      $$CodeExecutionPayloadsTableTableTableManager(
        _db.attachedDatabase,
        _db.codeExecutionPayloadsTable,
      );
  $$CodeExecutionCallsTableTableTableManager get codeExecutionCallsTable =>
      $$CodeExecutionCallsTableTableTableManager(
        _db.attachedDatabase,
        _db.codeExecutionCallsTable,
      );
  $$CodeModeStoreTableTableTableManager get codeModeStoreTable =>
      $$CodeModeStoreTableTableTableManager(
        _db.attachedDatabase,
        _db.codeModeStoreTable,
      );
}
