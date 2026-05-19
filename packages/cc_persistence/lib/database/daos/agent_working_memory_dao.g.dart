// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_working_memory_dao.dart';

// ignore_for_file: type=lint
mixin _$AgentWorkingMemoryDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $AgentWorkingMemoryTableTable get agentWorkingMemoryTable =>
      attachedDatabase.agentWorkingMemoryTable;
  AgentWorkingMemoryDaoManager get managers =>
      AgentWorkingMemoryDaoManager(this);
}

class AgentWorkingMemoryDaoManager {
  final _$AgentWorkingMemoryDaoMixin _db;
  AgentWorkingMemoryDaoManager(this._db);
  $$AgentsTableTableTableManager get agentsTable =>
      $$AgentsTableTableTableManager(_db.attachedDatabase, _db.agentsTable);
  $$AgentWorkingMemoryTableTableTableManager get agentWorkingMemoryTable =>
      $$AgentWorkingMemoryTableTableTableManager(
        _db.attachedDatabase,
        _db.agentWorkingMemoryTable,
      );
}
