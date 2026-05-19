// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_goal_run_dao.dart';

// ignore_for_file: type=lint
mixin _$AgentGoalRunDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $AgentGoalRunsTableTable get agentGoalRunsTable =>
      attachedDatabase.agentGoalRunsTable;
  AgentGoalRunDaoManager get managers => AgentGoalRunDaoManager(this);
}

class AgentGoalRunDaoManager {
  final _$AgentGoalRunDaoMixin _db;
  AgentGoalRunDaoManager(this._db);
  $$AgentGoalRunsTableTableTableManager get agentGoalRunsTable =>
      $$AgentGoalRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.agentGoalRunsTable,
      );
}
