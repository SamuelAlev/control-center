// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_sync_dao.dart';

// ignore_for_file: type=lint
mixin _$TicketSyncDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $TicketSyncConfigsTableTable get ticketSyncConfigsTable =>
      attachedDatabase.ticketSyncConfigsTable;
  $TicketSyncLinksTableTable get ticketSyncLinksTable =>
      attachedDatabase.ticketSyncLinksTable;
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
  $TicketSyncLogTableTable get ticketSyncLogTable =>
      attachedDatabase.ticketSyncLogTable;
  TicketSyncDaoManager get managers => TicketSyncDaoManager(this);
}

class TicketSyncDaoManager {
  final _$TicketSyncDaoMixin _db;
  TicketSyncDaoManager(this._db);
  $$TicketSyncConfigsTableTableTableManager get ticketSyncConfigsTable =>
      $$TicketSyncConfigsTableTableTableManager(
        _db.attachedDatabase,
        _db.ticketSyncConfigsTable,
      );
  $$TicketSyncLinksTableTableTableManager get ticketSyncLinksTable =>
      $$TicketSyncLinksTableTableTableManager(
        _db.attachedDatabase,
        _db.ticketSyncLinksTable,
      );
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
  $$TicketSyncLogTableTableTableManager get ticketSyncLogTable =>
      $$TicketSyncLogTableTableTableManager(
        _db.attachedDatabase,
        _db.ticketSyncLogTable,
      );
}
