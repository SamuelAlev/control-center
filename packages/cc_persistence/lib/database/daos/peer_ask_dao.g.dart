// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peer_ask_dao.dart';

// ignore_for_file: type=lint
mixin _$PeerAskDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
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
  $PeerAsksTableTable get peerAsksTable => attachedDatabase.peerAsksTable;
  PeerAskDaoManager get managers => PeerAskDaoManager(this);
}

class PeerAskDaoManager {
  final _$PeerAskDaoMixin _db;
  PeerAskDaoManager(this._db);
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
  $$PeerAsksTableTableTableManager get peerAsksTable =>
      $$PeerAsksTableTableTableManager(_db.attachedDatabase, _db.peerAsksTable);
}
