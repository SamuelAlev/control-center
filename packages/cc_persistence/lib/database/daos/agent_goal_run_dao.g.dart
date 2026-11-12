// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_goal_run_dao.dart';

// ignore_for_file: type=lint
mixin _$AgentGoalRunDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $PipelineRunsTableTable get pipelineRunsTable =>
      attachedDatabase.pipelineRunsTable;
  $SpacesTableTable get spacesTable => attachedDatabase.spacesTable;
  $ConversationsTableTable get conversationsTable =>
      attachedDatabase.conversationsTable;
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $ProjectsTableTable get projectsTable => attachedDatabase.projectsTable;
  $TeamsTableTable get teamsTable => attachedDatabase.teamsTable;
  $TicketsTableTable get ticketsTable => attachedDatabase.ticketsTable;
  $AgentRunLogsTableTable get agentRunLogsTable =>
      attachedDatabase.agentRunLogsTable;
  $AgentGoalRunsTableTable get agentGoalRunsTable =>
      attachedDatabase.agentGoalRunsTable;
  AgentGoalRunDaoManager get managers => AgentGoalRunDaoManager(this);
}

class AgentGoalRunDaoManager {
  final _$AgentGoalRunDaoMixin _db;
  AgentGoalRunDaoManager(this._db);
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
  $$AgentGoalRunsTableTableTableManager get agentGoalRunsTable =>
      $$AgentGoalRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.agentGoalRunsTable,
      );
}
