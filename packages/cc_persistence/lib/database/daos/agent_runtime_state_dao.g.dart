// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_runtime_state_dao.dart';

// ignore_for_file: type=lint
mixin _$AgentRuntimeStateDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $AgentRuntimeStateTableTable get agentRuntimeStateTable =>
      attachedDatabase.agentRuntimeStateTable;
  AgentRuntimeStateDaoManager get managers => AgentRuntimeStateDaoManager(this);
}

class AgentRuntimeStateDaoManager {
  final _$AgentRuntimeStateDaoMixin _db;
  AgentRuntimeStateDaoManager(this._db);
  $$AgentsTableTableTableManager get agentsTable =>
      $$AgentsTableTableTableManager(_db.attachedDatabase, _db.agentsTable);
  $$AgentRuntimeStateTableTableTableManager get agentRuntimeStateTable =>
      $$AgentRuntimeStateTableTableTableManager(
        _db.attachedDatabase,
        _db.agentRuntimeStateTable,
      );
}
