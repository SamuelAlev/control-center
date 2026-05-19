// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_dao.dart';

// ignore_for_file: type=lint
mixin _$AgentDaoMixin on DatabaseAccessor<AppDatabase> {
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $AgentRunLogsTableTable get agentRunLogsTable =>
      attachedDatabase.agentRunLogsTable;
  AgentDaoManager get managers => AgentDaoManager(this);
}

class AgentDaoManager {
  final _$AgentDaoMixin _db;
  AgentDaoManager(this._db);
  $$AgentsTableTableTableManager get agentsTable =>
      $$AgentsTableTableTableManager(_db.attachedDatabase, _db.agentsTable);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$AgentRunLogsTableTableTableManager get agentRunLogsTable =>
      $$AgentRunLogsTableTableTableManager(
        _db.attachedDatabase,
        _db.agentRunLogsTable,
      );
}
