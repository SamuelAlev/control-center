// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_extras_dao.dart';

// ignore_for_file: type=lint
mixin _$SpaceExtrasDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $PipelineRunsTableTable get pipelineRunsTable =>
      attachedDatabase.pipelineRunsTable;
  $SpacesTableTable get spacesTable => attachedDatabase.spacesTable;
  $SpaceNotesTableTable get spaceNotesTable => attachedDatabase.spaceNotesTable;
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $SpaceAutonomyTableTable get spaceAutonomyTable =>
      attachedDatabase.spaceAutonomyTable;
  $ConversationMessagesTableTable get conversationMessagesTable =>
      attachedDatabase.conversationMessagesTable;
  $MessageReactionsTableTable get messageReactionsTable =>
      attachedDatabase.messageReactionsTable;
  SpaceExtrasDaoManager get managers => SpaceExtrasDaoManager(this);
}

class SpaceExtrasDaoManager {
  final _$SpaceExtrasDaoMixin _db;
  SpaceExtrasDaoManager(this._db);
  $$PipelineRunsTableTableTableManager get pipelineRunsTable =>
      $$PipelineRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineRunsTable,
      );
  $$SpacesTableTableTableManager get spacesTable =>
      $$SpacesTableTableTableManager(_db.attachedDatabase, _db.spacesTable);
  $$SpaceNotesTableTableTableManager get spaceNotesTable =>
      $$SpaceNotesTableTableTableManager(
        _db.attachedDatabase,
        _db.spaceNotesTable,
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
  $$SpaceAutonomyTableTableTableManager get spaceAutonomyTable =>
      $$SpaceAutonomyTableTableTableManager(
        _db.attachedDatabase,
        _db.spaceAutonomyTable,
      );
  $$ConversationMessagesTableTableTableManager get conversationMessagesTable =>
      $$ConversationMessagesTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationMessagesTable,
      );
  $$MessageReactionsTableTableTableManager get messageReactionsTable =>
      $$MessageReactionsTableTableTableManager(
        _db.attachedDatabase,
        _db.messageReactionsTable,
      );
}
